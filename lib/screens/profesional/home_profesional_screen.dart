import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/disponibilidad_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../services/professional_service.dart' show EstadoCuentaStripe, ModoDisponibilidad;
import '../../theme/brand_mark.dart';
import '../../utils/error_extraction.dart';
import '../../utils/polling_lifecycle_mixin.dart';
import '../../widgets/animated_diff_list.dart';
import '../../widgets/entrada_animada.dart';
import 'trabajos_activos_profesional_screen.dart';
import '../../utils/imagen_autenticada.dart';

/// Pestaña "Inicio" del Panel Profesional: la lista de solicitudes
/// cercanas, más un acceso rápido en el AppBar para ponerse "No
/// disponible" sin salir de esta pantalla (roadmap económico, punto 2)
/// — el control completo (horario laboral/24h) sigue viviendo en "Mi
/// perfil", este botón solo cubre el caso rápido de "quiero dejar de
/// recibir solicitudes ya mismo".
class HomeProfesionalScreen extends ConsumerStatefulWidget {
  const HomeProfesionalScreen({super.key});

  @override
  ConsumerState<HomeProfesionalScreen> createState() => _HomeProfesionalScreenState();
}

class _HomeProfesionalScreenState extends ConsumerState<HomeProfesionalScreen>
    with WidgetsBindingObserver, PollingLifecycleMixin {
  @override
  void initState() {
    super.initState();
    // Antes solo se cargaba una vez al entrar y con pull-to-refresh
    // manual — un profesional que se quedaba con la pestaña abierta no
    // veía solicitudes nuevas sin deslizar. Mismo patrón de sondeo que
    // seguimiento_solicitud_screen.dart, pero cada 10s (no 5s): es una
    // lista, no un trabajo concreto ya aceptado, así que hay menos
    // urgencia y así se reduce la carga de red. Se pausa solo con la
    // app en segundo plano (ver PollingLifecycleMixin) — esta pestaña
    // sigue viva de fondo aunque no sea la visible (IndexedStack en
    // profesional_shell_screen.dart), así que sin esto sondeaba sin
    // parar incluso con el móvil bloqueado.
    startPolling(const Duration(seconds: 10), () {
      ref.read(nearbyRequestsProvider.notifier).cargar();
    });
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

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
        // El diálogo original ponía el TextField directo en un Column
        // dentro de content: con el teclado abierto en un móvil pequeño,
        // la altura disponible baja y el Column no cabe -> "BOTTOM
        // OVERFLOWED BY XX PIXELS". Envolver en SingleChildScrollView
        // hace que solo el contenido (no los botones de actions, que
        // quedan fuera y siempre visibles) se desplace; el padding con
        // viewInsets.bottom deja hueco extra para que el TextField no
        // quede tapado por el teclado mientras se escribe.
        content: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
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

  /// Apaga la disponibilidad al instante — sin pedir confirmación, a
  /// diferencia de activarla (que si requiere perfil completo/verificado,
  /// comprobado dentro del propio provider al activarla desde "Mi
  /// perfil"). Desactivar nunca se bloquea.
  Future<void> _ponerseNoDisponible(BuildContext context, WidgetRef ref, ModoDisponibilidad modoActual) async {
    final t = AppLocalizations.of(context);
    try {
      await ref.read(disponibilidadProvider.notifier).actualizar(disponible: false, modo: modoActual);
    } catch (e) {
      debugPrint('[HomeProfesionalScreen] Error al ponerse no disponible: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalErrorDisponibilidad, t: t))),
      );
    }
  }

  /// BUG 002 (QA, 2026-08-03): la tarjeta de disponibilidad solo permitía
  /// pausar — una vez en "No disponible" desaparecía del todo, sin dejar
  /// rastro del estado ni forma de volver a activarse sin ir a "Mi
  /// perfil". Ahora la tarjeta sigue visible en los dos estados (ver
  /// _TarjetaDisponibilidad) y este método reactiva directamente desde
  /// aquí, con los mismos requisitos que ya comprobaba
  /// _SelectorDisponibilidad en Mi perfil (perfil completo, verificado,
  /// Stripe configurado) — si falta algo, se explica con el mismo texto
  /// en vez de intentarlo y fallar en el backend. Reutiliza el último
  /// `modo` conocido (horario laboral / 24h) en vez de forzar uno fijo.
  Future<void> _ponerseDisponible(BuildContext context, WidgetRef ref, DisponibilidadState estado) async {
    final t = AppLocalizations.of(context);

    if (!estado.perfilCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.disponibilidadPerfilIncompleto)));
      return;
    }
    if (!estado.estaVerificado) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.disponibilidadPendienteVerificacion)));
      return;
    }
    if (estado.estadoCuentaStripe != EstadoCuentaStripe.configurada) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.disponibilidadPendienteStripe)));
      return;
    }

    try {
      await ref.read(disponibilidadProvider.notifier).actualizar(disponible: true, modo: estado.modo);
    } catch (e) {
      debugPrint('[HomeProfesionalScreen] Error al ponerse disponible: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalErrorDisponibilidad, t: t))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final solicitudesAsync = ref.watch(nearbyRequestsProvider);
    final trabajosActivosAsync = ref.watch(assignedRequestsProvider);
    final disponibilidadAsync = ref.watch(disponibilidadProvider);

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
        onRefresh: () => Future.wait([
          ref.read(nearbyRequestsProvider.notifier).cargar(),
          ref.read(assignedRequestsProvider.notifier).cargar(),
        ]),
        child: CustomScrollView(
          slivers: [
            // Acceso rápido a disponibilidad (roadmap económico, punto 2):
            // antes era un icono de rayo suelto en el AppBar, sin texto — un
            // usuario nuevo no tenía forma de adivinar qué hacía sin
            // mantener pulsado para ver el tooltip, y un toque perdido ahí
            // apagaba la disponibilidad sin confirmación ni aviso previo.
            // BUG 002 (QA, 2026-08-03): la tarjeta solo se mostraba estando
            // disponible — al pulsar "No disponible" desaparecía del todo,
            // dejando el estado del profesional sin ningún indicio visible
            // y sin forma de volver a activarse sin salir a "Mi perfil".
            // Ahora la tarjeta es siempre visible (ver _TarjetaDisponibilidad),
            // en los dos estados, con su propio botón para alternar.
            disponibilidadAsync.maybeWhen(
              data: (estado) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _TarjetaDisponibilidad(
                    estado: estado,
                    onPausar: () => _ponerseNoDisponible(context, ref, estado.modo),
                    onActivar: () => _ponerseDisponible(context, ref, estado),
                  ),
                ),
              ),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
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
                // AnimatedSliverList en vez de un SliverList normal: el
                // provider ya no pasa por loading() en cada refresco
                // silencioso (ver NearbyRequestsNotifier.cargar()), así
                // que aquí solo hace falta traducir altas/bajas en
                // transiciones suaves en vez de reconstruir todo de golpe.
                return AnimatedSliverList<NearbyRequest>(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  items: solicitudes,
                  idOf: (s) => s.id,
                  itemBuilder: (context, solicitud, index) {
                    return Padding(
                      key: ValueKey(solicitud.id),
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

/// Tarjeta de disponibilidad, siempre visible — antes solo existía en
/// el estado "disponible" (con un botón para pausar), y desaparecía
/// del todo al pasar a "No disponible" (BUG 002 de QA: el estado
/// quedaba sin ningún indicio visible y sin forma de volver a
/// activarse sin salir a "Mi perfil"). Ahora cubre los dos estados con
/// el mismo componente, dejando claro tanto la disponibilidad actual
/// como la acción del botón, sin necesitar un tooltip.
class _TarjetaDisponibilidad extends StatelessWidget {
  const _TarjetaDisponibilidad({
    required this.estado,
    required this.onPausar,
    required this.onActivar,
  });

  final DisponibilidadState estado;
  final VoidCallback onPausar;
  final VoidCallback onActivar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (estado.disponible) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.bolt, color: Colors.amber.shade800, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.profesionalDisponibleAhoraAviso,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: onPausar,
              style: TextButton.styleFrom(foregroundColor: Colors.amber.shade900),
              child: Text(t.disponibilidadOpcionNoDisponibleTitulo),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.disponibilidadOpcionNoDisponibleTitulo,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  t.profesionalNoDisponibleAyuda,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onActivar,
            child: Text(t.profesionalPonerseDisponibleBoton),
          ),
        ],
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
                      ? imagenDeRed(solicitud.clienteFotoUrl!, maxWidth: 120, maxHeight: 120)
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
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      onPressed: onIgnorar,
                      child: Text(
                        t.profesionalIgnorar,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      onPressed: onPostularse,
                      child: Text(
                        t.profesionalPostularme,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
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
