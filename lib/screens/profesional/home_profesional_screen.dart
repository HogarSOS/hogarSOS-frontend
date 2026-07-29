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

  Future<void> _aceptar(BuildContext context, WidgetRef ref, NearbyRequest solicitud) async {
    final t = AppLocalizations.of(context);
    try {
      await ref.read(nearbyRequestsProvider.notifier).aceptar(solicitud.id);
      // La solicitud recién aceptada ya cuenta como "trabajo activo" —
      // sin invalidar esto aquí, el contador/tarjeta de "Trabajos
      // activos" de esta misma pantalla se quedaba desactualizado hasta
      // el próximo pull-to-refresh o hasta salir y volver a entrar.
      ref.invalidate(assignedRequestsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profesionalSolicitudAceptada)),
      );
    } catch (e) {
      debugPrint('[HomeProfesionalScreen] Error al aceptar solicitud: $e');
      if (!context.mounted) return;
      // Antes mostraba siempre el mismo texto genérico
      // (profesionalYaNoDisponible) para CUALQUIER fallo — un 403 por
      // no estar verificado se veía exactamente igual que un 409 por
      // condición de carrera (otro profesional se adelantó). El
      // backend ya manda mensajes distintos para cada caso (ver
      // acceptServiceRequest en serviceRequest.controller.ts); esto
      // solo hacía falta dejar de ignorarlos.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalYaNoDisponible, t: t))),
      );
      ref.read(nearbyRequestsProvider.notifier).cargar();
    }
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
                              onAceptar: () => _aceptar(context, ref, solicitud),
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
    required this.onAceptar,
  });

  final NearbyRequest solicitud;
  final VoidCallback onIgnorar;
  final VoidCallback onAceptar;

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
                    onPressed: onAceptar,
                    child: Text(t.profesionalAceptar),
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
