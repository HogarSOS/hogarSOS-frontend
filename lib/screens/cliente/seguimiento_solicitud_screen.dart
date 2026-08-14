import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/presupuesto_model.dart';
import '../../models/service_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../services/payment_service.dart';
import '../../services/service_request_service.dart';
import '../../utils/category_display.dart';
import '../../utils/error_extraction.dart';
import '../../utils/polling_lifecycle_mixin.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';
import '../reportar_problema_screen.dart';
import 'pago_screen.dart';
import 'seleccionar_profesional_screen.dart';
import 'valoracion_screen.dart';

/// Pantalla central del ciclo de vida de una solicitud. Se navega aquí
/// justo después de crear una solicitud (ver home_cliente_screen.dart)
/// y también desde "Mis solicitudes". Sondea el estado cada 5s mientras
/// esté pendiente/aceptada — no hay push notifications todavía, así que
/// el sondeo es la forma más simple de detectar cuándo un profesional
/// acepta, sin añadir infraestructura nueva.
class SeguimientoSolicitudScreen extends ConsumerStatefulWidget {
  const SeguimientoSolicitudScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  ConsumerState<SeguimientoSolicitudScreen> createState() => _SeguimientoSolicitudScreenState();
}

class _SeguimientoSolicitudScreenState extends ConsumerState<SeguimientoSolicitudScreen>
    with WidgetsBindingObserver, PollingLifecycleMixin {
  final _servicio = ServiceRequestService();
  ServiceRequestModel? _solicitud;
  String? _error;

  static const _estadosActivos = {EstadoSolicitud.pendiente, EstadoSolicitud.aceptada, EstadoSolicitud.en_progreso};

  @override
  void initState() {
    super.initState();
    _cargar();
    // Se pausa solo con la app en segundo plano (ver PollingLifecycleMixin).
    startPolling(const Duration(seconds: 5), () => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    try {
      final solicitud = await _servicio.obtenerPorId(widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _solicitud = solicitud;
        _error = null;
      });
      // Ya no hace falta seguir sondeando si la solicitud llegó a un
      // estado final — ahorra peticiones de por vida de la pantalla.
      if (!_estadosActivos.contains(solicitud.estado)) {
        stopPolling();
      }
    } catch (e) {
      if (!mounted || silencioso) return; // en el sondeo de fondo, un fallo puntual no debe mostrar error
      setState(() => _error = 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.seguimientoTitulo)),
      body: _solicitud == null
          ? (_error != null
              ? Center(child: Text(t.seguimientoError))
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: () => _cargar(),
              child: _Contenido(solicitud: _solicitud!, onRecargar: _cargar),
            ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.solicitud, required this.onRecargar});

  final ServiceRequestModel solicitud;
  final Future<void> Function({bool silencioso}) onRecargar;

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.seguimientoCancelarTitulo),
        content: Text(t.seguimientoCancelarConfirmar),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.seguimientoCancelarTitulo),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    try {
      await ServiceRequestService().cancelar(solicitud.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.seguimientoCancelarExito)),
      );
      onRecargar();
      // Sin esto, el banner "Tienes N solicitudes activas" de Inicio se
      // quedaba con el conteo de antes de cancelar — ese provider vive
      // cacheado mientras Inicio siga montado (IndexedStack no lo
      // destruye nunca al cambiar de pestaña), así que nada lo refresca
      // si no se invalida explícitamente desde aquí.
      ref.invalidate(resumenActividadClienteProvider);
    } catch (e) {
      debugPrint('[SeguimientoSolicitudScreen] Error al cancelar: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.seguimientoCancelarError, t: t))),
      );
      onRecargar(); // por si el motivo es que ya no está pendiente (otro la aceptó justo ahora)
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final usuarioId = ref.watch(authProvider).usuario?.id ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        EntradaAnimada(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorParaCategoria(solicitud.categoria).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconoParaCategoria(solicitud.categoria), color: colorParaCategoria(solicitud.categoria)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreLocalizadoCategoria(context, solicitud.categoria),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      solicitud.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (solicitud.estado != EstadoSolicitud.cancelada && solicitud.estado != EstadoSolicitud.disputada) ...[
          EntradaAnimada(retraso: const Duration(milliseconds: 80), child: _LineaProgreso(estado: solicitud.estado)),
          const SizedBox(height: 20),
        ],
        EntradaAnimada(retraso: const Duration(milliseconds: 120), child: _EstadoBanner(estado: solicitud.estado)),
        const SizedBox(height: 24),

        // Solo mientras sigue "pendiente" tiene sentido elegir — en
        // cuanto hay alguien asignado ya no hay nada que comparar.
        if (solicitud.estado == EstadoSolicitud.pendiente && solicitud.numCandidatos > 0) ...[
          FilledButton.icon(
            icon: const Icon(Icons.people_outline),
            label: Text(t.seguimientoVerCandidatos(solicitud.numCandidatos)),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeleccionarProfesionalScreen(serviceRequestId: solicitud.id),
                ),
              );
              onRecargar();
            },
          ),
          const SizedBox(height: 12),
        ],

        // También se puede cancelar ya "aceptada" (antes solo mientras
        // "pendiente") — si la disponibilidad que propuso el
        // profesional al aceptar (ver home_profesional_screen.dart) no
        // le sirve al cliente, necesita una forma real de decir que no.
        // Deja de poder cancelarse en cuanto pasa a "en_progreso": ahí
        // ya se considera que el trabajo empezó de verdad.
        if (solicitud.estado == EstadoSolicitud.pendiente || solicitud.estado == EstadoSolicitud.aceptada) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label: Text(t.seguimientoCancelarTitulo),
            style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () => _cancelar(context, ref),
          ),
          const SizedBox(height: 24),
        ],

        if (solicitud.estado == EstadoSolicitud.aceptada || solicitud.estado == EstadoSolicitud.en_progreso) ...[
          FilledButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(t.seguimientoAbrirChat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    serviceRequestId: solicitud.id,
                    nombreContraparte: solicitud.profesionalNombre,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          if (solicitud.cierreHoras?.estado == EstadoPresupuesto.pendiente)
            _CierreHorasPendienteCard(
              serviceRequestId: solicitud.id,
              cierreHoras: solicitud.cierreHoras!,
              tarifaHora: solicitud.presupuesto?.tarifaHora,
              horasEstimadas: solicitud.presupuesto?.horasEstimadas,
              onRespondido: onRecargar,
            )
          else if (solicitud.ampliacion?.estado == EstadoPresupuesto.pendiente)
            _AmpliacionPendienteCard(
              serviceRequestId: solicitud.id,
              ampliacion: solicitud.ampliacion!,
              tarifaHora: solicitud.presupuesto?.tarifaHora,
              onRespondido: onRecargar,
            )
          else if (solicitud.pagoPendienteDeAutorizar)
            OutlinedButton.icon(
              icon: const Icon(Icons.payment_outlined),
              label: Text(t.seguimientoAutorizarPago),
              onPressed: () async {
                final resultado = await Navigator.of(context).push<PaymentIntentResult>(
                  MaterialPageRoute(builder: (_) => PagoScreen(serviceRequestId: solicitud.id)),
                );
                if (resultado == null) return;
                onRecargar();
                // Se muestra aquí (no en PagoScreen) porque este
                // contexto sigue vivo tras el pop — ver el comentario en
                // pago_screen.dart._pagar().
                if (!context.mounted) return;
                final comision = resultado.montoTotal - resultado.montoBase;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${t.pagoExito}\n${t.seguimientoDesgloseComision(
                        resultado.montoBase.toStringAsFixed(2),
                        comision.toStringAsFixed(2),
                        resultado.montoTotal.toStringAsFixed(2),
                      )}',
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
            )
          else if (solicitud.payment != null)
            _EstadoPagoChip(payment: solicitud.payment!)
          else if (solicitud.presupuesto == null)
            _EsperandoPresupuesto(texto: t.seguimientoEsperandoPresupuesto)
          else if (solicitud.presupuesto!.estado == EstadoPresupuesto.pendiente)
            _PresupuestoPendienteCard(
              serviceRequestId: solicitud.id,
              presupuesto: solicitud.presupuesto!,
              onRespondido: onRecargar,
            )
          else if (solicitud.presupuesto!.estado == EstadoPresupuesto.rechazado)
            _EsperandoPresupuesto(texto: t.seguimientoPresupuestoRechazadoInfo),
        ],

        if (solicitud.estado == EstadoSolicitud.completada) ...[
          Builder(builder: (context) {
            final miValoracion = solicitud.miValoracion(usuarioId);
            if (miValoracion == null) {
              return FilledButton.icon(
                icon: const Icon(Icons.star_outline),
                label: Text(t.seguimientoValorar),
                onPressed: () async {
                  final resultado = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => ValoracionScreen(serviceRequestId: solicitud.id)),
                  );
                  if (resultado == true) onRecargar();
                },
              );
            }
            return Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < miValoracion.puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(t.seguimientoYaValorado),
              ],
            );
          }),
        ],

        // Disponible en cualquier estado a partir de "aceptada" — una
        // vez hay profesional asignado puede haber algo que reportar
        // (no se presentó, comportamiento, pago...), no solo tras
        // completar. No se muestra en "disputada" porque ese estado YA
        // es la reclamación abierta (ver _EstadoBanner).
        if (solicitud.estado == EstadoSolicitud.aceptada ||
            solicitud.estado == EstadoSolicitud.en_progreso ||
            solicitud.estado == EstadoSolicitud.completada) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            label: Text(t.reportarProblemaBoton),
            style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () async {
              final resultado = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => ReportarProblemaScreen(serviceRequestId: solicitud.id)),
              );
              if (resultado == true) onRecargar();
            },
          ),
        ],
      ],
    );
  }
}

class _EstadoBanner extends StatelessWidget {
  const _EstadoBanner({required this.estado});

  final EstadoSolicitud estado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final (icono, texto, color) = switch (estado) {
      EstadoSolicitud.pendiente => (Icons.search, t.seguimientoBuscando, colorScheme.primary),
      EstadoSolicitud.aceptada => (Icons.handshake_outlined, t.seguimientoAceptada, colorScheme.tertiary),
      EstadoSolicitud.en_progreso => (Icons.construction_outlined, t.seguimientoEnProgreso, colorScheme.tertiary),
      EstadoSolicitud.completada => (Icons.check_circle_outline, t.seguimientoCompletada, Colors.green),
      EstadoSolicitud.cancelada => (Icons.cancel_outlined, t.seguimientoCancelada, colorScheme.error),
      EstadoSolicitud.disputada => (Icons.gavel_outlined, t.seguimientoDisputada, colorScheme.error),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (estado == EstadoSolicitud.pendiente)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            )
          else
            Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Texto informativo simple, sin acción — usado tanto para "todavía no
/// hay presupuesto" como para "rechazaste el anterior, esperando uno
/// nuevo del profesional".
class _EsperandoPresupuesto extends StatelessWidget {
  const _EsperandoPresupuesto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con el presupuesto pendiente de respuesta — muestra el
/// importe según el tipo (monto fijo, o tarifa × horas estimadas con
/// el techo que se autorizará) y los botones aceptar/rechazar.
/// Desglose "Presupuesto / Gastos de gestión / Total" que ve el cliente
/// antes de aceptar un presupuesto/ampliación/cierre de horas —
/// transparencia total, nada de sorpresas al pagar. "Gastos de gestión"
/// es el término oficial y único de Hogar SOS para esta comisión — no
/// usar ningún otro nombre ("tarifa de servicio", "comisión de
/// servicio"...) en ningún otro sitio de la app. Si la comisión vigente
/// es 0% para ambas partes, se muestra además el distintivo de
/// promoción (derivado en tiempo real de los porcentajes, no de una
/// fecha).
class _DesgloseComision extends StatelessWidget {
  const _DesgloseComision({required this.montoBase, required this.comisiones, this.incluyeIva});

  final double montoBase;
  final ComisionesInfo comisiones;
  // null = no aplica a este importe (ampliación/cierre de horas, que no
  // llevan su propia declaración de IVA); true/false = lo que declaró
  // el profesional al enviar el presupuesto original.
  final bool? incluyeIva;

  void _mostrarInfoGastosGestion(BuildContext context, AppLocalizations t) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.desglosePagoGastosGestionLabel),
        content: Text(t.desglosePagoGastosGestionInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.perfilCancelar),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final total = comisiones.totalCliente(montoBase);
    final comision = total - montoBase;

    TextStyle estiloEtiqueta({bool destacado = false}) => TextStyle(
          fontSize: destacado ? 13.5 : 12.5,
          fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
          color: destacado ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        );

    Widget filaImporte(String etiqueta, double importe, {bool destacado = false, Widget? extra}) {
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(etiqueta, style: estiloEtiqueta(destacado: destacado)),
                if (extra != null) extra,
              ],
            ),
            Text('${importe.toStringAsFixed(2)} €', style: estiloEtiqueta(destacado: destacado)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comisiones.esPromoLanzamiento)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t.seguimientoPromoLanzamiento,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colorScheme.onTertiaryContainer),
              ),
            ),
          filaImporte(t.desglosePagoPresupuestoLabel, montoBase),
          filaImporte(
            t.desglosePagoGastosGestionLabel,
            comision,
            extra: GestureDetector(
              onTap: () => _mostrarInfoGastosGestion(context, t),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 4), child: Divider(height: 1)),
          filaImporte(t.desglosePagoTotalLabel, total, destacado: true),
          if (incluyeIva != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                incluyeIva! ? t.desglosePagoIvaIncluido : t.desglosePagoIvaNoIncluido,
                style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresupuestoPendienteCard extends ConsumerWidget {
  const _PresupuestoPendienteCard({
    required this.serviceRequestId,
    required this.presupuesto,
    required this.onRespondido,
  });

  final String serviceRequestId;
  final PresupuestoInfo presupuesto;
  final Future<void> Function({bool silencioso}) onRespondido;

  Future<void> _responder(BuildContext context, bool aceptar) async {
    final t = AppLocalizations.of(context);

    if (!aceptar) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.seguimientoPresupuestoRechazar),
          content: Text(t.seguimientoPresupuestoRechazarConfirmar),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.perfilCancelar),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.seguimientoPresupuestoRechazar),
            ),
          ],
        ),
      );
      if (confirmado != true || !context.mounted) return;
    }

    try {
      await ServiceRequestService().responderPresupuesto(serviceRequestId, presupuesto.id, aceptar: aceptar);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aceptar ? t.seguimientoPresupuestoAceptadoExito : t.seguimientoPresupuestoRechazadoExito)),
      );
      onRespondido();
    } catch (e) {
      debugPrint('[SeguimientoSolicitudScreen] Error al responder presupuesto: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.seguimientoPresupuestoError, t: t))),
      );
      onRespondido();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final esPorHoras = presupuesto.tipo == TipoPresupuesto.porHoras;
    final comisiones = ref.watch(comisionesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.seguimientoPresupuestoTitulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 8),
          Text(
            esPorHoras
                ? t.seguimientoPresupuestoPorHorasDetalle(
                    presupuesto.tarifaHora!.toStringAsFixed(2),
                    presupuesto.horasEstimadas!.toStringAsFixed(1),
                    presupuesto.importeTotal.toStringAsFixed(2),
                  )
                : t.seguimientoPresupuestoCerradoDetalle(presupuesto.monto!.toStringAsFixed(2)),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          comisiones.when(
            data: (info) => _DesgloseComision(
              montoBase: presupuesto.importeTotal,
              comisiones: info,
              incluyeIva: presupuesto.incluyeIva,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (presupuesto.mensaje != null && presupuesto.mensaje!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${presupuesto.mensaje}"',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                  onPressed: () => _responder(context, false),
                  child: Text(t.seguimientoPresupuestoRechazar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _responder(context, true),
                  child: Text(t.seguimientoPresupuestoAceptar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con una ampliación de horas pendiente de respuesta — el
/// profesional pide más tiempo del estimado, el cliente acepta (se
/// autorizará el importe adicional en un paso aparte, ver
/// `pagoPendienteDeAutorizar`) o rechaza (el trabajo sigue igual).
class _AmpliacionPendienteCard extends ConsumerWidget {
  const _AmpliacionPendienteCard({
    required this.serviceRequestId,
    required this.ampliacion,
    required this.tarifaHora,
    required this.onRespondido,
  });

  final String serviceRequestId;
  final AmpliacionInfo ampliacion;
  final double? tarifaHora;
  final Future<void> Function({bool silencioso}) onRespondido;

  Future<void> _responder(BuildContext context, bool aceptar) async {
    final t = AppLocalizations.of(context);
    try {
      await ServiceRequestService().responderAmpliacion(serviceRequestId, ampliacion.id, aceptar: aceptar);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aceptar ? t.seguimientoAmpliacionAceptadaExito : t.seguimientoAmpliacionRechazadaExito)),
      );
      onRespondido();
    } catch (e) {
      debugPrint('[SeguimientoSolicitudScreen] Error al responder ampliación: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.seguimientoAmpliacionError, t: t))),
      );
      onRespondido();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final importeAdicional = ampliacion.importeAdicional(tarifaHora);
    final comisiones = ref.watch(comisionesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ampliacion.esPorHoras ? t.seguimientoAmpliacionTitulo : t.seguimientoAmpliacionTituloMonto,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          Text(
            ampliacion.esPorHoras
                ? t.seguimientoAmpliacionDetalle(
                    ampliacion.horasAdicionales!.toStringAsFixed(1),
                    importeAdicional.toStringAsFixed(2),
                  )
                : t.seguimientoAmpliacionMontoDetalle(importeAdicional.toStringAsFixed(2)),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          comisiones.when(
            data: (info) => _DesgloseComision(montoBase: importeAdicional, comisiones: info),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (ampliacion.mensaje != null && ampliacion.mensaje!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${ampliacion.mensaje}"',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                  onPressed: () => _responder(context, false),
                  child: Text(t.seguimientoPresupuestoRechazar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _responder(context, true),
                  child: Text(t.seguimientoPresupuestoAceptar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con las horas declaradas por el profesional al terminar un
/// trabajo "por_horas" — el cliente las confirma (eso libera el pago)
/// o, si no está de acuerdo, abre una reclamación (no hay
/// renegociación automática, se resuelve por chat o soporte).
class _CierreHorasPendienteCard extends ConsumerWidget {
  const _CierreHorasPendienteCard({
    required this.serviceRequestId,
    required this.cierreHoras,
    required this.tarifaHora,
    required this.horasEstimadas,
    required this.onRespondido,
  });

  final String serviceRequestId;
  final CierreHorasInfo cierreHoras;
  final double? tarifaHora;
  final double? horasEstimadas;
  final Future<void> Function({bool silencioso}) onRespondido;

  Future<void> _confirmar(BuildContext context, {bool confirmarReduccionGrande = false}) async {
    final t = AppLocalizations.of(context);
    try {
      await ServiceRequestService().responderCierreHoras(
        serviceRequestId,
        cierreHoras.id,
        aceptar: true,
        confirmarReduccionGrande: confirmarReduccionGrande,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.seguimientoCierreHorasConfirmadoExito)));
      onRespondido();
    } catch (e) {
      debugPrint('[SeguimientoSolicitudScreen] Error al confirmar horas: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.seguimientoCierreHorasError, t: t))),
      );
      onRespondido();
    }
  }

  /// La reducción anómala (auditoría 2026-08-14, protección
  /// anti-evasión) nunca se acepta con un solo toque: se le pide al
  /// cliente que confirme explícitamente viendo la comparación otra
  /// vez, en un diálogo aparte del botón "Confirmar" de la tarjeta —
  /// así una pulsación accidental o distraída no libera un pago muy
  /// por debajo de lo estimado.
  Future<void> _confirmarConAviso(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final estimadas = horasEstimadas;
    final porcentaje = cierreHoras.porcentaje;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.seguimientoCierreHorasDialogoTitulo),
        content: Text(
          t.seguimientoCierreHorasDialogoDetalle(
            cierreHoras.horasReales.toStringAsFixed(1),
            estimadas?.toStringAsFixed(1) ?? '—',
            porcentaje != null ? '$porcentaje%' : '—',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(t.seguimientoCierreHorasDialogoCancelar)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(t.seguimientoCierreHorasDialogoConfirmar)),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      await _confirmar(context, confirmarReduccionGrande: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final importeFinal = (tarifaHora ?? 0) * cierreHoras.horasReales;
    final comisiones = ref.watch(comisionesProvider);
    final esAnomala = cierreHoras.reduccionAnomala;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.seguimientoCierreHorasTitulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 10),
          // Comparación completa ANTES de aceptar (auditoría
          // 2026-08-14) — antes solo se veían las horas declaradas y
          // el importe, sin nada al lado con lo que compararlas.
          if (horasEstimadas != null)
            _FilaCierreHoras(etiqueta: t.seguimientoCierreHorasLabelEstimadas, valor: '${horasEstimadas!.toStringAsFixed(1)} h'),
          _FilaCierreHoras(etiqueta: t.seguimientoCierreHorasLabelReales, valor: '${cierreHoras.horasReales.toStringAsFixed(1)} h'),
          if (tarifaHora != null)
            _FilaCierreHoras(etiqueta: t.seguimientoCierreHorasLabelTarifa, valor: '${tarifaHora!.toStringAsFixed(2)} €/h'),
          _FilaCierreHoras(etiqueta: t.seguimientoCierreHorasLabelImporte, valor: '${importeFinal.toStringAsFixed(2)} €', destacado: true),
          if (esAnomala) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.seguimientoCierreHorasAvisoReduccion(cierreHoras.porcentaje != null ? '${cierreHoras.porcentaje}' : '—'),
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          comisiones.when(
            data: (info) => _DesgloseComision(montoBase: importeFinal, comisiones: info),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                  onPressed: () async {
                    final resultado = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => ReportarProblemaScreen(serviceRequestId: serviceRequestId)),
                    );
                    if (resultado == true) onRespondido();
                  },
                  child: Text(t.seguimientoCierreHorasReclamar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => esAnomala ? _confirmarConAviso(context) : _confirmar(context),
                  child: Text(t.seguimientoCierreHorasConfirmar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaCierreHoras extends StatelessWidget {
  const _FilaCierreHoras({required this.etiqueta, required this.valor, this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(
            valor,
            style: TextStyle(fontSize: destacado ? 14.5 : 13, fontWeight: destacado ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EstadoPagoChip extends StatelessWidget {
  const _EstadoPagoChip({required this.payment});

  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = switch (payment.estado) {
      'retenido' => t.seguimientoPagoRetenido,
      'liberado' => t.seguimientoPagoLiberado,
      'reembolsado' => t.seguimientoPagoReembolsado,
      _ => t.seguimientoPagoFallido,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
          Text(
            t.montoConSimbolo(payment.montoTotal.toStringAsFixed(2)),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Línea de progreso de 3 etapas reales (no se inventa un estado
/// intermedio de "respuestas recibidas" que no existe en los datos —
/// ver nota al usuario sobre esta decisión).
class _LineaProgreso extends StatelessWidget {
  const _LineaProgreso({required this.estado});

  final EstadoSolicitud estado;

  int get _etapaActual => switch (estado) {
        EstadoSolicitud.pendiente => 0,
        EstadoSolicitud.aceptada || EstadoSolicitud.en_progreso => 1,
        EstadoSolicitud.completada => 2,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final etiquetas = [t.progresoBuscando, t.progresoSeleccionado, t.progresoFinalizado];

    return Row(
      children: List.generate(etiquetas.length * 2 - 1, (i) {
        if (i.isOdd) {
          final indiceLinea = i ~/ 2;
          final completada = indiceLinea < _etapaActual;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: completada ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            ),
          );
        }
        final indice = i ~/ 2;
        final activo = indice <= _etapaActual;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                indice < _etapaActual ? Icons.check : Icons.circle,
                size: indice < _etapaActual ? 16 : 8,
                color: activo ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              // maxLines: 2 en vez de 1: a 70px/10.5px ya cabía en 1
              // línea en español, pero etiquetas en inglés como
              // "Confirmation pending" no caben — sin límite, Flutter
              // ya envuelve solo, así que basta con acotarlo a 2 líneas
              // y recortar con "…" si ni así cupiera, en vez de dejar
              // que crezca sin control y desalinee las 3 columnas.
              child: Text(
                etiquetas[indice],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                  color: activo ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
