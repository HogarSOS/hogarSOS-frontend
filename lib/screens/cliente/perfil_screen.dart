import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/entrada_animada.dart';
import '../../widgets/eliminar_cuenta.dart';
import 'editar_perfil_screen.dart';
import 'mis_solicitudes_screen.dart';
import 'mis_valoraciones_screen.dart';
import '../legal/privacidad_screen.dart';
import '../legal/terminos_screen.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  // Se recalcula en build() a partir de AuthService — no es un simple
  // `final bool` de una vez, porque "Ya lo confirmé" necesita volver a
  // preguntarle a Firebase (reload()) y reflejar el resultado aquí.
  bool _emailVerificado = true;
  bool _comprobandoVerificacion = false;

  @override
  void initState() {
    super.initState();
    _emailVerificado = ref.read(authServiceProvider).emailVerificado;
  }

  Future<void> _reenviarVerificacion(BuildContext context, AppLocalizations t) async {
    try {
      await ref.read(authServiceProvider).reenviarEmailVerificacion();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.perfilEmailVerificacionReenviada)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _comprobarVerificacion(BuildContext context, AppLocalizations t) async {
    setState(() => _comprobandoVerificacion = true);
    final verificado = await ref.read(authServiceProvider).recargarYComprobarEmailVerificado();
    if (!context.mounted) return;
    setState(() {
      _emailVerificado = verificado;
      _comprobandoVerificacion = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(verificado ? t.perfilEmailVerificadoExito : t.perfilEmailAunNoVerificado)),
    );
  }

  String _rolTexto(AppLocalizations t, UserRole role) {
    switch (role) {
      case UserRole.profesional:
        return t.perfilRolProfesional;
      case UserRole.admin:
        return t.perfilRolAdmin;
      case UserRole.cliente:
        return t.perfilRolCliente;
    }
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.perfilCerrarSesion),
        content: Text(t.perfilConfirmarSalir),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.perfilCerrarSesion),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ref.read(authProvider.notifier).logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final usuario = ref.watch(authProvider).usuario;

    return Scaffold(
      appBar: AppBar(title: Text(t.navPerfil)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_emailVerificado)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: EntradaAnimada(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mark_email_unread_outlined, color: colorScheme.onTertiaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.perfilEmailSinVerificarTitulo,
                              style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onTertiaryContainer),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.perfilEmailSinVerificarDescripcion,
                        style: TextStyle(fontSize: 13, color: colorScheme.onTertiaryContainer, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reenviarVerificacion(context, t),
                              child: Text(t.perfilEmailSinVerificarReenviar, style: const TextStyle(fontSize: 12.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: _comprobandoVerificacion ? null : () => _comprobarVerificacion(context, t),
                              child: _comprobandoVerificacion
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(t.perfilEmailSinVerificarYaConfirme, style: const TextStyle(fontSize: 12.5)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          EntradaAnimada(
            child: Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: usuario?.fotoPerfilUrl != null
                      ? CachedNetworkImageProvider(usuario!.fotoPerfilUrl!, maxWidth: 320, maxHeight: 320)
                      : null,
                  child: usuario?.fotoPerfilUrl == null
                      ? Text(
                          (usuario?.nombre.isNotEmpty ?? false) ? usuario!.nombre[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  usuario?.nombre ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    usuario != null ? _rolTexto(t, usuario.role) : '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.perfilMiembroDesde,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 32),
          EntradaAnimada(
            retraso: const Duration(milliseconds: 100),
            child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(t.perfilEditar),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(t.misValoracionesTitulo),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MisValoracionesScreen()),
                      );
                    },
                  ),
                  // Favoritos oculto temporalmente (ver home_cliente_screen.dart)
                  // — nunca se implementó de verdad, solo mostraba "Próximamente".
                  // No se borra t.perfilFavoritos ni la lógica, solo este acceso.
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(t.perfilMisSolicitudes),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MisSolicitudesScreen()),
                      );
                    },
                  ),
                  // "Configuración" oculto temporalmente, mismo motivo que
                  // Favoritos arriba: nunca se implementó de verdad, solo
                  // mostraba "Próximamente". No se borra t.perfilConfiguracion
                  // ni el icono, solo este acceso — hasta que haya algo real
                  // que configurar (notificaciones, idioma, etc.).
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(t.perfilPrivacidad),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacidadScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(t.perfilTerminos),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TerminosScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          const SizedBox(height: 20),
          EntradaAnimada(
            retraso: const Duration(milliseconds: 160),
            child: OutlinedButton.icon(
              onPressed: () => _confirmarCerrarSesion(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(t.perfilCerrarSesion),
              style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
            ),
          ),
          const SizedBox(height: 10),
          EntradaAnimada(
            retraso: const Duration(milliseconds: 180),
            child: TextButton(
              onPressed: () => confirmarYEliminarCuenta(context, ref),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: Text(t.perfilEliminarCuenta),
            ),
          ),
        ],
      ),
    );
  }
}
