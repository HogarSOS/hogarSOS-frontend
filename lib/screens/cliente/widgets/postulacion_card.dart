import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/postulacion_model.dart';
import '../../../utils/tipo_profesional_display.dart';
import '../../../widgets/verification_badge.dart';
import '../../../utils/imagen_autenticada.dart';

/// Tarjeta de un candidato en la pantalla "Elegir profesional" — mismo
/// lenguaje visual que ProfessionalCard (búsqueda), pero con los datos
/// propios de una candidatura (mensaje de disponibilidad, distancia) y
/// el botón de elegir en vez de navegar a un perfil.
class PostulacionCard extends StatelessWidget {
  const PostulacionCard({super.key, required this.candidato, required this.onElegir});

  final PostulacionCandidate candidato;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final c = candidato;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: c.fotoPerfilUrl != null
                      ? imagenDeRed(c.fotoPerfilUrl!, maxWidth: 160, maxHeight: 160)
                      : null,
                  child: c.fotoPerfilUrl == null
                      ? Text(
                          c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
                          style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.nombre,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.estaVerificado) ...[
                            const SizedBox(width: 4),
                            const VerificationBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            c.valoracionMedia.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${t.buscarTrabajos(c.totalValoraciones)})',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                          if (c.distanciaMetros != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.location_on, size: 13, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              t.profesionalDistanciaKm((c.distanciaMetros! / 1000).toStringAsFixed(1)),
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                      // Tipo declarado (Autónomo/Empresa/Particular) como chip
                      // propio, separado del nombre: el cliente lo ve ANTES de
                      // elegir sin entrar al perfil (hallazgo C del cierre P0).
                      // API antigua o tipo desconocido → null → no se pinta.
                      // Va en su propia línea (no en la fila del nombre ni la
                      // de valoración) para que un nombre largo o la fuente
                      // grande del sistema nunca lo desborden.
                      // (Merge 2026-08-24: dos implementaciones independientes
                      // del mismo hallazgo — se conserva esta, la de bcd4709,
                      // que llegó con test dedicado.)
                      if (c.tipoProfesional != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            etiquetaTipoProfesional(t, c.tipoProfesional!),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${c.mensaje}"',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onElegir,
                child: Text(t.seleccionarProfesionalElegir),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
