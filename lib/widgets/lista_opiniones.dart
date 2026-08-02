import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/professional_summary_model.dart';

/// Resumen (media + total) y lista de opiniones — el mismo widget vale
/// para el perfil propio del profesional y para el del cliente, para
/// que ambos "se sientan" la misma funcionalidad en vez de dos
/// implementaciones parecidas pero distintas.
class ResumenYListaOpiniones extends StatelessWidget {
  const ResumenYListaOpiniones({
    super.key,
    required this.valoracionMedia,
    required this.totalValoraciones,
    required this.opiniones,
  });

  final double valoracionMedia;
  final int totalValoraciones;
  final List<ProfessionalReview> opiniones;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 22, color: Colors.amber.shade700),
            const SizedBox(width: 6),
            Text(
              valoracionMedia.toStringAsFixed(1),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              t.opinionesTotal(totalValoraciones),
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (opiniones.isEmpty)
          Text(
            t.perfilProSinOpiniones,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          )
        else
          ...opiniones.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Expanded: el nombre es texto libre del usuario
                        // (sin límite de longitud conocido) — sin esto,
                        // un nombre largo desborda la fila contra las 5
                        // estrellas de al lado.
                        Expanded(
                          child: Text(
                            review.autor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (review.comentario != null && review.comentario!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(review.comentario!, style: const TextStyle(fontSize: 13.5)),
                    ],
                  ],
                ),
              )),
      ],
    );
  }
}
