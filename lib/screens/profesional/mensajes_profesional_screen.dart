import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/chat_read_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../utils/category_display.dart';
import '../../utils/imagen_autenticada.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';

/// Pestaña "Mensajes" del profesional (revisión UX 2026-08-16) — antes
/// esta pestaña mostraba en realidad TrabajosActivosProfesionalScreen
/// (tarjetas con Chat, Enviar presupuesto, Reportar...), mezclando "mis
/// conversaciones" con "gestión de mis trabajos". Ahora es una lista
/// limpia de conversaciones, mismo patrón que ya usa el cliente en
/// cliente/mensajes_screen.dart (no se inventa uno nuevo). Trabajos
/// activos sigue existiendo tal cual, como pantalla independiente
/// accesible desde la tarjeta "Tienes X trabajos activos" en Solicitudes
/// (ver home_profesional_screen.dart) y desde notificaciones de un
/// trabajo ya asignado (ver resolverDestinoNotificacionProfesional en
/// profesional_shell_screen.dart).
///
/// Solo se listan trabajos aceptados/en curso — mismo criterio que ya
/// usa mensajes_screen.dart del cliente, para no inventar un criterio
/// nuevo. Un trabajo completado (hasta que se archive) sigue teniendo su
/// botón de Chat en Trabajos activos; simplemente no aparece aquí.
///
/// Reutiliza unreadChatProvider/assignedRequestsProvider/ChatScreen tal
/// cual — sin providers de chat nuevos, sin tocar backend ni Firestore.
class MensajesProfesionalScreen extends ConsumerWidget {
  const MensajesProfesionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final trabajosAsync = ref.watch(assignedRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.navMensajes)),
      body: trabajosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => RefreshIndicator(
          onRefresh: () async => ref.read(assignedRequestsProvider.notifier).cargar(),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(t.trabajosActivosErrorCargar)),
              ),
            ],
          ),
        ),
        data: (trabajos) {
          final conversaciones = trabajos
              .where((tr) => tr.estado == EstadoSolicitud.aceptada || tr.estado == EstadoSolicitud.en_progreso)
              .toList();

          if (conversaciones.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.read(assignedRequestsProvider.notifier).cargar(),
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
            onRefresh: () async => ref.read(assignedRequestsProvider.notifier).cargar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final trabajo = conversaciones[index];
                final noLeido = ref.watch(unreadChatProvider(trabajo.id));
                return EntradaAnimada(
                  retraso: Duration(milliseconds: 40 * index),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 22,
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
                      title: Text(
                        trabajo.clienteNombre,
                        style: TextStyle(
                          fontWeight: noLeido ? FontWeight.w800 : FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        nombreLocalizadoCategoria(context, trabajo.categoria),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: noLeido ? FontWeight.w600 : FontWeight.normal,
                          color: noLeido ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: noLeido
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
                            )
                          : const Icon(Icons.chat_bubble_outline),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(serviceRequestId: trabajo.id, nombreContraparte: trabajo.clienteNombre),
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
