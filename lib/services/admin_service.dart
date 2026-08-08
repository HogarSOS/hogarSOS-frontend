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
}
