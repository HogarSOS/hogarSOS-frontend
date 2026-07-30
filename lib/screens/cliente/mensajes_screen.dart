import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../services/service_request_service.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';

/// Pestaña "Mensajes" del cliente — antes era un placeholder fijo
/// ("Próximamente") sin ningún dato real: el chat de verdad ya existía
/// y funcionaba desde "Mis solicitudes" → detalle → botón de chat, pero
/// no había ningún punto de entrada directo a "mis conversaciones"
/// desde la pestaña que lleva ese nombre en la barra de navegación —
/// exactamente el mismo hueco que tenía el profesional antes de que se
/// le añadiera su propia pestaña de Mensajes.
///
/// Solo se listan solicitudes con profesional asignado y todavía
/// activas (aceptada/en_progreso) — mismo criterio que ya usa el botón
/// de chat en seguimiento_solicitud_screen.dart, para no inventar un
/// criterio nuevo y distinto.
class MensajesScreen extends StatefulWidget {
  const MensajesScreen({super.key});

  @override
  State<MensajesScreen> createState() => _MensajesScreenState();
}

class _MensajesScreenState extends State<MensajesScreen> {
  final _servicio = ServiceRequestService();
  late Future<List<MyServiceRequestSummary>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.listarMisSolicitudes();
  }

  void _recargar() {
    setState(() => _futuro = _servicio.listarMisSolicitudes());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.navMensajes)),
      body: FutureBuilder<List<MyServiceRequestSummary>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(t.misSolicitudesError)),
                  ),
                ],
              ),
            );
          }

          final conversaciones = snapshot.data!
              .where((s) => s.estado == EstadoSolicitud.aceptada || s.estado == EstadoSolicitud.en_progreso)
              .toList();

          if (conversaciones.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                            child: Icon(Icons.forum_outlined, size: 44, color: colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            t.mensajesVacioTitulo,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.mensajesProximamenteDescripcion,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = conversaciones[index];
                final color = colorParaCategoria(s.categoria);
                return EntradaAnimada(
                  retraso: Duration(milliseconds: 40 * index),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(iconoParaCategoria(s.categoria), color: color, size: 22),
                      ),
                      title: Text(nombreLocalizadoCategoria(context, s.categoria)),
                      subtitle: Text(
                        s.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(serviceRequestId: s.id, nombreContraparte: s.profesionalNombre),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
