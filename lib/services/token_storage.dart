import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la sesión — en disco (persiste entre arranques de la app) o
/// solo en memoria (se pierde al cerrar del todo la app), según lo que
/// elija el usuario con la casilla "Mantener sesión iniciada" del
/// login. Con la casilla desmarcada, el `login`/`registro` siguen
/// funcionando exactamente igual DENTRO de esa misma sesión — solo que
/// al volver a abrir la app en frío no queda nada en disco que
/// restaurar, así que cae al login. Ambos modos usan las mismas claves
/// de flutter_secure_storage; la única diferencia es escribir ahí o no.
class TokenStorage {
  TokenStorage._internal();
  static final TokenStorage instance = TokenStorage._internal();

  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'hogarsos_access_token';
  static const _refreshKey = 'hogarsos_refresh_token';
  static const _usuarioKey = 'hogarsos_usuario';

  String? _memAccessToken;
  String? _memRefreshToken;
  Map<String, dynamic>? _memUsuario;
  bool _persistente = true;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required bool persistente,
  }) async {
    _persistente = persistente;
    if (persistente) {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } else {
      // Por si había una sesión persistente ANTERIOR en este mismo
      // dispositivo (otro usuario, u otro login previo con la casilla
      // marcada) — sin este borrado, restaurarSesion() en el próximo
      // arranque en frío encontraría esos tokens viejos en disco y
      // restauraría una sesión que el usuario pidió explícitamente NO
      // recordar.
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      _memAccessToken = accessToken;
      _memRefreshToken = refreshToken;
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    if (_persistente) {
      await _storage.write(key: _accessKey, value: accessToken);
    } else {
      _memAccessToken = accessToken;
    }
  }

  /// Guarda el JSON crudo del usuario (tal como lo devuelve el backend
  /// en login/registro), para poder restaurar la sesión al arrancar en
  /// frío sin depender de un AppUser.toJson() que hoy no existe.
  Future<void> saveUsuario(Map<String, dynamic> usuarioJson, {required bool persistente}) async {
    if (persistente) {
      await _storage.write(key: _usuarioKey, value: jsonEncode(usuarioJson));
    } else {
      await _storage.delete(key: _usuarioKey);
      _memUsuario = usuarioJson;
    }
  }

  Future<Map<String, dynamic>?> getUsuario() async {
    if (_memUsuario != null) return _memUsuario;
    final raw = await _storage.read(key: _usuarioKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Copia en memoria del access token, sin `await`.
  ///
  /// Necesaria para los widgets de imagen (ver utils/imagen_autenticada.dart):
  /// desde B4, /uploads exige autenticación, y un `ImageProvider` se
  /// construye de forma síncrona dentro de `build` — no puede esperar a
  /// leer del almacenamiento seguro. `getAccessToken` de abajo rellena
  /// esta copia en su primera lectura, y el interceptor de Dio la llama
  /// en cada petición, así que para cuando se pinta una imagen ya está.
  String? get accessTokenEnMemoria => _memAccessToken;

  Future<String?> getAccessToken() async {
    // Se cachea en memoria al leer de disco (arranque en frío con sesión
    // persistente): sin esto, `accessTokenEnMemoria` seguiría a null
    // hasta el primer login de esa ejecución y las imágenes saldrían sin
    // cabecera.
    _memAccessToken ??= await _storage.read(key: _accessKey);
    return _memAccessToken;
  }
  Future<String?> getRefreshToken() async => _memRefreshToken ?? await _storage.read(key: _refreshKey);

  Future<void> clear() async {
    _memAccessToken = null;
    _memRefreshToken = null;
    _memUsuario = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _usuarioKey);
  }
}
