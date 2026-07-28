import 'package:dio/dio.dart';

/// Extrae un mensaje legible de un error de red.
///
/// Antes, varias pantallas mostraban `'$e'` directamente en el
/// SnackBar — para un DioException eso imprime algo como
/// "DioException [bad response]: ...", NUNCA el mensaje real que el
/// backend sí manda en el cuerpo de la respuesta (`{ "error": "..." }`,
/// ver el patrón `res.status(...).json({ error: '...' })` usado en
/// todos los controladores). El usuario nunca llegaba a ver por qué
/// algo había fallado — solo un texto técnico sin sentido. Esta
/// función es la misma idea que `_mensajeDio` en auth_service.dart,
/// generalizada para reutilizarla en cualquier pantalla.
String mensajeDeError(Object error, {String? contexto}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'No se pudo conectar con el servidor. Comprueba tu conexión.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'El servidor tardó demasiado en responder.';
      default:
        return contexto ?? 'Ocurrió un error inesperado.';
    }
  }
  return contexto ?? 'Ocurrió un error inesperado.';
}
