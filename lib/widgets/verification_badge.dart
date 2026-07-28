import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Distintivo visual de "profesional verificado". Puramente informativo:
/// no decide si el profesional puede operar (eso lo controla el backend
/// vía REQUIRE_PROFESSIONAL_VERIFICATION) — aquí solo se muestra si
/// `estadoVerificacion == 'aprobado'`, para que el cliente lo vea aunque
/// el flag esté desactivado y haya profesionales sin aprobar visibles.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, this.conEtiqueta = false});

  /// Si es true, muestra el icono junto al texto ("Verificado"). Si es
  /// false, muestra solo el icono (para espacios reducidos como tarjetas).
  final bool conEtiqueta;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (!conEtiqueta) {
      return Icon(Icons.verified_rounded, size: 16, color: colorScheme.primary);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            t.distintivoVerificado,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
