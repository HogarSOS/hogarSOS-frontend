import 'dart:io';
import 'package:dio/dio.dart';
import '../models/service_category_model.dart';
import '../models/service_request_model.dart';
import 'api_service.dart';

class ServiceRequestService {
  final _api = ApiService.instance.client;

  Future<List<ServiceCategory>> obtenerCategorias() async {
    final respuesta = await _api.get('/service-categories');
    return (respuesta.data as List)
        .map((json) => ServiceCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Sube una foto y devuelve su URL pública, para incluirla luego en
  /// crearSolicitud. Se hace en un paso separado (no dentro del propio
  /// POST de creación) porque el usuario puede añadir/quitar fotos
  /// mientras rellena el asistente, antes de publicar nada.
  Future<String> subirFoto(File archivo) async {
    final nombre = archivo.path.split('/').last;
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(archivo.path, filename: nombre),
    });
    final respuesta = await _api.post('/uploads/photo', data: formData);
    return respuesta.data['url'] as String;
  }

  Future<String> crearSolicitud({
    required int categoryId,
    required String descripcion,
    required double latitud,
    required double longitud,
    List<String>? fotosUrls,
    String? direccionTexto,
    double? precioEstimado,
    UrgenciaSolicitud urgencia = UrgenciaSolicitud.loAntesPosible,
    DateTime? fechaDeseada,
  }) async {
    final respuesta = await _api.post('/service-requests', data: {
      'categoryId': categoryId,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      if (fotosUrls != null && fotosUrls.isNotEmpty) 'fotosUrls': fotosUrls,
      if (direccionTexto != null) 'direccionTexto': direccionTexto,
      if (precioEstimado != null) 'precioEstimado': precioEstimado,
      'urgencia': urgencia.valorApi,
      if (fechaDeseada != null) 'fechaDeseada': fechaDeseada.toUtc().toIso8601String(),
    });
    return respuesta.data['id'] as String;
  }

  Future<ServiceRequestModel> obtenerPorId(String id) async {
    final respuesta = await _api.get('/service-requests/$id');
    return ServiceRequestModel.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<List<MyServiceRequestSummary>> listarMisSolicitudes() async {
    final respuesta = await _api.get('/service-requests/mine');
    final lista = respuesta.data['solicitudes'] as List;
    return lista.map((j) => MyServiceRequestSummary.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<NearbyRequest>> listarCercanas() async {
    final respuesta = await _api.get('/service-requests/nearby/list');
    final lista = respuesta.data['solicitudes'] as List;
    return lista.map((json) => NearbyRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<AssignedRequest>> listarTrabajosAsignados() async {
    final respuesta = await _api.get('/service-requests/assigned/mine');
    final lista = respuesta.data['solicitudes'] as List;
    return lista.map((json) => AssignedRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> aceptar(String id) async {
    await _api.patch('/service-requests/$id/accept');
  }

  Future<void> completar(String id, {required double precioFinal}) async {
    await _api.patch('/service-requests/$id/complete', data: {'precioFinal': precioFinal});
  }

  Future<void> cancelar(String id) async {
    await _api.patch('/service-requests/$id/cancel');
  }

  /// Reintenta la sincronización del chat de esta solicitud a Firestore
  /// (UIDs de Firebase de cliente y profesional). La sincronización
  /// automática al aceptar puede fallar en silencio del lado del
  /// backend (credenciales de Firebase Admin, API deshabilitada...) —
  /// esto existe para que abrir el chat se autorrepare en vez de
  /// quedar roto para siempre. Se llama antes de suscribirse a los
  /// mensajes (ver chat_screen.dart); si falla, el chat sigue
  /// intentando cargar igual — el error real de Firestore ya se
  /// muestra por su cuenta si la sincronización de verdad hacía falta.
  Future<void> sincronizarChat(String id) async {
    await _api.post('/service-requests/$id/sync-chat');
  }

  /// Marca el chat como leído por mí (ver chat_read_provider.dart) —
  /// escribe en Firestore vía el backend, porque el cliente Flutter no
  /// tiene permiso de escritura directa sobre ese documento.
  Future<void> marcarChatLeido(String id) async {
    await _api.post('/service-requests/$id/mark-chat-read');
  }
}
