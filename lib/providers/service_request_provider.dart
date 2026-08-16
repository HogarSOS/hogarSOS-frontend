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

  /// Solo pasa por el estado "cargando" (pantalla completa con spinner)
  /// si todavía no hay ningún dato previo — en refrescos posteriores
  /// (automáticos cada 10s o pull-to-refresh) la lista ya mostrada se
  /// queda visible mientras se pide la actualización, y solo se
  /// reemplaza al llegar la respuesta. Antes cada refresco pasaba por
  /// loading() primero, lo que tiraba toda la lista a un spinner y
  /// perdía la posición de scroll cada 10 segundos.
  Future<void> cargar() async {
    if (!state.hasValue) state = const AsyncValue.loading();
    try {
      final solicitudes = await _servicio.listarCercanas();
      state = AsyncValue.data(solicitudes);
    } catch (e, st) {
      // Un refresco silencioso que falla (ej. un blip de red) no debe
      // borrar una lista que ya se estaba mostrando bien — solo se
      // convierte en pantalla de error si es la primera carga.
      if (!state.hasValue) state = AsyncValue.error(e, st);
    }
  }

  /// Ignora una solicitud de forma persistente por cuenta (no por
  /// dispositivo) — ver ignorarSolicitud en postulacion.controller.ts.
  /// No vuelve a aparecer en ningún sondeo posterior, ni en otro
  /// dispositivo con la misma cuenta, ni tras cerrar y reabrir la app.
  /// Optimista: la quita de la lista al instante y llama al backend; si
  /// la llamada falla, la devuelve a la lista y relanza el error para
  /// que la pantalla pueda avisar (mismo patrón que
  /// DisponibilidadNotifier.actualizar).
  Future<void> ignorar(String solicitudId) async {
    final anterior = state;
    state = state.whenData(
      (lista) => lista.where((s) => s.id != solicitudId).toList(),
    );
    try {
      await _servicio.ignorar(solicitudId);
    } catch (e) {
      state = anterior;
      rethrow;
    }
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

/// Trabajos que el profesional ya aceptó y aún no completó (o completó
/// hace poco, sin archivar). StateNotifier en vez de FutureProvider por
/// el mismo motivo que NearbyRequestsNotifier: ProfesionalShellScreen lo
/// sondea cada 10s para que un trabajo cancelado por el cliente
/// desaparezca solo de "Trabajos activos" sin esperar a un
/// pull-to-refresh manual, y ese sondeo no debe tirar la lista a un
/// spinner en cada vuelta — ver cargar().
class AssignedRequestsNotifier extends StateNotifier<AsyncValue<List<AssignedRequest>>> {
  AssignedRequestsNotifier(this._servicio) : super(const AsyncValue.loading()) {
    cargar();
  }

  final ServiceRequestService _servicio;

  Future<void> cargar() async {
    if (!state.hasValue) state = const AsyncValue.loading();
    try {
      final trabajos = await _servicio.listarTrabajosAsignados();
      state = AsyncValue.data(trabajos);
    } catch (e, st) {
      if (!state.hasValue) state = AsyncValue.error(e, st);
    }
  }

  /// Quita un trabajo de la lista local sin esperar a la respuesta del
  /// servidor — usado al archivar (ver trabajos_activos_profesional_screen.dart):
  /// el swipe de Dismissible ya lo hizo desaparecer visualmente, así que
  /// los datos deben reflejarlo YA. Si la llamada real a archivar falla
  /// después, quien la invoque debe llamar a cargar() para recuperar el
  /// estado real del servidor.
  void quitarLocal(String id) {
    state = state.whenData((lista) => lista.where((t) => t.id != id).toList());
  }
}

final assignedRequestsProvider =
    StateNotifierProvider<AssignedRequestsNotifier, AsyncValue<List<AssignedRequest>>>((ref) {
  return AssignedRequestsNotifier(ref.watch(serviceRequestServiceProvider));
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
