import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/service_request_provider.dart';
import '../../services/service_request_service.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';
import 'seguimiento_solicitud_screen.dart';

class MisSolicitudesScreen extends ConsumerStatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  ConsumerState<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends ConsumerState<MisSolicitudesScreen> {
  final _servicio = ServiceRequestService();
  List<MyServiceRequestSummary>? _solicitudes;
  bool _error = false;
  Timer? _polling;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Antes solo se cargaba una vez al entrar y con pull-to-refresh
    // manual — una solicitud nueva o un cambio de estado (candidato
    // nuevo, aceptada...) no se veía sin deslizar. Mismo patrón de
    // sondeo silencioso que seguimiento_solicitud_screen.dart.
    _polling = Timer.periodic(const Duration(seconds: 10), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _polling?.cancel();
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

  Future<bool> _confirmarBorrado(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.misSolicitudesBorrarTitulo),
        content: Text(t.misSolicitudesBorrarMensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.misSolicitudesBorrarConfirmar),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _borrar(String id) async {
    final t = AppLocalizations.of(context);
    try {
      await _servicio.borrar(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.misSolicitudesBorrarExito)));
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.misSolicitudesBorrarError)));
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
                    final borrable = s.profesionalNombre == null &&
                        (s.estado == EstadoSolicitud.pendiente || s.estado == EstadoSolicitud.cancelada);
                    final tile = EntradaAnimada(
                      retraso: Duration(milliseconds: 40 * index),
                      child: _SolicitudTile(solicitud: s, onRegresar: _recargar),
                    );
                    if (!borrable) return tile;
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
                      confirmDismiss: (_) => _confirmarBorrado(context),
                      onDismissed: (_) => _borrar(s.id),
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

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(iconoParaCategoria(solicitud.categoria), color: color, size: 22),
        ),
        title: Text(nombreLocalizadoCategoria(context, solicitud.categoria)),
        subtitle: Row(
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
