import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

/// Reclamaciones ("Reportar un problema") sobre un trabajo ya aceptado.
/// `subirFoto` es una copia deliberada de
/// `ServiceRequestService.subirFoto` — mismo endpoint genérico de subida,
/// pero se evita acoplar este subsistema al de solicitudes solo para
/// reutilizar un método de una línea.
class DisputeService {
  final _api = ApiService.instance.client;

  /// Siempre `foto_disputa`: todo lo que se sube desde aquí es una prueba
  /// adjunta a una reclamación, así que el tipo no lo elige el llamador
  /// (a diferencia de `ServiceRequestService.subirFoto`, que sirve para
  /// varios casos). El tipo decide quién podrá verla después: solo las
  /// dos partes de esa solicitud y un admin (auditoría B4).
  Future<String> subirFoto(File archivo) async {
    final nombre = archivo.path.split('/').last;
    final formData = FormData.fromMap({
      'tipo': 'foto_disputa',
      'foto': await MultipartFile.fromFile(archivo.path, filename: nombre),
    });
    final respuesta = await _api.post('/uploads/photo', data: formData);
    return respuesta.data['url'] as String;
  }

  Future<void> crearReclamacion(
    String serviceRequestId, {
    required String motivo,
    required String descripcion,
    List<String>? fotosUrls,
  }) async {
    await _api.post('/service-requests/$serviceRequestId/disputes', data: {
      'motivo': motivo,
      'descripcion': descripcion,
      if (fotosUrls != null && fotosUrls.isNotEmpty) 'fotosUrls': fotosUrls,
    });
  }
}
