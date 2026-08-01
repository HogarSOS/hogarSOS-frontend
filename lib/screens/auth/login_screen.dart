import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/brand_mark.dart';
import '../admin/admin_screen.dart';
import '../cliente_shell_screen.dart';
import '../legal/privacidad_screen.dart';
import '../legal/terminos_screen.dart';
import '../profesional_shell_screen.dart';
import 'verificar_codigo_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  // +34 precargado porque la mayoría de usuarios son de España — sigue
  // siendo editable para el resto (ver el porqué de fondo en el comentario
  // de _modoTelefono, más abajo).
  final _telefonoController = TextEditingController(text: '+34 ');
  final _passwordFocusNode = FocusNode();
  UserRole _rolSeleccionado = UserRole.cliente;
  bool _modoRegistro = false;
  // Alternativa al email+contraseña — el usuario elige uno de los dos,
  // no se combinan. Ver AuthService.enviarCodigoTelefono/
  // completarConCredencialTelefono para el porqué de por qué el
  // teléfono no puede reutilizar el mismo _enviar() de email tal cual
  // (Firebase avisa por callbacks, no con un simple await que falle si
  // la cuenta no existe).
  bool _modoTelefono = false;
  bool _enviandoCodigo = false;
  bool _recordarSesion = true;
  bool _passwordVisible = false;
  String? _errorValidacion;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Perfil es la primera pestaña del shell (índice 0 por defecto) —
  // antes había que pasar pestanaInicial: 3 a mano solo para el caso de
  // registro, para que un profesional recién creado viera primero su
  // perfil y lo completara (foto, categorías...); ya no hace falta el
  // caso especial, login normal y registro coinciden. Compartido entre
  // el flujo de email (aquí mismo) y el de teléfono (tras autoverificar
  // sin pasar por VerificarCodigoScreen).
  Widget _destinoSegunRol(UserRole role) {
    return switch (role) {
      UserRole.profesional => const ProfesionalShellScreen(),
      UserRole.admin => const AdminScreen(),
      UserRole.cliente => const ClienteShellScreen(),
    };
  }

  Future<void> _enviar() async {
    if (_modoTelefono) return _enviarPorTelefono();

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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _destinoSegunRol(usuario.role)),
    );
  }

  /// Pide el SMS y, según lo que responda Firebase, o pasa a
  /// VerificarCodigoScreen (caso normal: hay que escribir el código) o
  /// completa sesión directamente (Android detectó el SMS solo, sin
  /// pantalla intermedia — ver AuthService.enviarCodigoTelefono).
  Future<void> _enviarPorTelefono() async {
    final t = AppLocalizations.of(context);
    // replaceAll y no solo trim(): Firebase exige formato E.164 estricto
    // (sin espacios internos), y el campo empieza precargado con "+34 "
    // — un espacio decorativo entre prefijo y número que hay que quitar
    // antes de mandarlo, no solo los de los extremos.
    final telefono = _telefonoController.text.replaceAll(' ', '').trim();

    if (telefono.isEmpty ||
        telefono == '+34' ||
        (_modoRegistro && _nombreController.text.trim().isEmpty)) {
      setState(() => _errorValidacion = t.loginCamposObligatorios);
      return;
    }
    setState(() {
      _errorValidacion = null;
      _enviandoCodigo = true;
    });

    final nombre = _nombreController.text.trim();

    await ref.read(authServiceProvider).enviarCodigoTelefono(
          numeroTelefono: telefono,
          onCodigoEnviado: (verificationId) {
            if (!mounted) return;
            setState(() => _enviandoCodigo = false);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerificarCodigoScreen(
                  verificationId: verificationId,
                  telefono: telefono,
                  nombre: nombre,
                  role: _rolSeleccionado,
                  esRegistro: _modoRegistro,
                  recordarSesion: _recordarSesion,
                ),
              ),
            );
          },
          onAutoVerificado: (credential) async {
            if (!mounted) return;
            setState(() => _enviandoCodigo = false);
            await ref.read(authProvider.notifier).completarConCredencialTelefono(
                  credential,
                  nombre: nombre,
                  role: _rolSeleccionado,
                  esRegistro: _modoRegistro,
                  recordarSesion: _recordarSesion,
                );
            if (!mounted) return;
            final usuario = ref.read(authProvider).usuario;
            if (usuario == null) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => _destinoSegunRol(usuario.role)),
            );
          },
          onError: (mensaje) {
            if (!mounted) return;
            setState(() {
              _errorValidacion = mensaje;
              _enviandoCodigo = false;
            });
          },
        );
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
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(value: false, label: Text(t.loginModoEmail)),
                            ButtonSegment(value: true, label: Text(t.loginModoTelefono)),
                          ],
                          selected: {_modoTelefono},
                          onSelectionChanged: (nuevo) {
                            setState(() {
                              _modoTelefono = nuevo.first;
                              _errorValidacion = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_modoTelefono) ...[
                          TextField(
                            // Clave explícita: sin ella, este TextField y el
                            // de email de la rama de abajo ocupan la misma
                            // posición del árbol al alternar el toggle, y
                            // Flutter reutiliza el Element/State en vez de
                            // crear uno nuevo — el teclado del sistema se
                            // quedaba en modo numérico (heredado de este
                            // campo) incluso después de volver a Email,
                            // porque la conexión con el teclado no se
                            // reabría con el keyboardType nuevo.
                            key: const ValueKey('campo_telefono'),
                            controller: _telefonoController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _enviar(),
                            decoration: InputDecoration(
                              labelText: t.loginFieldTelefono,
                              helperText: t.loginTelefonoAyuda,
                              helperMaxLines: 2,
                            ),
                          ),
                        ] else ...[
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
                        ],
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
                        if (_modoRegistro) ...[
                          _AvisoLegal(t: t, colorScheme: colorScheme),
                          const SizedBox(height: 12),
                        ],
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
                          onPressed: (authState.cargando || _enviandoCodigo) ? null : _enviar,
                          child: (authState.cargando || _enviandoCodigo)
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _modoTelefono
                                      ? t.loginBtnEnviarCodigo
                                      : (_modoRegistro ? t.loginBtnCrearCuenta : t.loginBtnIniciarSesion),
                                ),
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
                  if (!_modoRegistro && !_modoTelefono)
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

/// Aviso de "al registrarte, aceptas..." con enlaces reales a las
/// pantallas legales — antes no existía ningún punto de aceptación
/// explícito en el registro, algo que las tiendas de apps exigen ver
/// antes o durante el alta de cuenta, no solo escondido en el perfil.
/// Construido a partir de fragmentos traducidos por separado (prefijo /
/// "y" / sufijo) en vez de buscar dónde caen los enlaces dentro de una
/// única frase ya traducida — más simple y no depende de que el texto
/// de cada idioma coincida carácter a carácter con las claves de perfil.
class _AvisoLegal extends StatelessWidget {
  const _AvisoLegal({required this.t, required this.colorScheme});

  final AppLocalizations t;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant);
    final estiloEnlace = estilo.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600);

    return Text.rich(
      TextSpan(
        style: estilo,
        children: [
          TextSpan(text: t.legalAceptacionPrefijo),
          TextSpan(
            text: t.perfilTerminos,
            style: estiloEnlace,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TerminosScreen()),
                  ),
          ),
          TextSpan(text: t.legalAceptacionY),
          TextSpan(
            text: t.perfilPrivacidad,
            style: estiloEnlace,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacidadScreen()),
                  ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
