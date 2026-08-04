import 'package:cached_network_image/cached_network_image.dart';

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
