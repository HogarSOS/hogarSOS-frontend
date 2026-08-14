import 'dart:io';
import 'package:dio/dio.dart';
import '../models/postulacion_model.dart';
import '../models/presupuesto_model.dart';
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
  /// Sube un archivo y lo CLASIFICA (auditoría B4). El `tipo` no es
  /// informativo: decide quién podrá verlo después. Un documento de
  /// identidad subido como `foto_perfil` quedaría visible para cualquier
  /// usuario, así que hay que pasarlo bien en cada llamada.
  ///
  /// Valores válidos (deben coincidir con el enum TipoArchivo del
  /// backend): foto_perfil, foto_solicitud, foto_disputa,
  /// documento_identidad, certificado, seguro_rc.
  Future<String> subirFoto(File archivo, {required String tipo}) async {
    final nombre = archivo.path.split('/').last;
    final formData = FormData.fromMap({
      'tipo': tipo,
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

  /// Se postula a una solicitud pendiente con un mensaje corto de
  /// disponibilidad — quien queda asignado lo decide el cliente después
  /// (ver seleccionarProfesional, más abajo).
  Future<void> postularse(String id, {required String mensaje}) async {
    await _api.post('/service-requests/$id/postulaciones', data: {'mensaje': mensaje});
  }

  Future<List<PostulacionCandidate>> listarPostulaciones(String id) async {
    final respuesta = await _api.get('/service-requests/$id/postulaciones');
    final lista = respuesta.data['postulaciones'] as List;
    return lista.map((json) => PostulacionCandidate.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> seleccionarProfesional(String id, String postulacionId) async {
    await _api.post('/service-requests/$id/postulaciones/$postulacionId/seleccionar');
  }

  /// Envía un presupuesto real tras ser elegido — cerrado (monto fijo)
  /// o por horas (tarifaHora + horasEstimadas, el importe que se
  /// autoriza al aceptar es tarifaHora × horasEstimadas).
  Future<void> enviarPresupuesto(
    String id, {
    required TipoPresupuesto tipo,
    double? monto,
    double? tarifaHora,
    double? horasEstimadas,
    String? mensaje,
    bool incluyeIva = false,
  }) async {
    await _api.post('/service-requests/$id/presupuesto', data: {
      'tipo': tipoPresupuestoToApi(tipo),
      if (monto != null) 'monto': monto,
      if (tarifaHora != null) 'tarifaHora': tarifaHora,
      if (horasEstimadas != null) 'horasEstimadas': horasEstimadas,
      if (mensaje != null && mensaje.isNotEmpty) 'mensaje': mensaje,
      'incluyeIva': incluyeIva,
    });
  }

  Future<void> responderPresupuesto(String id, String presupuestoId, {required bool aceptar}) async {
    await _api.post('/service-requests/$id/presupuesto/$presupuestoId/responder', data: {
      'accion': aceptar ? 'aceptar' : 'rechazar',
    });
  }

  /// Marca un trabajo como completado. Sin argumentos para presupuesto
  /// "cerrado" (el importe ya lo fija el presupuesto aceptado); con
  /// `horasReales` para "por_horas" (el backend calcula tarifa × horas,
  /// pero no libera el pago todavía — hace falta que el cliente
  /// confirme, ver responderCierreHoras).
  Future<void> completar(String id, {double? horasReales}) async {
    await _api.patch('/service-requests/$id/complete', data: {
      if (horasReales != null) 'horasReales': horasReales,
    });
  }

  /// Pide sumar más horas a un presupuesto "por_horas" ya aceptado,
  /// cuando el trabajo se alarga más de lo estimado.
  /// Exactamente uno de los dos según el tipo del presupuesto aceptado:
  /// `horasAdicionales` para "por_horas", `montoAdicional` para "cerrado".
  Future<void> pedirAmpliacion(String id, {double? horasAdicionales, double? montoAdicional, String? mensaje}) async {
    await _api.post('/service-requests/$id/ampliacion', data: {
      if (horasAdicionales != null) 'horasAdicionales': horasAdicionales,
      if (montoAdicional != null) 'montoAdicional': montoAdicional,
      if (mensaje != null && mensaje.isNotEmpty) 'mensaje': mensaje,
    });
  }

  Future<void> responderAmpliacion(String id, String ampliacionId, {required bool aceptar}) async {
    await _api.post('/service-requests/$id/ampliacion/$ampliacionId/responder', data: {
      'accion': aceptar ? 'aceptar' : 'rechazar',
    });
  }

  /// El cliente confirma (o rechaza) las horas reales que declaró el
  /// profesional al completar un trabajo "por_horas" — aceptar es lo
  /// que de verdad completa la solicitud y libera el pago.
  ///
  /// `confirmarReduccionGrande` solo hace falta cuando
  /// `CierreHorasInfo.reduccionAnomala` es true (auditoría 2026-08-14,
  /// protección anti-evasión) — sin ella el backend responde
  /// HOURS_REDUCTION_CONFIRMATION_REQUIRED en vez de liberar el pago.
  Future<void> responderCierreHoras(
    String id,
    String cierreId, {
    required bool aceptar,
    bool confirmarReduccionGrande = false,
  }) async {
    await _api.post('/service-requests/$id/cierre-horas/$cierreId/responder', data: {
      'accion': aceptar ? 'aceptar' : 'rechazar',
      if (confirmarReduccionGrande) 'confirmarReduccionGrande': true,
    });
  }

  Future<void> cancelar(String id) async {
    await _api.patch('/service-requests/$id/cancel');
  }

  /// El profesional marca que ha empezado a trabajar de verdad
  /// ("aceptada" -> "en_progreso") — protege su cobro frente a una
  /// cancelación instantánea del cliente. Opcional, no obligatorio para
  /// poder completar el trabajo después.
  Future<void> iniciarTrabajo(String id) async {
    await _api.patch('/service-requests/$id/start');
  }

  /// Deshace un "Iniciar trabajo" pulsado por error ("en_progreso" ->
  /// "aceptada"). No mueve ni un céntimo — la autorización de Stripe
  /// sigue retenida igual en ambos estados.
  Future<void> deshacerInicioTrabajo(String id) async {
    await _api.patch('/service-requests/$id/undo-start');
  }

  /// Borra del historial una solicitud que nadie llegó a aceptar
  /// (pendiente o cancelada, sin profesional asignado) — el backend
  /// rechaza el borrado si ya hubo un profesional de por medio.
  Future<void> borrar(String id) async {
    await _api.delete('/service-requests/$id');
  }

  /// Quita una solicitud terminada (completada o cancelada) de MI lista
  /// sin borrar nada — a diferencia de `borrar`, que solo vale para
  /// solicitudes que nadie llegó a aceptar. El historial de pago/chat/
  /// valoraciones se conserva; la otra parte sigue viéndola hasta que
  /// también la archive.
  Future<void> archivar(String id) async {
    await _api.patch('/service-requests/$id/archive');
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
