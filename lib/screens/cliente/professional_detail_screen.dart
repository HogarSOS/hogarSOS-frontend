import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/professional_summary_model.dart';
import '../../services/professional_service.dart';
import '../../utils/category_display.dart';
import '../../widgets/verification_badge.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  const ProfessionalDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ProfessionalDetailScreen> createState() => _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  final _servicio = ProfessionalService();
  late Future<ProfessionalPublicProfile> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerPerfilPublico(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: FutureBuilder<ProfessionalPublicProfile>(
        future: _futuro,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(t.perfilProCargandoError));
          }
          return _Contenido(perfil: snapshot.data!);
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.perfil});

  final ProfessionalPublicProfile perfil;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: colorScheme.primaryContainer,
                  child: Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: colorScheme.primary,
                      backgroundImage:
                          perfil.fotoPerfilUrl != null ? CachedNetworkImageProvider(perfil.fotoPerfilUrl!) : null,
                      child: perfil.fotoPerfilUrl == null
                          ? Text(
                              perfil.nombre.isNotEmpty ? perfil.nombre[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  perfil.nombre,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (perfil.estaVerificado) ...[
                                const SizedBox(width: 8),
                                const VerificationBadge(conEtiqueta: true),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: perfil.disponible
                                ? colorScheme.tertiaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            perfil.disponible ? t.buscarDisponibleAhora : t.buscarNoDisponible,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: perfil.disponible
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          perfil.valoracionMedia.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${t.buscarTrabajos(perfil.totalTrabajos)}',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(t.perfilProServiciosTitulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: perfil.categorias.map((c) {
                        return Chip(
                          avatar: Icon(iconoParaCategoria(c), size: 16, color: colorParaCategoria(c)),
                          label: Text(nombreLocalizadoCategoria(context, c)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Text(t.perfilProGaleriaTitulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    // Estado vacío honesto: hoy no existe subida de fotos de
                    // trabajos en el backend (requeriría nuevo modelo de
                    // datos, fuera del alcance de "no modificar el esquema").
                    // Se muestra así en vez de simular fotos que no son reales.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 32, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              t.perfilProSinGaleria,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(t.perfilProOpinionesTitulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (perfil.reviews.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Text(
                    t.perfilProSinOpiniones,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = perfil.reviews[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(review.autor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
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
                      );
                    },
                    childCount: perfil.reviews.length,
                  ),
                ),
              ),
          ],
        ),
        // Botón fijo fuera del scroll — siempre visible. La creación de
        // solicitud dirigida a UN profesional concreto no existe hoy en
        // el backend (createServiceRequest difunde a profesionales
        // cercanos, no permite elegir uno) — cambiar eso es lógica de
        // negocio, no una simple lectura, así que no lo modifico aquí.
        // Se guía al usuario al flujo real que ya funciona (Inicio).
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.perfilProSolicitarInfo)),
              );
              Navigator.of(context).pop();
            },
            child: Text(t.perfilProSolicitarBtn),
          ),
        ),
      ],
    );
  }
}
