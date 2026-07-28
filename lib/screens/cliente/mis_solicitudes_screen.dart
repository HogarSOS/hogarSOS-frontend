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
  late Future<List<MyServiceRequestSummary>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.listarMisSolicitudes();
  }

  void _recargar() {
    setState(() => _futuro = _servicio.listarMisSolicitudes());
    // El estado de una solicitud pudo cambiar mientras se veía su
    // detalle (cancelada, aceptada...) — el banner de Inicio usa un
    // provider aparte que hay que invalidar explícitamente, ver la
    // nota en resumenActividadClienteProvider.
    ref.invalidate(resumenActividadClienteProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.perfilMisSolicitudes)),
      body: FutureBuilder<List<MyServiceRequestSummary>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(t.misSolicitudesError));
          }
          final solicitudes = snapshot.data!;
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
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: solicitudes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = solicitudes[index];
                return EntradaAnimada(
                  retraso: Duration(milliseconds: 40 * index),
                  child: _SolicitudTile(solicitud: s, onRegresar: _recargar),
                );
              },
            ),
          );
        },
      ),
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
