import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/entrada_animada.dart';
import 'editar_perfil_screen.dart';
import 'mis_solicitudes_screen.dart';
import 'mis_valoraciones_screen.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final usuario = ref.watch(authProvider).usuario;

    return Scaffold(
      appBar: AppBar(title: Text(t.navPerfil)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EntradaAnimada(
            child: Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: usuario?.fotoPerfilUrl != null ? NetworkImage(usuario!.fotoPerfilUrl!) : null,
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: Text(t.perfilFavoritos),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO (Fase 3): pantalla de favoritos
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.proximamenteTitulo)),
                      );
                    },
                  ),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(t.perfilConfiguracion),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.proximamenteTitulo)),
                      );
                    },
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
        ],
      ),
    );
  }
}
