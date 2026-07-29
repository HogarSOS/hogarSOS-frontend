import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/brand_mark.dart';
import '../admin/admin_screen.dart';
import '../cliente_shell_screen.dart';
import '../profesional_shell_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  UserRole _rolSeleccionado = UserRole.cliente;
  bool _modoRegistro = false;
  bool _recordarSesion = true;
  bool _passwordVisible = false;
  String? _errorValidacion;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = AppLocalizations.of(context);

    // Sin esto, un email/contraseña vacíos llegaban tal cual a Firebase,
    // que para ese caso concreto no lanza un FirebaseAuthException limpio
    // sino una excepción de plataforma cruda (el nombre interno del canal
    // Pigeon) — eso es lo que se veía en pantalla en vez de un mensaje
    // legible, porque el catch-all de auth_provider.dart no sabe traducir
    // algo que no es ni AuthException ni un formato reconocible.
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty ||
        (_modoRegistro && _nombreController.text.trim().isEmpty)) {
      setState(() => _errorValidacion = t.loginCamposObligatorios);
      return;
    }
    setState(() => _errorValidacion = null);

    final notifier = ref.read(authProvider.notifier);

    if (_modoRegistro) {
      await notifier.registrar(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        role: _rolSeleccionado,
        recordarSesion: _recordarSesion,
      );
    } else {
      await notifier.loginConEmail(
        _emailController.text.trim(),
        _passwordController.text,
        recordarSesion: _recordarSesion,
      );
    }

    if (!mounted) return;

    final usuario = ref.read(authProvider).usuario;
    if (usuario == null) return; // el error ya se muestra vía authProvider.error

    final destino = switch (usuario.role) {
      // pestanaInicial: 3 = Perfil, solo en registro — un profesional
      // recién creado debe ver primero su propio perfil para
      // completarlo (foto, categorías...), no Inicio.
      UserRole.profesional => ProfesionalShellScreen(pestanaInicial: _modoRegistro ? 3 : 0),
      UserRole.admin => const AdminScreen(),
      UserRole.cliente => const ClienteShellScreen(),
    };

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  Future<void> _recuperarPassword() async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: _emailController.text.trim());

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.loginRecuperarTitulo),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(labelText: t.loginFieldEmail),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.loginRecuperarEnviar),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    final error = await ref.read(authProvider.notifier).enviarEmailRecuperacion(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? t.loginRecuperarExito)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: HogarSosLogoVertical(markSize: 84, fontSize: 30)),
                  const SizedBox(height: 10),
                  Text(
                    t.loginTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_modoRegistro) ...[
                          TextField(
                            controller: _nombreController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(labelText: t.loginFieldNombre),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<UserRole>(
                            segments: [
                              ButtonSegment(value: UserRole.cliente, label: Text(t.loginRoleCliente)),
                              ButtonSegment(value: UserRole.profesional, label: Text(t.loginRoleProfesional)),
                            ],
                            selected: {_rolSeleccionado},
                            onSelectionChanged: (nuevo) {
                              setState(() => _rolSeleccionado = nuevo.first);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                          decoration: InputDecoration(labelText: t.loginFieldEmail),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: !_passwordVisible,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _enviar(),
                          decoration: InputDecoration(
                            labelText: t.loginFieldPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Material(type: transparency) a propósito: el
                        // CheckboxListTile pinta su fondo/ripple en el
                        // Material ancestro más cercano — sin esto, la
                        // tarjeta contenedora (un Container con su
                        // propio BoxDecoration, no un Material) se lo
                        // "roba" y el ripple del checkbox queda
                        // invisible (aviso real visto en ejecución).
                        Material(
                          type: MaterialType.transparency,
                          child: CheckboxListTile(
                            value: _recordarSesion,
                            onChanged: (valor) => setState(() => _recordarSesion = valor ?? true),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(t.loginRecordarSesion, style: const TextStyle(fontSize: 13.5)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_errorValidacion != null || authState.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorValidacion ?? authState.error!,
                              style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        FilledButton(
                          onPressed: authState.cargando ? null : _enviar,
                          child: authState.cargando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_modoRegistro ? t.loginBtnCrearCuenta : t.loginBtnIniciarSesion),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _modoRegistro = !_modoRegistro),
                    child: Text(
                      _modoRegistro ? t.loginLinkYaTienesCuenta : t.loginLinkNoTienesCuenta,
                    ),
                  ),
                  if (!_modoRegistro)
                    TextButton(
                      onPressed: _recuperarPassword,
                      child: Text(t.loginOlvidasteContrasena),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
