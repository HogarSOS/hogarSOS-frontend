import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../services/token_storage.dart';

/// Cabeceras para cargar imágenes servidas por el backend (auditoría B4).
///
/// Desde B4, `/uploads/<archivo>` ya no es un directorio estático público:
/// exige sesión y comprueba permisos según el tipo de archivo (una foto
/// de perfil la ve cualquiera; un documento de identidad, solo su dueño y
/// un admin). Los widgets de imagen no pasan por Dio, así que no heredan
/// el interceptor que añade el token — hay que ponérselo aquí.
///
/// Punto único a propósito: si mañana cambia la forma de autenticar las
/// imágenes, se cambia aquí y no en los once sitios que pintan una.
Map<String, String> cabecerasImagen() {
  final token = TokenStorage.instance.accessTokenEnMemoria;
  return token == null ? const {} : {'Authorization': 'Bearer $token'};
}

/// `CachedNetworkImageProvider` con la sesión ya puesta. Sustituye al uso
/// directo del provider en cualquier imagen que venga de nuestro backend.
///
/// Sigue cacheando en disco por URL igual que antes: una imagen ya
/// descargada no vuelve a pedirse, así que añadir autenticación no
/// supone más tráfico ni más latencia en el uso normal.
CachedNetworkImageProvider imagenDeRed(
  String url, {
  int? maxWidth,
  int? maxHeight,
}) {
  return CachedNetworkImageProvider(
    url,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    headers: cabecerasImagen(),
  );
}

/// Manejador común para un fallo al cargar una imagen remota (auditoría
/// Crashlytics 25/8: `MultiImageStreamCompleter`/`ImageStreamCompleter`
/// registró 9 fallos como "Fatal" — con `FlutterError.onError` conectado a
/// `recordFlutterFatalError` en main.dart, CUALQUIER fallo de imagen sin
/// listener de error propio cae ahí. Una imagen rota (URL vieja, host
/// caído, archivo borrado) es un dato esperable, no un crash del
/// framework: la app sigue funcionando igual, solo falta esa foto.
///
/// Pásalo tal cual a `onBackgroundImageError` (CircleAvatar) o `onError`
/// (DecorationImage) — su firma coincide exactamente. En cuanto ese
/// callback no es nulo, Flutter entrega el error AHÍ en vez de dejarlo
/// caer en `FlutterError.reportError` (y por tanto en el handler global
/// fatal) — ver `ImageStreamCompleter.reportError` en el SDK. Se sigue
/// mandando a Crashlytics, pero marcado explícitamente como no-fatal, así
/// que una URL rota sigue siendo detectable sin inflar la tasa de crashes.
void onErrorImagenDeRed(Object error, StackTrace? stackTrace) {
  debugPrint('[imagenDeRed] No se pudo cargar la imagen: $error');
  if (kReleaseMode) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
  }
}

/// `true` si `url` es una URL de imagen usable — evita pasarle a
/// `imagenDeRed` un `null` (ya cubierto por los `!= null` existentes) o un
/// string vacío (que SÍ pasaba antes: `CachedNetworkImageProvider('')`
/// intenta resolver una URI vacía y falla igual que una rota).
bool urlDeImagenValida(String? url) => url != null && url.trim().isNotEmpty;
