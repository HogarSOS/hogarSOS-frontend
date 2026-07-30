import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/service_request_provider.dart';
import '../../theme/brand_mark.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import 'trabajos_activos_profesional_screen.dart';

/// Pestaña "Inicio" del Panel Profesional: solo la lista de solicitudes
/// cercanas. El interruptor de disponibilidad y el acceso a "Mi perfil"
/// ya no viven aquí — tienen sus propias pestañas en
/// ProfesionalShellScreen, así no hay dos sitios distintos para lo
/// mismo ni hace falta un botón extra en el AppBar para llegar a ellos.
class HomeProfesionalScreen extends ConsumerWidget {
  const HomeProfesionalScreen({super.key});

  Future<void> _postularse(BuildContext context, WidgetRef ref, NearbyRequest solicitud) async {
    final t = AppLocalizations.of(context);

    // Mismo diálogo que antes se usaba justo tras aceptar (¿cuándo
    // puedes ir?) — ahora ese mensaje ES la candidatura en sí, no algo
    // que se manda por chat después. Devuelve null si canceló.
    final mensaje = await _mostrarDialogoDisponibilidad(context, t);
    if (mensaje == null || !context.mounted) return;
    if (mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profesionalPostulacionMensajeObligatorio)),
      );
      return;
    }

    try {
      await ref.read(nearbyRequestsProvider.notifier).postularse(solicitud.id, mensaje: mensaje);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profesionalPostulacionEnviada)),
      );
    } catch (e) {
      debugPrint('[HomeProfesionalScreen] Error al postularse: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalYaNoDisponible, t: t))),
      );
      ref.read(nearbyRequestsProvider.notifier).cargar();
    }
  }

  Future<String?> _mostrarDialogoDisponibilidad(BuildContext context, AppLocalizations t) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.profesionalDisponibilidadTitulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.profesionalDisponibilidadSubtitulo,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                t.profesionalDisponibilidadSugerencia1,
                t.profesionalDisponibilidadSugerencia2,
                t.profesionalDisponibilidadSugerencia3,
              ]
                  .map((sugerencia) => ActionChip(
                        label: Text(sugerencia, style: const TextStyle(fontSize: 12.5)),
                        onPressed: () => controller.text = sugerencia,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(hintText: t.profesionalDisponibilidadHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.profesionalDisponibilidadConfirmar),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final solicitudesAsync = ref.watch(nearbyRequestsProvider);
    final trabajosActivosAsync = ref.watch(assignedRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HogarSosMark(size: 28),
            const SizedBox(width: 10),
            Text(t.profesionalTituloSolicitudes),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(nearbyRequestsProvider.notifier).cargar();
          ref.invalidate(assignedRequestsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Solo se muestra si hay trabajos aceptados pendientes de
            // completar — sin este acceso, aceptar una solicitud la
            // hacía desaparecer sin dejar ningún rastro ni forma de
            // volver a ella (ver trabajos_activos_profesional_screen.dart).
            trabajosActivosAsync.maybeWhen(
              data: (trabajos) {
                if (trabajos.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _TarjetaTrabajosActivos(
                      cantidad: trabajos.length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrabajosActivosProfesionalScreen()),
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            solicitudesAsync.when(
              data: (solicitudes) {
                if (solicitudes.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EstadoVacio(icono: Icons.inbox_outlined, titulo: t.profesionalSinSolicitudes),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final solicitud = solicitudes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EntradaAnimada(
                            retraso: Duration(milliseconds: 40 * index),
                            child: _TarjetaSolicitudCercana(
                              solicitud: solicitud,
                              onIgnorar: () => ref.read(nearbyRequestsProvider.notifier).ocultar(solicitud.id),
                              onPostularse: () => _postularse(context, ref, solicitud),
                            ),
                          ),
                        );
                      },
                      childCount: solicitudes.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              // Antes mostraba siempre el mismo texto genérico, incluso
              // cuando el motivo real (que el backend sí manda) es que la
              // cuenta del profesional todavía no ha sido aprobada por un
              // admin — un profesional recién registrado veía "error al
              // cargar" sin ninguna pista de que solo tenía que esperar la
              // verificación.
              error: (error, __) => SliverFillRemaining(
                hasScrollBody: false,
                child: _EstadoVacio(
                  icono: Icons.error_outline,
                  titulo: mensajeDeError(error, contexto: t.profesionalErrorCargar, t: t),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaTrabajosActivos extends StatelessWidget {
  const _TarjetaTrabajosActivos({required this.cantidad, required this.onTap});

  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.work_outline, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.profesionalTrabajosActivos(cantidad),
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaSolicitudCercana extends StatelessWidget {
  const _TarjetaSolicitudCercana({
    required this.solicitud,
    required this.onIgnorar,
    required this.onPostularse,
  });

  final NearbyRequest solicitud;
  final VoidCallback onIgnorar;
  final VoidCallback onPostularse;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final distanciaKm = (solicitud.distanciaMetros / 1000).toStringAsFixed(1);

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: solicitud.clienteFotoUrl != null
                      ? CachedNetworkImageProvider(solicitud.clienteFotoUrl!)
                      : null,
                  child: solicitud.clienteFotoUrl == null
                      ? Text(
                          solicitud.clienteNombre.isNotEmpty ? solicitud.clienteNombre[0].toUpperCase() : '?',
                          style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    solicitud.clienteNombre,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 13, color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        t.profesionalDistanciaKm(distanciaKm),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              solicitud.descripcion,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 14),
            if (solicitud.yaPostulado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      t.profesionalYaPostulado,
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onIgnorar,
                      child: Text(t.profesionalIgnorar),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPostularse,
                      child: Text(t.profesionalPostularme),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.icono, required this.titulo});

  final IconData icono;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(titulo, style: const TextStyle(fontSize: 15), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
