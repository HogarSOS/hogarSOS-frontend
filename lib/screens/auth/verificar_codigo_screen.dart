import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/error_extraction.dart';
import '../admin/admin_screen.dart';
import '../cliente_shell_screen.dart';
import '../profesional_shell_screen.dart';

/// Pantalla de introducir el código SMS de 6 dígitos — segundo paso del
/// login/registro por teléfono (el primero es login_screen.dart, que
/// pide el número y llama a `enviarCodigoTelefono`). Recibe todo lo que
/// hace falta para completar la sesión al confirmar: `verificationId`
/// (identifica ESTE envío de SMS ante Firebase), y los mismos datos de
/// nombre/rol/recordar que ya se rellenaron en la pantalla anterior —
/// se guardan aquí en vez de perderlos, porque `esRegistro` decide
/// entre /auth/register y /auth/login al confirmar.
class VerificarCodigoScreen extends ConsumerStatefulWidget {
  const VerificarCodigoScreen({
    super.key,
    required this.verificationId,
    required this.telefono,
    required this.nombre,
    required this.role,
    required this.esRegistro,
    required this.recordarSesion,
  });

  final String verificationId;
  final String telefono;
  final String nombre;
  final UserRole role;
  final bool esRegistro;
  final bool recordarSesion;

  @override
  ConsumerState<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState extends ConsumerState<VerificarCodigoScreen> {
  final _codigoController = TextEditingController();
  late String _verificationId;
  String? _errorLocal;
  bool _reenviando = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final t = AppLocalizations.of(context);
    final codigo = _codigoController.text.trim();
    if (codigo.length < 6) {
      setState(() => _errorLocal = t.loginCamposObligatorios);
      return;
    }
    setState(() => _errorLocal = null);

    await ref.read(authProvider.notifier).confirmarCodigoTelefono(
          verificationId: _verificationId,
          smsCode: codigo,
          nombre: widget.nombre,
          role: widget.role,
          esRegistro: widget.esRegistro,
          recordarSesion: widget.recordarSesion,
        );

    if (!mounted) return;
    final usuario = ref.read(authProvider).usuario;
    if (usuario == null) return; // el error ya se muestra vía authProvider.error, más abajo

    final destino = switch (usuario.role) {
      UserRole.profesional => const ProfesionalShellScreen(),
      UserRole.admin => const AdminScreen(),
      UserRole.cliente => const ClienteShellScreen(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destino),
      (route) => false,
    );
  }

  Future<void> _reenviar() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _reenviando = true;
      _errorLocal = null;
    });

    await ref.read(authServiceProvider).enviarCodigoTelefono(
          numeroTelefono: widget.telefono,
          onCodigoEnviado: (verificationId) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _reenviando = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.otpCodigoReenviado)),
            );
          },
          // Poco probable en un reenvío (ya se pasó por aquí una vez sin
          // autoverificar), pero si Android lo detecta solo, se completa
          // sesión igual que en login_screen.dart en vez de dejar a medias.
          onAutoVerificado: (credential) async {
            if (!mounted) return;
            setState(() => _reenviando = false);
            await ref.read(authProvider.notifier).completarConCredencialTelefono(
                  credential,
                  nombre: widget.nombre,
                  role: widget.role,
                  esRegistro: widget.esRegistro,
                  recordarSesion: widget.recordarSesion,
                );
            if (!mounted) return;
            final usuario = ref.read(authProvider).usuario;
            if (usuario == null) return;
            final destino = switch (usuario.role) {
              UserRole.profesional => const ProfesionalShellScreen(),
              UserRole.admin => const AdminScreen(),
              UserRole.cliente => const ClienteShellScreen(),
            };
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => destino),
              (route) => false,
            );
          },
          onError: (codigoError) {
            if (!mounted) return;
            setState(() {
              _errorLocal = mensajeAuthError(codigoError, t);
              _reenviando = false;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.otpTitulo)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                t.otpDescripcion(widget.telefono),
                style: TextStyle(fontSize: 14.5, color: colorScheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codigoController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: InputDecoration(labelText: t.otpFieldCodigo, counterText: ''),
                onSubmitted: (_) => _confirmar(),
              ),
              if (_errorLocal != null || authState.errorCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    _errorLocal ?? mensajeAuthError(authState.errorCode!, t),
                    style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: authState.cargando ? null : _confirmar,
                child: authState.cargando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(t.otpBtnConfirmar),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _reenviando ? null : _reenviar,
                child: Text(t.otpReenviarCodigo),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.otpCambiarNumero),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
