import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_category_model.dart';
import '../models/service_request_model.dart';
import '../services/service_request_service.dart';

final serviceRequestServiceProvider = Provider((ref) => ServiceRequestService());

/// Carga el catálogo de categorías una sola vez (se usa en la pantalla
/// "¿Qué necesitas?" del cliente).
final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final servicio = ref.watch(serviceRequestServiceProvider);
  return servicio.obtenerCategorias();
});

/// Estado de las solicitudes cercanas visibles para el profesional.
/// Es un StateNotifier (no un simple FutureProvider) porque necesita
/// soportar "refrescar" y "quitar de la lista al aceptar" sin recargar
/// toda la pantalla.
class NearbyRequestsNotifier extends StateNotifier<AsyncValue<List<NearbyRequest>>> {
  NearbyRequestsNotifier(this._servicio) : super(const AsyncValue.loading()) {
    cargar();
  }

  final ServiceRequestService _servicio;

  Future<void> cargar() async {
    state = const AsyncValue.loading();
    try {
      final solicitudes = await _servicio.listarCercanas();
      state = AsyncValue.data(solicitudes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Oculta una solicitud de la lista local sin llamar a la API — no
  /// existe un endpoint de "rechazar" porque la solicitud sigue siendo
  /// visible para otros profesionales; "ignorar" es solo un filtro local.
  void ocultar(String solicitudId) {
    state = state.whenData(
      (lista) => lista.where((s) => s.id != solicitudId).toList(),
    );
  }

  /// Se postula a una solicitud — a diferencia de aceptar, NO la quita
  /// de la lista (sigue "pendiente" y visible para otros profesionales
  /// hasta que el cliente elija a alguien); solo marca localmente
  /// `yaPostulado` para que esta tarjeta deje de ofrecer el botón.
  Future<void> postularse(String solicitudId, {required String mensaje}) async {
    await _servicio.postularse(solicitudId, mensaje: mensaje);
    state = state.whenData(
      (lista) => lista
          .map((s) => s.id == solicitudId
              ? NearbyRequest(
                  id: s.id,
                  descripcion: s.descripcion,
                  distanciaMetros: s.distanciaMetros,
                  createdAt: s.createdAt,
                  urgencia: s.urgencia,
                  clienteNombre: s.clienteNombre,
                  clienteFotoUrl: s.clienteFotoUrl,
                  yaPostulado: true,
                )
              : s)
          .toList(),
    );
  }
}

final nearbyRequestsProvider =
    StateNotifierProvider<NearbyRequestsNotifier, AsyncValue<List<NearbyRequest>>>((ref) {
  return NearbyRequestsNotifier(ref.watch(serviceRequestServiceProvider));
});

/// Trabajos que el profesional ya aceptó y aún no completó.
/// `autoDispose` — no hace falta mantenerlo vivo cuando no se está
/// viendo esa pantalla, se recarga sola al volver a entrar.
final assignedRequestsProvider = FutureProvider.autoDispose<List<AssignedRequest>>((ref) {
  final servicio = ref.watch(serviceRequestServiceProvider);
  return servicio.listarTrabajosAsignados();
});

/// Resumen de "solicitudes activas" para el banner de Inicio del
/// cliente — reutiliza el mismo endpoint que "Mis solicitudes"
/// (/service-requests/mine), no añade ninguna llamada nueva.
///
/// Antes vivía como provider privado dentro de home_cliente_screen.dart
/// — eso significaba que, con IndexedStack manteniendo Home siempre
/// montado, el resultado quedaba cacheado para siempre y nada podía
/// invalidarlo desde fuera de ese archivo. Cancelar una solicitud (u
/// otra acción que cambie cuántas están activas) dejaba el banner
/// desactualizado hasta un pull-to-refresh manual en Inicio. Al
/// hacerlo público aquí, seguimiento_solicitud_screen.dart y
/// mis_solicitudes_screen.dart pueden invalidarlo tras cualquier
/// acción que cambie el estado de una solicitud.
final resumenActividadClienteProvider = FutureProvider.autoDispose<List<MyServiceRequestSummary>>((ref) {
  final servicio = ref.watch(serviceRequestServiceProvider);
  return servicio.listarMisSolicitudes();
});
