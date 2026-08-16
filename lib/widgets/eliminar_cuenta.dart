import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

/// Eliminar cuenta — requisito de la política de datos de Google Play
/// (obligatoria desde abril de 2024): cualquier app que permite crear
/// cuenta debe ofrecer también una vía para eliminarla dentro de la
/// app (ver también la página pública /eliminar-cuenta en
/// legal.routes.ts). Compartido entre el perfil de cliente y el de
/// profesional — mismo endpoint (DELETE /api/users/me) para ambos
/// roles, mismo diálogo de confirmación.
Future<void> confirmarYEliminarCuenta(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.perfilEliminarCuentaConfirmarTitulo),
      content: Text(t.perfilEliminarCuentaConfirmarTexto),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.perfilCancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          child: Text(t.perfilEliminarCuentaBotonConfirmar),
        ),
      ],
    ),
  );

  if (confirmado != true) return;

  try {
    await UserService().eliminarCuenta();
  } catch (e) {
    debugPrint('[eliminarCuenta] Error al eliminar la cuenta: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.perfilEliminarCuentaError)),
    );
    return;
  }

  if (!context.mounted) return;
  // Fuente única de verdad de navegación (revisión arquitectónica
  // 2026-08-16): no se navega a LoginScreen aquí — este widget vive
  // dentro del árbol que ya controla AuthGateScreen (Perfil de cliente
  // o de profesional), así que en cuanto logout() deja
  // authProvider.usuario en null, AuthGateScreen reconstruye solo y
  // muestra LoginScreen. Navegar aquí ADEMÁS creaba una segunda
  // instancia compitiendo con la de AuthGateScreen — la misma causa
  // raíz que el crash "ref after disposed" en el profesional.
  await ref.read(authProvider.notifier).logout();
}
