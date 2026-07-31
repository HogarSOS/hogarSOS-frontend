import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/presupuesto_model.dart';
import '../../models/service_request_model.dart';
import '../../providers/chat_read_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../services/service_request_service.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';
import '../reportar_problema_screen.dart';
import '../cliente/valoracion_screen.dart';

/// Trabajos que el profesional aceptó — en curso o ya completados
/// recientemente.
///
/// Antes de esta pantalla, aceptar una solicitud la hacía desaparecer
/// para siempre desde el punto de vista del profesional: no había
/// forma de volver a verla, escribir al cliente, marcarla como
/// terminada ni, tras completarla, valorar al cliente. Este era el
/// hueco real detrás de "revisa el chat" — el cliente sí podía abrir
/// el chat desde "Mis solicitudes", pero el profesional nunca tenía un
/// botón equivalente.
class TrabajosActivosProfesionalScreen extends ConsumerWidget {
  const TrabajosActivosProfesionalScreen({super.key});

  /// Completa el trabajo. El importe sale siempre del presupuesto ya
  /// aceptado (`trabajo.presupuesto`), nunca de un número escrito a
  /// mano: para "cerrado" solo hace falta confirmar, para "por_horas"
  /// se piden las horas reales y el backend calcula tarifa × horas.
  Future<void> _completar(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    final presupuesto = trabajo.presupuesto;
    double? horasReales;

    if (presupuesto?.tipo == TipoPresupuesto.porHoras) {
      final controller = TextEditingController();
      horasReales = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.trabajosActivosHorasRealesTitulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.trabajosActivosHorasRealesTarifa(presupuesto!.tarifaHora!.toStringAsFixed(2)),
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t.trabajosActivosHorasRealesHint),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.perfilCancelar),
            ),
            FilledButton(
              onPressed: () {
                final valor = double.tryParse(controller.text.replaceAll(',', '.'));
                Navigator.of(context).pop(valor);
              },
              child: Text(t.trabajosActivosPrecioFinalConfirmar),
            ),
          ],
        ),
      );
      if (horasReales == null || horasReales <= 0 || !context.mounted) return;
    } else {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.trabajosActivosPrecioFinalTitulo),
          content: Text(t.trabajosActivosCompletarCerradoConfirmar),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.perfilCancelar),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.trabajosActivosPrecioFinalConfirmar),
            ),
          ],
        ),
      );
      if (confirmado != true || !context.mounted) return;
    }

    final esPorHoras = presupuesto?.tipo == TipoPresupuesto.porHoras;

    try {
      await ServiceRequestService().completar(trabajo.id, horasReales: horasReales);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(esPorHoras ? t.trabajosActivosHorasEnviadasExito : t.trabajosActivosCompletadoExito)),
      );
      ref.invalidate(assignedRequestsProvider);

      // "Por horas" no completa aquí de verdad — queda pendiente de que
      // el cliente confirme las horas (ver responderCierreHoras), así
      // que no tiene sentido invitar a valorar todavía.
      if (esPorHoras) return;

      // Invitación automática a valorar al cliente, justo al completar
      // — el profesional puede omitirla (botón atrás) y valorar más
      // tarde desde esta misma lista, ver _TarjetaTrabajo más abajo.
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ValoracionScreen(serviceRequestId: trabajo.id)),
      );
      ref.invalidate(assignedRequestsProvider);
    } catch (e) {
      debugPrint('[TrabajosActivosProfesionalScreen] Error al completar: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.trabajosActivosCompletadoError, t: t))),
      );
    }
  }

  /// Diálogo para pedir más horas cuando un trabajo "por_horas" se
  /// alarga más de lo estimado — nunca se cobra el exceso fuera de la
  /// app, hay que pasar por aquí y que el cliente lo acepte.
  Future<void> _pedirAmpliacion(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    final horasController = TextEditingController();
    final mensajeController = TextEditingController();

    final pedido = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trabajosActivosPedirAmpliacionTitulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: horasController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.trabajosActivosPedirAmpliacionHorasHint),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mensajeController,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(hintText: t.presupuestoDialogoMensajeHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () async {
              final horas = double.tryParse(horasController.text.replaceAll(',', '.'));
              if (horas == null || horas <= 0) return;
              try {
                await ServiceRequestService().pedirAmpliacion(
                  trabajo.id,
                  horasAdicionales: horas,
                  mensaje: mensajeController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              } catch (e) {
                debugPrint('[TrabajosActivosProfesionalScreen] Error al pedir ampliación: $e');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mensajeDeError(e, contexto: t.trabajosActivosPedirAmpliacionError, t: t))),
                );
              }
            },
            child: Text(t.trabajosActivosPrecioFinalConfirmar),
          ),
        ],
      ),
    );

    if (pedido == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.trabajosActivosPedirAmpliacionExito)));
      ref.invalidate(assignedRequestsProvider);
    }
  }

  /// Diálogo para enviar un presupuesto — cerrado (monto fijo) o por
  /// horas (tarifa + horas estimadas). Mismo patrón de AlertDialog con
  /// StatefulBuilder que el resto de diálogos de esta pantalla, para
  /// poder alternar los campos visibles según el tipo elegido.
  Future<void> _enviarPresupuesto(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    var tipo = TipoPresupuesto.cerrado;
    final montoController = TextEditingController();
    final tarifaController = TextEditingController();
    final horasController = TextEditingController();
    final mensajeController = TextEditingController();

    final enviado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.presupuestoDialogoTitulo),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<TipoPresupuesto>(
                  segments: [
                    ButtonSegment(value: TipoPresupuesto.cerrado, label: Text(t.presupuestoTipoCerrado)),
                    ButtonSegment(value: TipoPresupuesto.porHoras, label: Text(t.presupuestoTipoPorHoras)),
                  ],
                  selected: {tipo},
                  onSelectionChanged: (seleccion) => setState(() => tipo = seleccion.first),
                ),
                const SizedBox(height: 14),
                if (tipo == TipoPresupuesto.cerrado)
                  TextField(
                    controller: montoController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.presupuestoDialogoMontoHint),
                  )
                else ...[
                  TextField(
                    controller: tarifaController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.presupuestoDialogoTarifaHint),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: horasController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.presupuestoDialogoHorasEstimadasHint),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: mensajeController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(hintText: t.presupuestoDialogoMensajeHint),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.perfilCancelar),
            ),
            FilledButton(
              onPressed: () async {
                final mensaje = mensajeController.text.trim();
                try {
                  if (tipo == TipoPresupuesto.cerrado) {
                    final monto = double.tryParse(montoController.text.replaceAll(',', '.'));
                    if (monto == null || monto <= 0) return;
                    await ServiceRequestService().enviarPresupuesto(
                      trabajo.id,
                      tipo: tipo,
                      monto: monto,
                      mensaje: mensaje,
                    );
                  } else {
                    final tarifa = double.tryParse(tarifaController.text.replaceAll(',', '.'));
                    final horas = double.tryParse(horasController.text.replaceAll(',', '.'));
                    if (tarifa == null || tarifa <= 0 || horas == null || horas <= 0) return;
                    await ServiceRequestService().enviarPresupuesto(
                      trabajo.id,
                      tipo: tipo,
                      tarifaHora: tarifa,
                      horasEstimadas: horas,
                      mensaje: mensaje,
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                } catch (e) {
                  debugPrint('[TrabajosActivosProfesionalScreen] Error al enviar presupuesto: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mensajeDeError(e, contexto: t.presupuestoEnviadoError, t: t))),
                  );
                }
              },
              child: Text(t.trabajosActivosPrecioFinalConfirmar),
            ),
          ],
        ),
      ),
    );

    if (enviado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.presupuestoEnviadoExito)));
      ref.invalidate(assignedRequestsProvider);
    }
  }

  Future<void> _valorar(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ValoracionScreen(serviceRequestId: trabajo.id)),
    );
    if (resultado == true) ref.invalidate(assignedRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final trabajosAsync = ref.watch(assignedRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.trabajosActivosTitulo)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(assignedRequestsProvider),
        child: trabajosAsync.when(
          data: (trabajos) {
            if (trabajos.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(t.trabajosActivosVacio, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trabajos.length,
              itemBuilder: (context, index) {
                final trabajo = trabajos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntradaAnimada(
                    retraso: Duration(milliseconds: 40 * index),
                    child: _TarjetaTrabajo(
                      trabajo: trabajo,
                      noLeido: ref.watch(unreadChatProvider(trabajo.id)),
                      onChat: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            serviceRequestId: trabajo.id,
                            nombreContraparte: trabajo.clienteNombre,
                          ),
                        ),
                      ),
                      onCompletar: () => _completar(context, ref, trabajo),
                      onEnviarPresupuesto: () => _enviarPresupuesto(context, ref, trabajo),
                      onPedirAmpliacion: () => _pedirAmpliacion(context, ref, trabajo),
                      onValorar: () => _valorar(context, ref, trabajo),
                      onReportar: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportarProblemaScreen(serviceRequestId: trabajo.id),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(t.trabajosActivosErrorCargar)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaTrabajo extends StatelessWidget {
  const _TarjetaTrabajo({
    required this.trabajo,
    required this.noLeido,
    required this.onChat,
    required this.onCompletar,
    required this.onEnviarPresupuesto,
    required this.onPedirAmpliacion,
    required this.onValorar,
    required this.onReportar,
  });

  final AssignedRequest trabajo;
  final bool noLeido;
  final VoidCallback onChat;
  final VoidCallback onCompletar;
  final VoidCallback onEnviarPresupuesto;
  final VoidCallback onPedirAmpliacion;
  final VoidCallback onValorar;
  final VoidCallback onReportar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final completado = trabajo.estado == EstadoSolicitud.completada;

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
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: trabajo.clienteFotoUrl != null
                      ? CachedNetworkImageProvider(trabajo.clienteFotoUrl!)
                      : null,
                  child: trabajo.clienteFotoUrl == null
                      ? Text(
                          trabajo.clienteNombre.isNotEmpty ? trabajo.clienteNombre[0].toUpperCase() : '?',
                          style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trabajo.clienteNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        trabajo.categoria,
                        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (completado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.seguimientoCompletada,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(trabajo.descripcion, style: const TextStyle(fontSize: 14, height: 1.35)),
            if (trabajo.direccionTexto != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trabajo.direccionTexto!,
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (completado)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Badge(isLabelVisible: noLeido, child: const Icon(Icons.chat_bubble_outline, size: 18)),
                      label: Text(t.trabajosActivosChat),
                      onPressed: onChat,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: trabajo.tieneValoracion
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  t.seguimientoYaValorado,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : FilledButton.icon(
                            icon: const Icon(Icons.star_outline, size: 18),
                            label: Text(t.seguimientoValorar),
                            onPressed: onValorar,
                          ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Badge(isLabelVisible: noLeido, child: const Icon(Icons.chat_bubble_outline, size: 18)),
                      label: Text(t.trabajosActivosChat),
                      onPressed: onChat,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _botonSegunPresupuesto(t, colorScheme)),
                ],
              ),
              if (_mostrarBotonAmpliacion) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.more_time, size: 18),
                    label: Text(t.trabajosActivosPedirAmpliacion),
                    onPressed: onPedirAmpliacion,
                  ),
                ),
              ] else if (trabajo.ampliacion?.estado == EstadoPresupuesto.pendiente) ...[
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t.trabajosActivosAmpliacionEsperando,
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.report_gmailerrorred_outlined, size: 16, color: colorScheme.error),
                label: Text(
                  t.reportarProblemaBoton,
                  style: TextStyle(color: colorScheme.error, fontSize: 12.5),
                ),
                onPressed: onReportar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sin presupuesto o rechazado: hay que enviar uno antes de poder
  /// completar (el backend rechazaría "completar" con un 409 porque
  /// sin presupuesto aceptado no puede haber pago autorizado). Con uno
  /// pendiente: nada que hacer todavía, solo esperar. Con uno aceptado:
  /// si ya se declararon las horas y el cliente todavía no las ha
  /// confirmado (cierreHoras pendiente), esperar esa confirmación en
  /// vez de ofrecer completar otra vez. Si no, el flujo normal.
  Widget _botonSegunPresupuesto(AppLocalizations t, ColorScheme colorScheme) {
    final presupuesto = trabajo.presupuesto;
    if (presupuesto == null || presupuesto.estado == EstadoPresupuesto.rechazado) {
      return FilledButton.icon(
        icon: const Icon(Icons.request_quote_outlined, size: 18),
        label: Text(t.trabajosActivosEnviarPresupuesto),
        onPressed: onEnviarPresupuesto,
      );
    }
    if (presupuesto.estado == EstadoPresupuesto.pendiente) {
      return _chipEspera(colorScheme, t.trabajosActivosPresupuestoEsperando);
    }
    if (trabajo.cierreHoras?.estado == EstadoPresupuesto.pendiente) {
      return _chipEspera(colorScheme, t.trabajosActivosCierreEsperando);
    }
    return FilledButton.icon(
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: Text(t.trabajosActivosCompletar),
      onPressed: onCompletar,
    );
  }

  Widget _chipEspera(ColorScheme colorScheme, String texto) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// El botón de "Pedir ampliación" solo tiene sentido con un
  /// presupuesto "por_horas" ya aceptado, sin una ampliación ya
  /// pendiente de respuesta, y sin un cierre de horas ya en curso (no
  /// tiene sentido pedir más tiempo si ya se está cerrando el trabajo).
  bool get _mostrarBotonAmpliacion {
    final presupuesto = trabajo.presupuesto;
    if (presupuesto == null || presupuesto.tipo != TipoPresupuesto.porHoras) return false;
    if (presupuesto.estado != EstadoPresupuesto.aceptado) return false;
    if (trabajo.cierreHoras?.estado == EstadoPresupuesto.pendiente) return false;
    if (trabajo.ampliacion?.estado == EstadoPresupuesto.pendiente) return false;
    return true;
  }
}
