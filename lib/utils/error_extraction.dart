import 'package:dio/dio.dart';
import '../l10n/app_localizations.dart';

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
///
/// `t` es opcional (no siempre hay un `BuildContext` a mano) — sin él,
/// los mensajes de conexión/error genérico caen al español fijo, igual
/// que antes de la Sprint 2. Pasándolo, esos mismos mensajes (los
/// únicos que este archivo redacta directamente, no el resto que ya
/// viene traducido en `contexto` o del backend) respetan el idioma
/// activo de la app.
String mensajeDeError(Object error, {String? contexto, AppLocalizations? t}) {
  final errorConexion = t?.errorConexion ?? 'No se pudo conectar con el servidor. Comprueba tu conexión.';
  final errorServidorLento = t?.errorServidorLento ?? 'El servidor tardó demasiado en responder.';
  final errorInesperado = t?.errorInesperado ?? 'Ocurrió un error inesperado.';

  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return errorConexion;
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return errorServidorLento;
      default:
        return contexto ?? errorInesperado;
    }
  }
  return contexto ?? errorInesperado;
}
