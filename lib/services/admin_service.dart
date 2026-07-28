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
}
