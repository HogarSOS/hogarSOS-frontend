import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/presupuesto_model.dart';
import '../../models/service_request_model.dart';
import '../../providers/chat_read_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/trabajos_vistos_provider.dart';
import '../../services/payment_service.dart';
import '../../services/service_request_service.dart';
import '../../utils/category_display.dart';
import '../../utils/error_extraction.dart';
import '../../utils/polling_lifecycle_mixin.dart';
import '../../widgets/animated_diff_list.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';
import '../profesional_shell_screen.dart' show profesionalTabIndexProvider;
import '../reportar_problema_screen.dart';
import '../cliente/valoracion_screen.dart';
import '../../utils/imagen_autenticada.dart';

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
class TrabajosActivosProfesionalScreen extends ConsumerStatefulWidget {
  const TrabajosActivosProfesionalScreen({super.key});

  @override
  ConsumerState<TrabajosActivosProfesionalScreen> createState() => _TrabajosActivosProfesionalScreenState();
}

class _TrabajosActivosProfesionalScreenState extends ConsumerState<TrabajosActivosProfesionalScreen>
    with WidgetsBindingObserver, PollingLifecycleMixin {
  @override
  void initState() {
    super.initState();
    // Mismo patrón de sondeo que home_profesional_screen.dart: un trabajo
    // cancelado por el cliente ya no aparece en listMyAssignedRequests
    // (filtro en el backend), pero sin refrescar esta lista periódicamente
    // el profesional solo se enteraría con un pull-to-refresh manual —
    // cada 10s se entera solo, sin spinner de por medio (el refresco es
    // silencioso, ver AssignedRequestsNotifier.cargar()). Se pausa solo
    // con la app en segundo plano (ver PollingLifecycleMixin).
    startPolling(const Duration(seconds: 10), () {
      ref.read(assignedRequestsProvider.notifier).cargar();
    });

    // Con solo entrar en esta pestaña se considera "visto" — no hace
    // falta abrir cada tarjeta suelta. Quita el punto rojo del shell
    // (ver profesional_shell_screen.dart y trabajos_vistos_provider.dart).
    // `listenManual` (en vez de `ref.listen` en build) porque desde
    // initState no hay build en curso al que enganchar el listener, y
    // así también cubre los datos que YA estuvieran cargados al entrar
    // (assignedRequestsProvider es compartido con el shell), no solo
    // los que lleguen después.
    void marcarVistosDe(List<AssignedRequest> trabajos) {
      // El set ANTES de marcar es lo que distingue "ya lo había visto"
      // de "me acabo de enterar" — sin esto, cada carga (incluida la
      // primera al entrar) contaría como "nuevo".
      final vistosAntes = ref.read(trabajosVistosProvider);
      final trabajosNuevos =
          trabajos.where((t) => t.estado == EstadoSolicitud.aceptada && !vistosAntes.contains(t.id)).toList();

      ref.read(trabajosVistosProvider.notifier).marcarVistos(
            trabajos.where((t) => t.estado == EstadoSolicitud.aceptada).map((t) => t.id),
          );

      if (trabajosNuevos.isEmpty) return;
      // Diferido al siguiente frame: en la primera llamada esto corre
      // dentro de initState, donde el ScaffoldMessenger todavía no
      // tiene garantizado un ancestro montado.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final t = AppLocalizations.of(context);
        for (final trabajo in trabajosNuevos) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.trabajosActivosTeEligieron(nombreLocalizadoCategoria(context, trabajo.categoria))),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: t.trabajosActivosVerTrabajo,
                // El propio shell mantiene todas las pestañas montadas
                // (IndexedStack) — este aviso puede dispararse estando
                // en otra pestaña, así que "ver trabajo" solo necesita
                // cambiar el índice activo, no navegar de verdad.
                onPressed: () => ref.read(profesionalTabIndexProvider.notifier).state = 2,
              ),
            ),
          );
        }
      });
    }

    final actuales = ref.read(assignedRequestsProvider).valueOrNull;
    if (actuales != null) marcarVistosDe(actuales);
    ref.listenManual(assignedRequestsProvider, (_, next) => next.whenData(marcarVistosDe));
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

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
          content: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
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
      ref.read(assignedRequestsProvider.notifier).cargar();

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
      ref.read(assignedRequestsProvider.notifier).cargar();
    } catch (e) {
      debugPrint('[TrabajosActivosProfesionalScreen] Error al completar: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.trabajosActivosCompletadoError, t: t))),
      );
    }
  }

  /// "Iniciar trabajo" — protección opcional del profesional frente a
  /// una cancelación instantánea del cliente (ver "Deshacer inicio" más
  /// abajo para el error). El diálogo de confirmación existe porque esto
  /// SÍ tiene una consecuencia real inmediata (el cliente deja de poder
  /// cancelar solo) — no es una acción neutra como abrir el chat.
  Future<void> _iniciar(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trabajosActivosIniciarTrabajoConfirmarTitulo),
        content: Text(t.trabajosActivosIniciarTrabajoConfirmarTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.trabajosActivosIniciarTrabajo),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    try {
      await ServiceRequestService().iniciarTrabajo(trabajo.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.trabajosActivosIniciarTrabajoExito)));
      ref.read(assignedRequestsProvider.notifier).cargar();
    } catch (e) {
      debugPrint('[TrabajosActivosProfesionalScreen] Error al iniciar trabajo: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.trabajosActivosIniciarTrabajoError, t: t))),
      );
      ref.read(assignedRequestsProvider.notifier).cargar();
    }
  }

  /// Deshace un "Iniciar trabajo" pulsado por error — nunca toca dinero,
  /// así que no hace falta ningún diálogo de confirmación (a diferencia
  /// de _iniciar arriba, esto solo le devuelve al cliente su cancelación
  /// instantánea, nunca perjudica a nadie).
  Future<void> _deshacerInicio(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    try {
      await ServiceRequestService().deshacerInicioTrabajo(trabajo.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.trabajosActivosDeshacerInicioExito)));
      ref.read(assignedRequestsProvider.notifier).cargar();
    } catch (e) {
      debugPrint('[TrabajosActivosProfesionalScreen] Error al deshacer inicio: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.trabajosActivosDeshacerInicioError, t: t))),
      );
      ref.read(assignedRequestsProvider.notifier).cargar();
    }
  }

  /// Diálogo para pedir más margen cuando el trabajo se complica más de
  /// lo previsto — nunca se cobra el exceso fuera de la app, hay que
  /// pasar por aquí y que el cliente lo acepte. Mismo patrón para las
  /// dos modalidades de presupuesto: "por_horas" pide horas
  /// adicionales, "cerrado" pide un importe adicional + motivo (ej.
  /// "+40€, hay que sustituir una válvula") — un único flujo, sin
  /// duplicar lógica entre los dos casos.
  Future<void> _pedirAmpliacion(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    final esCerrado = trabajo.presupuesto?.tipo == TipoPresupuesto.cerrado;
    final valorController = TextEditingController();
    final mensajeController = TextEditingController();

    // _procesando evita que un doble tap en "Confirmar" (o un segundo
    // tap mientras la petición anterior sigue en curso) dispare dos
    // llamadas a pedirAmpliacion — la garantía real de que nunca se
    // creen dos ampliaciones pendientes está en el backend (índice
    // único parcial, P2 #3), esto es solo UX, mismo patrón que
    // seguimiento_solicitud_screen.dart.
    var procesando = false;

    final pedido = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(esCerrado ? t.trabajosActivosAmpliarPresupuestoTitulo : t.trabajosActivosPedirAmpliacionTitulo),
          // Dos TextField apilados sin scroll era el diálogo con más
          // riesgo de overflow de teclado de toda la pantalla — mismo fix
          // que en home_profesional_screen.dart.
          content: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: valorController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: esCerrado
                        ? t.trabajosActivosAmpliarPresupuestoMontoHint
                        : t.trabajosActivosPedirAmpliacionHorasHint,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mensajeController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(hintText: t.trabajosActivosAmpliacionMotivoHint),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: procesando ? null : () => Navigator.of(context).pop(false),
              child: Text(t.perfilCancelar),
            ),
            FilledButton(
              onPressed: procesando
                  ? null
                  : () async {
                      final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
                      if (valor == null || valor <= 0) return;
                      setState(() => procesando = true);
                      try {
                        await ServiceRequestService().pedirAmpliacion(
                          trabajo.id,
                          horasAdicionales: esCerrado ? null : valor,
                          montoAdicional: esCerrado ? valor : null,
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
                      } finally {
                        if (context.mounted) setState(() => procesando = false);
                      }
                    },
              child: procesando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.trabajosActivosPrecioFinalConfirmar),
            ),
          ],
        ),
      ),
    );

    if (pedido == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.trabajosActivosPedirAmpliacionExito)));
      ref.read(assignedRequestsProvider.notifier).cargar();
    }
  }

  /// Diálogo para enviar un presupuesto — cerrado (monto fijo) o por
  /// horas (tarifa + horas estimadas). Mismo patrón de AlertDialog con
  /// StatefulBuilder que el resto de diálogos de esta pantalla, para
  /// poder alternar los campos visibles según el tipo elegido.
  Future<void> _enviarPresupuesto(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    var tipo = TipoPresupuesto.cerrado;
    var incluyeIva = false;
    final montoController = TextEditingController();
    final tarifaController = TextEditingController();
    final horasController = TextEditingController();
    final mensajeController = TextEditingController();
    // Evita que un doble tap en "Confirmar" dispare dos llamadas a
    // enviarPresupuesto — la garantía real de que nunca se creen dos
    // presupuestos pendientes está en el backend (índice único
    // parcial, P2 #3), esto es solo UX, mismo patrón que
    // seguimiento_solicitud_screen.dart.
    var procesando = false;

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
                // Justo debajo del importe/tarifa, no al final del
                // diálogo (UX pre-lanzamiento, 2026-08-14) — antes
                // quedaba por debajo del campo de mensaje, fuera de la
                // vista inicial del diálogo (con el teclado abierto,
                // solo visible haciendo scroll), así que era fácil
                // enviar un presupuesto sin fijarse en si incluía IVA
                // o no. El cálculo del importe no cambia: este checkbox
                // solo se guarda junto al presupuesto (incluyeIva), no
                // se usa para calcular monto/tarifaHora.
                CheckboxListTile(
                  value: incluyeIva,
                  onChanged: (valor) => setState(() => incluyeIva = valor ?? false),
                  title: Text(t.presupuestoDialogoIncluyeIva, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
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
          ),
          actions: [
            TextButton(
              onPressed: procesando ? null : () => Navigator.of(context).pop(false),
              child: Text(t.perfilCancelar),
            ),
            FilledButton(
              onPressed: procesando
                  ? null
                  : () async {
                      final mensaje = mensajeController.text.trim();
                      double? monto;
                      double? tarifa;
                      double? horas;
                      if (tipo == TipoPresupuesto.cerrado) {
                        monto = double.tryParse(montoController.text.replaceAll(',', '.'));
                        if (monto == null || monto <= 0) return;
                      } else {
                        tarifa = double.tryParse(tarifaController.text.replaceAll(',', '.'));
                        horas = double.tryParse(horasController.text.replaceAll(',', '.'));
                        if (tarifa == null || tarifa <= 0 || horas == null || horas <= 0) return;
                      }
                      setState(() => procesando = true);
                      try {
                        if (tipo == TipoPresupuesto.cerrado) {
                          await ServiceRequestService().enviarPresupuesto(
                            trabajo.id,
                            tipo: tipo,
                            monto: monto,
                            mensaje: mensaje,
                            incluyeIva: incluyeIva,
                          );
                        } else {
                          await ServiceRequestService().enviarPresupuesto(
                            trabajo.id,
                            tipo: tipo,
                            tarifaHora: tarifa,
                            horasEstimadas: horas,
                            mensaje: mensaje,
                            incluyeIva: incluyeIva,
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
                      } finally {
                        if (context.mounted) setState(() => procesando = false);
                      }
                    },
              child: procesando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.trabajosActivosPrecioFinalConfirmar),
            ),
          ],
        ),
      ),
    );

    if (enviado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.presupuestoEnviadoExito)));
      ref.read(assignedRequestsProvider.notifier).cargar();
    }
  }

  Future<void> _valorar(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ValoracionScreen(serviceRequestId: trabajo.id)),
    );
    if (resultado == true) ref.read(assignedRequestsProvider.notifier).cargar();
  }

  /// Solo aplica a trabajos ya completados — se oculta de esta lista sin
  /// borrar nada (pago/chat/valoraciones se conservan), el cliente lo
  /// sigue viendo en la suya hasta que también lo archive.
  Future<bool> _confirmarArchivar(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trabajosActivosArchivarTitulo),
        content: Text(t.trabajosActivosArchivarMensaje),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.perfilCancelar)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.trabajosActivosArchivarConfirmar),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _archivar(BuildContext context, WidgetRef ref, String id) async {
    final t = AppLocalizations.of(context);
    // Quita el trabajo de los datos ANTES de esperar la respuesta del
    // servidor: el swipe de Dismissible ya lo animó fuera de la vista, y
    // como el refresco ahora es silencioso (ya no pasa por loading() en
    // cada recarga, ver AssignedRequestsNotifier.cargar()), si los datos
    // tardaran en reflejarlo el mismo Dismissible con la misma key podría
    // volver a construirse ya "descartado" y Flutter lanzaría "A
    // dismissed Dismissible widget is still part of the tree".
    ref.read(assignedRequestsProvider.notifier).quitarLocal(id);
    try {
      await ServiceRequestService().archivar(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.trabajosActivosArchivarExito)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.trabajosActivosArchivarError, t: t))),
      );
      // El archivado falló de verdad (a diferencia del quitarLocal de
      // arriba, que es solo optimista) — recupera el estado real del
      // servidor, por si el trabajo debe volver a aparecer.
      ref.read(assignedRequestsProvider.notifier).cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final trabajosAsync = ref.watch(assignedRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.trabajosActivosTitulo)),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(assignedRequestsProvider.notifier).cargar(),
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
            // AnimatedFlatList en vez de un ListView.builder normal: el
            // provider ya no pasa por loading() en cada refresco
            // silencioso del polling de 10s (ver AssignedRequestsNotifier
            // .cargar()), así que aquí solo hace falta traducir
            // altas/bajas (ej. un trabajo cancelado por el cliente que
            // deja de venir del backend) en transiciones suaves.
            return AnimatedFlatList<AssignedRequest>(
              padding: const EdgeInsets.all(16),
              items: trabajos,
              idOf: (t) => t.id,
              itemBuilder: (context, trabajo, index) {
                final tarjeta = EntradaAnimada(
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
                    onIniciar: () => _iniciar(context, ref, trabajo),
                    onDeshacerInicio: () => _deshacerInicio(context, ref, trabajo),
                    onEnviarPresupuesto: () => _enviarPresupuesto(context, ref, trabajo),
                    onPedirAmpliacion: () => _pedirAmpliacion(context, ref, trabajo),
                    onValorar: () => _valorar(context, ref, trabajo),
                    onReportar: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportarProblemaScreen(serviceRequestId: trabajo.id),
                      ),
                    ),
                  ),
                );

                if (trabajo.estado != EstadoSolicitud.completada) {
                  return Padding(
                    key: ValueKey(trabajo.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: tarjeta,
                  );
                }

                return Padding(
                  key: ValueKey(trabajo.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey('archivar-${trabajo.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                    ),
                    confirmDismiss: (_) => _confirmarArchivar(context),
                    onDismissed: (_) => _archivar(context, ref, trabajo.id),
                    child: tarjeta,
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

/// Descripción visual de un estado: texto + colores + icono. Un único
/// sitio que decide "qué chip se ve" para toda la tarjeta, en vez de
/// repartir esa decisión entre varios widgets.
class _EstadoVisual {
  const _EstadoVisual(this.texto, this.icono, this.fondo, this.contenido);

  final String texto;
  final IconData icono;
  final Color fondo;
  final Color contenido;
}

/// Desglose "importe del trabajo · comisión · recibirás" que ve el
/// profesional — mismo distintivo de promoción que el cliente. Recibe
/// los importes ya calculados (no un `ComisionesInfo` en vivo) porque,
/// una vez hay una autorización de pago, esos importes están FIJADOS en
/// esa autorización y no deben recalcularse con el % vigente (puede
/// haber cambiado entre la aceptación y ahora — ver `payment.service.ts`).
class _DesgloseComisionProfesional extends StatelessWidget {
  const _DesgloseComisionProfesional({
    required this.montoBase,
    required this.comision,
    required this.recibiras,
    required this.esPromo,
  });

  final double montoBase;
  final double comision;
  final double recibiras;
  final bool esPromo;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPromo)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t.trabajosActivosPromoLanzamiento,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colorScheme.onTertiaryContainer),
              ),
            ),
          Text(
            t.trabajosActivosDesgloseComision(
              montoBase.toStringAsFixed(2),
              comision.toStringAsFixed(2),
              recibiras.toStringAsFixed(2),
            ),
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TarjetaTrabajo extends ConsumerWidget {
  const _TarjetaTrabajo({
    required this.trabajo,
    required this.noLeido,
    required this.onChat,
    required this.onCompletar,
    required this.onIniciar,
    required this.onDeshacerInicio,
    required this.onEnviarPresupuesto,
    required this.onPedirAmpliacion,
    required this.onValorar,
    required this.onReportar,
  });

  final AssignedRequest trabajo;
  final bool noLeido;
  final VoidCallback onChat;
  final VoidCallback onCompletar;
  final VoidCallback onIniciar;
  final VoidCallback onDeshacerInicio;
  final VoidCallback onEnviarPresupuesto;
  final VoidCallback onPedirAmpliacion;
  final VoidCallback onValorar;
  final VoidCallback onReportar;

  static const _tamanoIconoAccion = 17.0;
  static const _anchoBotonChat = 92.0;

  bool get _completado => trabajo.estado == EstadoSolicitud.completada;

  /// Un único chip de estado, con prioridad de lo más urgente/reciente
  /// a lo más asentado — evita mezclar varias señales a la vez en la
  /// misma tarjeta.
  _EstadoVisual _estadoVisual(BuildContext context) {
    final t = AppLocalizations.of(context);
    final presupuesto = trabajo.presupuesto;

    if (trabajo.cierreHoras?.estado == EstadoPresupuesto.pendiente) {
      return _EstadoVisual(t.trabajosActivosEstadoCierrePendiente, Icons.verified_user_outlined, Colors.blue.shade50, Colors.blue.shade800);
    }
    if (trabajo.ampliacion?.estado == EstadoPresupuesto.pendiente) {
      return _EstadoVisual(t.trabajosActivosEstadoAmpliacionPendiente, Icons.hourglass_top, Colors.orange.shade50, Colors.orange.shade800);
    }
    if (_completado && trabajo.payment?.estado == 'liberado') {
      return _EstadoVisual(t.trabajosActivosEstadoPagoLiberado, Icons.account_balance_wallet_outlined, Colors.green.shade100, Colors.green.shade900);
    }
    if (_completado) {
      return _EstadoVisual(t.seguimientoCompletada, Icons.task_alt, Colors.green.shade50, Colors.green.shade800);
    }
    if (presupuesto == null || presupuesto.estado == EstadoPresupuesto.rechazado) {
      final colorScheme = Theme.of(context).colorScheme;
      return _EstadoVisual(t.trabajosActivosEstadoSinPresupuesto, Icons.request_quote_outlined, colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant);
    }
    if (presupuesto.estado == EstadoPresupuesto.pendiente) {
      return _EstadoVisual(t.trabajosActivosEstadoPresupuestoPendiente, Icons.hourglass_top, Colors.amber.shade50, Colors.amber.shade900);
    }
    // Mismo color (tertiary) que usa _EstadoBanner en la pantalla del
    // cliente para este mismo estado — mismo lenguaje visual en las dos
    // apps para "en curso".
    if (trabajo.estado == EstadoSolicitud.en_progreso) {
      final colorScheme = Theme.of(context).colorScheme;
      return _EstadoVisual(t.trabajosActivosEstadoEnCurso, Icons.construction_outlined, colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer);
    }
    return _EstadoVisual(t.trabajosActivosEstadoPresupuestoAceptado, Icons.task_alt, Colors.green.shade50, Colors.green.shade800);
  }

  /// Construye el desglose a mostrar, si aplica: prioriza los importes ya
  /// FIJADOS en el `Payment` (retenido o liberado — nunca se recalculan
  /// con el % vigente, ver `_DesgloseComisionProfesional`); solo antes de
  /// que exista una autorización usa los porcentajes en vivo sobre el
  /// presupuesto/ampliación aceptado, vía [comisiones].
  Widget? _desglose(AsyncValue<ComisionesInfo> comisiones) {
    final payment = trabajo.payment;
    if (payment != null) {
      // `comisionPlataforma` del Payment es lo que se queda la
      // plataforma EN TOTAL, e incluye la parte que paga el CLIENTE por
      // encima del presupuesto. Al profesional no se le puede enseñar
      // esa cifra: él solo "paga" la diferencia entre lo que cotizó y lo
      // que recibe. Con la comisión vigente (5% cliente / 0%
      // profesional) mostrar comisionPlataforma daba un desglose
      // absurdo — "Importe 100 € · Gastos de gestión 5 € · Recibirás
      // 100 €" — cobrándole visualmente algo que no paga. Mientras
      // ambos porcentajes fueron iguales (o ambos 0) el error no se
      // notaba; aparece justo al aplicar 5%/0%.
      final comisionDelProfesional = payment.montoBase - payment.montoProfesional;
      return _DesgloseComisionProfesional(
        montoBase: payment.montoBase,
        comision: comisionDelProfesional,
        recibiras: payment.montoProfesional,
        esPromo: comisionDelProfesional == 0,
      );
    }

    final presupuesto = trabajo.presupuesto;
    if (presupuesto == null || presupuesto.estado != EstadoPresupuesto.aceptado) return null;

    return comisiones.when(
      data: (info) => _DesgloseComisionProfesional(
        montoBase: presupuesto.importeTotal,
        comision: presupuesto.importeTotal - info.totalProfesional(presupuesto.importeTotal),
        recibiras: info.totalProfesional(presupuesto.importeTotal),
        // Mismo criterio que arriba: al profesional le importa SU
        // porcentaje, no que ambos sean 0. `esPromoLanzamiento` (los dos
        // a cero) haría desaparecer el distintivo de "no pagas comisión"
        // en cuanto el cliente pase a 5% aunque el profesional siga a 0%.
        esPromo: info.comisionProfesionalPorcentaje == 0,
      ),
      loading: () => null,
      error: (_, __) => null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final estado = _estadoVisual(context);
    final desglose = _desglose(ref.watch(comisionesProvider));

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Cabecera: quién y qué, con el chip de estado siempre visible ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: trabajo.clienteFotoUrl != null
                      ? imagenDeRed(trabajo.clienteFotoUrl!, maxWidth: 120, maxHeight: 120)
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
                      Text(
                        trabajo.clienteNombre,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        nombreLocalizadoCategoria(context, trabajo.categoria),
                        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ChipEstado(estado: estado),
              ],
            ),
            if (desglose != null) desglose,
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
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 14),

            // --- Acciones: Chat con ancho fijo (no compite por espacio),
            // la acción principal se lleva el resto — así nunca se parte. ---
            if (_completado)
              Row(
                children: [
                  SizedBox(width: _anchoBotonChat, child: _botonChat(t)),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : _botonAccion(
                            icon: Icons.star_outline,
                            label: t.seguimientoValorar,
                            onPressed: onValorar,
                            relleno: true,
                          ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  SizedBox(width: _anchoBotonChat, child: _botonChat(t)),
                  const SizedBox(width: 8),
                  Expanded(child: _botonSegunPresupuesto(t, colorScheme)),
                ],
              ),
              // "Iniciar trabajo" / "Deshacer inicio": protección opcional
              // frente a la cancelación instantánea del cliente — nunca
              // sustituye a "Marcar como completado" de arriba, que sigue
              // funcionando igual con o sin pasar por aquí primero.
              if (trabajo.estado == EstadoSolicitud.aceptada &&
                  trabajo.presupuesto?.estado == EstadoPresupuesto.aceptado) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: _botonAccion(
                    icon: Icons.play_circle_outline,
                    label: t.trabajosActivosIniciarTrabajo,
                    onPressed: onIniciar,
                    relleno: false,
                  ),
                ),
              ] else if (trabajo.estado == EstadoSolicitud.en_progreso) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.undo, size: 16, color: colorScheme.onSurfaceVariant),
                    label: Text(
                      t.trabajosActivosDeshacerInicio,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12.5),
                    ),
                    onPressed: onDeshacerInicio,
                  ),
                ),
              ],
              if (_mostrarBotonAmpliacion) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: _botonAccion(
                    icon: Icons.add_circle_outline,
                    label: trabajo.presupuesto?.tipo == TipoPresupuesto.cerrado
                        ? t.trabajosActivosAmpliarPresupuesto
                        : t.trabajosActivosPedirAmpliacion,
                    onPressed: onPedirAmpliacion,
                    relleno: false,
                  ),
                ),
              ] else if (trabajo.ampliacion?.estado == EstadoPresupuesto.pendiente) ...[
                const SizedBox(height: 8),
                _chipEspera(colorScheme, Icons.hourglass_top, t.trabajosActivosAmpliacionEsperando),
              ],
            ],
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.report_problem_outlined, size: 16, color: colorScheme.error),
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

  Widget _botonChat(AppLocalizations t) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onChat,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(isLabelVisible: noLeido, child: const Icon(Icons.chat_bubble_outline, size: _tamanoIconoAccion)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              t.trabajosActivosChat,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Botón compacto que nunca parte el texto en varias líneas — icono
  /// pequeño + label a tamaño reducido + padding ajustado, en vez de
  /// depender del padding/tamaño por defecto de FilledButton.icon.
  Widget _botonAccion({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool relleno,
  }) {
    final contenido = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _tamanoIconoAccion),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
    final estilo = ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
      visualDensity: VisualDensity.compact,
    );
    return relleno
        ? FilledButton(style: estilo, onPressed: onPressed, child: contenido)
        : OutlinedButton(style: estilo, onPressed: onPressed, child: contenido);
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
      return _botonAccion(
        icon: Icons.request_quote,
        label: t.trabajosActivosEnviarPresupuesto,
        onPressed: onEnviarPresupuesto,
        relleno: true,
      );
    }
    if (presupuesto.estado == EstadoPresupuesto.pendiente) {
      return _chipEspera(colorScheme, Icons.hourglass_top, t.trabajosActivosPresupuestoEsperando);
    }
    if (trabajo.cierreHoras?.estado == EstadoPresupuesto.pendiente) {
      return _chipEspera(colorScheme, Icons.verified_user_outlined, t.trabajosActivosCierreEsperando);
    }
    return _botonAccion(
      icon: Icons.task_alt,
      label: t.trabajosActivosCompletar,
      onPressed: onCompletar,
      relleno: true,
    );
  }

  Widget _chipEspera(ColorScheme colorScheme, IconData icono, String texto) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// El botón de ampliación (horas o importe, según el tipo) solo tiene
  /// sentido con un presupuesto ya aceptado, sin una ampliación ya
  /// pendiente de respuesta, y sin un cierre de horas ya en curso (no
  /// tiene sentido pedir más margen si ya se está cerrando el trabajo).
  bool get _mostrarBotonAmpliacion {
    final presupuesto = trabajo.presupuesto;
    if (presupuesto == null) return false;
    if (presupuesto.estado != EstadoPresupuesto.aceptado) return false;
    if (trabajo.cierreHoras?.estado == EstadoPresupuesto.pendiente) return false;
    if (trabajo.ampliacion?.estado == EstadoPresupuesto.pendiente) return false;
    return true;
  }
}

/// Chip de estado compacto, con color propio por estado (ver
/// _EstadoVisual) — el mismo lenguaje visual en todas las tarjetas.
class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});

  final _EstadoVisual estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 130 se quedaba corto para estados en inglés más largos que su
      // versión en español (p.ej. "Confirmation pending" vs
      // "Confirmación pendiente" truncaba de más pese al maxLines:1 +
      // ellipsis de abajo, que ya evita el overflow pero no evita
      // perder texto innecesariamente).
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: estado.fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estado.icono, size: 13, color: estado.contenido),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              estado.texto,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: estado.contenido),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
