import '../models/admin_models.dart';
import 'api_service.dart';

class AdminService {
  final _api = ApiService.instance.client;

  Future<List<PendingVerification>> listarVerificacionesPendientes() async {
    final respuesta = await _api.get('/admin/verifications/pending');
    return (respuesta.data as List)
        .map((json) => PendingVerification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> decidirVerificacion({
    required String professionalId,
    required bool aprobar,
    String? motivoRechazo,
  }) async {
    await _api.patch('/admin/verifications/$professionalId/approve', data: {
      'aprobar': aprobar,
      if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
    });
  }

  Future<List<DisputeSummary>> listarDisputas() async {
    final respuesta = await _api.get('/admin/disputes');
    return (respuesta.data as List)
        .map((json) => DisputeSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolverDisputa({
    required String disputeId,
    required bool favorProfesional,
    required String notas,
  }) async {
    await _api.patch('/admin/disputes/$disputeId/resolve', data: {
      'resolucion': favorProfesional ? 'resuelta_profesional' : 'resuelta_cliente',
      'notas': notas,
    });
  }

  Future<StuckPaymentsSummary> listarPagosAtascados() async {
    final respuesta = await _api.get('/admin/payments/stuck');
    return StuckPaymentsSummary.fromJson(respuesta.data as Map<String, dynamic>);
  }

  /// Reintenta capturar/transferir un pago atascado. Usa exactamente el
  /// mismo `releasePayments` idempotente y reanudable del flujo normal
  /// (ver `reintentarLiberacion` en `payment.service.ts`) — un doble tap
  /// no mueve dinero dos veces, el backend ya lo protege.
  Future<void> reintentarLiberacion(String serviceRequestId) async {
    await _api.post('/admin/payments/$serviceRequestId/retry');
  }

  Future<List<ScheduledJob>> listarTareas() async {
    final respuesta = await _api.get('/admin/jobs');
    return (respuesta.data['tareas'] as List)
        .map((j) => ScheduledJob.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Fuerza la ejecución de una tarea ya (sin esperar a su ciclo). El
  /// lock en BD (`bloqueadoHasta`) lo sigue gestionando el backend — si
  /// ya está en curso, `ejecutarTareaAhora` en `scheduler.ts` responde
  /// 409 en vez de duplicarla.
  Future<String> ejecutarTareaAhora(String nombre) async {
    final respuesta = await _api.post('/admin/jobs/$nombre/run');
    return respuesta.data['resultado'] as String;
  }
}
