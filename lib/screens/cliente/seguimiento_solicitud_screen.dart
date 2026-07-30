import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../services/service_request_service.dart';
import '../../utils/category_display.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';
import 'pago_screen.dart';
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

class _SeguimientoSolicitudScreenState extends ConsumerState<SeguimientoSolicitudScreen> {
  final _servicio = ServiceRequestService();
  ServiceRequestModel? _solicitud;
  String? _error;
  Timer? _polling;

  static const _estadosActivos = {EstadoSolicitud.pendiente, EstadoSolicitud.aceptada, EstadoSolicitud.en_progreso};

  @override
  void initState() {
    super.initState();
    _cargar();
    _polling = Timer.periodic(const Duration(seconds: 5), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _polling?.cancel();
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
        _polling?.cancel();
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

        // Cancelar solo tiene sentido mientras nadie la ha aceptado —
        // en cuanto pasa a "aceptada" el botón desaparece solo, porque
        // esta condición deja de cumplirse (no hace falta lógica
        // aparte para "ocultarlo tras aceptar").
        if (solicitud.estado == EstadoSolicitud.pendiente) ...[
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
          if (solicitud.payment == null)
            OutlinedButton.icon(
              icon: const Icon(Icons.payment_outlined),
              label: Text(t.seguimientoAutorizarPago),
              onPressed: () async {
                final resultado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => PagoScreen(serviceRequestId: solicitud.id)),
                );
                if (resultado == true) onRecargar();
              },
            )
          else
            _EstadoPagoChip(payment: solicitud.payment!),
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
            '${payment.montoTotal.toStringAsFixed(2)} €',
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
              child: Text(
                etiquetas[indice],
                textAlign: TextAlign.center,
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
