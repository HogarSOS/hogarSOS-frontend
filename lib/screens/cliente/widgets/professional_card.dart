import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/professional_summary_model.dart';
import '../../../utils/category_display.dart';
import '../../../widgets/entrada_animada.dart';
import '../../../widgets/verification_badge.dart';

class ProfessionalCard extends StatelessWidget {
  const ProfessionalCard({
    super.key,
    required this.profesional,
    required this.onTap,
    required this.retraso,
  });

  final ProfessionalSummary profesional;
  final VoidCallback onTap;
  final Duration retraso;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final p = profesional;
    final categoriaPrincipal = p.categorias.isNotEmpty ? p.categorias.first : '';
    final colorCategoria = colorParaCategoria(categoriaPrincipal);
    final categoriasLocalizadas = p.categorias.map((c) => nombreLocalizadoCategoria(context, c)).join(' · ');

    return EntradaAnimada(
      retraso: retraso,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorCategoria.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    // CachedNetworkImageProvider (con caché de disco) en vez
                    // de NetworkImage (solo caché en memoria, se pierde en
                    // cuanto el widget se recrea): el mismo profesional
                    // aparece en la búsqueda, en su detalle y en su perfil,
                    // así que sin caché de disco su foto se re-descarga cada
                    // vez que se reconstruye esta tarjeta.
                    image: p.fotoPerfilUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(p.fotoPerfilUrl!, maxWidth: 160, maxHeight: 160),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: p.fotoPerfilUrl == null
                      ? Icon(
                          iconoParaCategoria(categoriaPrincipal),
                          color: colorCategoria,
                          size: 26,
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
                              p.nombre,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.estaVerificado) ...[
                            const SizedBox(width: 4),
                            const VerificationBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoriasLocalizadas,
                        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            p.valoracionMedia.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${t.buscarTrabajos(p.totalTrabajos)})',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.disponible
                            ? colorScheme.tertiaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p.disponible ? t.buscarDisponibleAhora : t.buscarNoDisponible,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: p.disponible
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
