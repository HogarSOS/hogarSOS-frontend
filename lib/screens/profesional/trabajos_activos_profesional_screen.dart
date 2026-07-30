import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_request_model.dart';
import '../../providers/service_request_provider.dart';
import '../../services/service_request_service.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../chat_screen.dart';
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

  Future<void> _completar(BuildContext context, WidgetRef ref, AssignedRequest trabajo) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: trabajo.precioEstimado?.toStringAsFixed(2) ?? '',
    );

    final precio = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trabajosActivosPrecioFinalTitulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.trabajosActivosPrecioFinalHint),
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

    if (precio == null || precio <= 0 || !context.mounted) return;

    try {
      await ServiceRequestService().completar(trabajo.id, precioFinal: precio);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trabajosActivosCompletadoExito)),
      );
      ref.invalidate(assignedRequestsProvider);

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
                      onChat: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            serviceRequestId: trabajo.id,
                            nombreContraparte: trabajo.clienteNombre,
                          ),
                        ),
                      ),
                      onCompletar: () => _completar(context, ref, trabajo),
                      onValorar: () => _valorar(context, ref, trabajo),
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
    required this.onChat,
    required this.onCompletar,
    required this.onValorar,
  });

  final AssignedRequest trabajo;
  final VoidCallback onChat;
  final VoidCallback onCompletar;
  final VoidCallback onValorar;

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
                  child: Text(
                    trabajo.clienteNombre.isNotEmpty ? trabajo.clienteNombre[0].toUpperCase() : '?',
                    style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
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
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
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
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(t.trabajosActivosChat),
                      onPressed: onChat,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(t.trabajosActivosCompletar),
                      onPressed: onCompletar,
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
