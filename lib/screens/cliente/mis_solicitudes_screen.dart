import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/service_request_provider.dart';
import '../../services/service_request_service.dart';
import '../../utils/category_display.dart';
import '../../utils/polling_lifecycle_mixin.dart';
import '../../widgets/entrada_animada.dart';
import 'seguimiento_solicitud_screen.dart';

class MisSolicitudesScreen extends ConsumerStatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  ConsumerState<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends ConsumerState<MisSolicitudesScreen>
    with WidgetsBindingObserver, PollingLifecycleMixin {
  final _servicio = ServiceRequestService();
  List<MyServiceRequestSummary>? _solicitudes;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Antes solo se cargaba una vez al entrar y con pull-to-refresh
    // manual — una solicitud nueva o un cambio de estado (candidato
    // nuevo, aceptada...) no se veía sin deslizar. Mismo patrón de
    // sondeo silencioso que seguimiento_solicitud_screen.dart. Se pausa
    // solo con la app en segundo plano (ver PollingLifecycleMixin).
    startPolling(const Duration(seconds: 10), () => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    try {
      final solicitudes = await _servicio.listarMisSolicitudes();
      if (!mounted) return;
      setState(() {
        _solicitudes = solicitudes;
        _error = false;
      });
    } catch (e) {
      if (!mounted || silencioso) return; // en el sondeo de fondo, un fallo puntual no debe mostrar error
      setState(() => _error = true);
    }
  }

  void _recargar() {
    _cargar();
    // El estado de una solicitud pudo cambiar mientras se veía su
    // detalle (cancelada, aceptada...) — el banner de Inicio usa un
    // provider aparte que hay que invalidar explícitamente, ver la
    // nota en resumenActividadClienteProvider.
    ref.invalidate(resumenActividadClienteProvider);
  }

  Future<bool> _confirmarBorrado(BuildContext context, {required bool archivar}) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(archivar ? t.misSolicitudesArchivarTitulo : t.misSolicitudesBorrarTitulo),
        content: Text(archivar ? t.misSolicitudesArchivarMensaje : t.misSolicitudesBorrarMensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(archivar ? t.misSolicitudesArchivarConfirmar : t.misSolicitudesBorrarConfirmar),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  /// `archivar`: la solicitud ya tuvo profesional de por medio (pago/chat
  /// posible) — se oculta de la lista sin borrar nada. Si no, es una
  /// solicitud huérfana (nadie la aceptó nunca) y se borra de verdad.
  Future<void> _quitar(String id, {required bool archivar}) async {
    final t = AppLocalizations.of(context);
    try {
      if (archivar) {
        await _servicio.archivar(id);
      } else {
        await _servicio.borrar(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(archivar ? t.misSolicitudesArchivarExito : t.misSolicitudesBorrarExito)),
      );
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(archivar ? t.misSolicitudesArchivarError : t.misSolicitudesBorrarError)),
      );
      _recargar(); // por si el Dismissible ya la quitó visualmente antes de fallar
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.perfilMisSolicitudes)),
      body: _solicitudes == null
          ? (_error
              ? Center(child: Text(t.misSolicitudesError))
              : const Center(child: CircularProgressIndicator()))
          : Builder(builder: (context) {
              final solicitudes = _solicitudes!;
              if (solicitudes.isEmpty) {
                final colorScheme = Theme.of(context).colorScheme;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(t.misSolicitudesVacio, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _cargar(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: solicitudes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = solicitudes[index];
                    // Huérfana (nadie la aceptó nunca) -> se borra de verdad.
                    // Terminada con profesional de por medio -> se archiva
                    // (se oculta, conserva pago/chat/valoraciones).
                    final huerfana = s.profesionalNombre == null &&
                        (s.estado == EstadoSolicitud.pendiente || s.estado == EstadoSolicitud.cancelada);
                    final archivable = s.estado == EstadoSolicitud.completada ||
                        (s.estado == EstadoSolicitud.cancelada && s.profesionalNombre != null);
                    final tile = EntradaAnimada(
                      retraso: Duration(milliseconds: 40 * index),
                      child: _SolicitudTile(solicitud: s, onRegresar: _recargar),
                    );
                    if (!huerfana && !archivable) return tile;
                    return Dismissible(
                      key: ValueKey(s.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                      ),
                      confirmDismiss: (_) => _confirmarBorrado(context, archivar: archivable),
                      onDismissed: (_) => _quitar(s.id, archivar: archivable),
                      child: tile,
                    );
                  },
                ),
              );
            }),
    );
  }
}

class _SolicitudTile extends StatelessWidget {
  const _SolicitudTile({required this.solicitud, required this.onRegresar});

  final MyServiceRequestSummary solicitud;
  final VoidCallback onRegresar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorParaCategoria(solicitud.categoria);

    final (textoEstado, colorEstado) = switch (solicitud.estado) {
      EstadoSolicitud.pendiente => (t.seguimientoBuscando, colorScheme.primary),
      EstadoSolicitud.aceptada => (t.seguimientoAceptada, colorScheme.tertiary),
      EstadoSolicitud.en_progreso => (t.seguimientoEnProgreso, colorScheme.tertiary),
      EstadoSolicitud.completada => (t.seguimientoCompletada, Colors.green),
      EstadoSolicitud.cancelada => (t.seguimientoCancelada, colorScheme.error),
      EstadoSolicitud.disputada => (t.seguimientoDisputada, colorScheme.error),
    };

    final textoUrgencia = switch (solicitud.urgencia) {
      UrgenciaSolicitud.hoy => t.wizardUrgenciaHoy,
      UrgenciaSolicitud.manana => t.wizardUrgenciaManana,
      UrgenciaSolicitud.fechaEspecifica => null, // sin fecha concreta a mano en el resumen, se omite
      UrgenciaSolicitud.loAntesPosible => null, // es el caso por defecto, no aporta resaltarlo
    };

    // Un presupuesto/ampliación/cierre de horas pendiente de que el
    // cliente responda es la única situación de esta lista donde de
    // verdad hace falta que el usuario entre — antes solo se distinguía
    // por el texto de estado (p.ej. "Aceptada"), indistinguible a
    // simple vista de una solicitud sin nada pendiente. El borde de
    // color + la insignia son a propósito redundantes con el texto,
    // para que se note incluso pasando el dedo rápido por la lista.
    final destacar = solicitud.requiereAccion;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: destacar ? BorderSide(color: colorScheme.tertiary, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(iconoParaCategoria(solicitud.categoria), color: color, size: 22),
        ),
        title: Text(nombreLocalizadoCategoria(context, solicitud.categoria)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    textoEstado,
                    style: TextStyle(color: colorEstado, fontWeight: FontWeight.w600, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (textoUrgencia != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      textoUrgencia,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ],
            ),
            if (destacar) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.priority_high, size: 13, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 3),
                    Text(
                      t.misSolicitudesAccionRequerida,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SeguimientoSolicitudScreen(solicitudId: solicitud.id)),
          );
          onRegresar(); // el estado puede haber cambiado mientras se veía el detalle
        },
      ),
    );
  }
}
