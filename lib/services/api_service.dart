import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_storage.dart';

/// Cliente HTTP central hacia la API de hogarSOS (Node.js).
///
/// Añade el JWT automáticamente a cada petición autenticada y, si una
/// petición falla por token expirado (401), intenta refrescarlo una vez
/// con el refresh token guardado antes de reintentar — así las pantallas
/// no necesitan preocuparse por la expiración del access token (15 min).
class ApiService {
  ApiService._internal() {
    debugPrint('[ApiService] baseUrl = $_baseUrl');
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Log completo del error real — esto es lo que hay que mirar
          // en la consola de `flutter run` cuando algo falla "sin razón".
          debugPrint(
            '[ApiService] Error en ${error.requestOptions.method} '
            '${error.requestOptions.path}: ${error.type} — ${error.message}'
            '${error.response != null ? ' | respuesta: ${error.response?.data}' : ''}',
          );

          final esNoAutorizado = error.response?.statusCode == 401;
          final yaReintentado = error.requestOptions.extra['reintentado'] == true;

          if (esNoAutorizado && !yaReintentado) {
            final refrescado = await intentarRefrescarToken();
            if (refrescado) {
              final opcionesReintento = error.requestOptions;
              opcionesReintento.extra['reintentado'] = true;
              final nuevoToken = await TokenStorage.instance.getAccessToken();
              opcionesReintento.headers['Authorization'] = 'Bearer $nuevoToken';

              try {
                final respuesta = await _dio.fetch(opcionesReintento);
                return handler.resolve(respuesta);
              } catch (_) {
                // Si el reintento también falla, se propaga el error original.
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._internal();

  /// URL base del backend.
  ///
  /// El valor por defecto DEBE ser el backend real desplegado en Render
  /// — así cualquier build sin --dart-define explícito (incluida la APK
  /// que se reparte a los beta testers) funciona desde cualquier móvil
  /// con internet, sin depender de que esté en la misma red WiFi que el
  /// ordenador de desarrollo. Antes apuntaba a una IP de red local
  /// (192.168.1.134) que solo era alcanzable desde esa red concreta —
  /// cualquier APK compilada sin pasar la variable a mano fallaba con
  /// error de conexión para cualquier usuario fuera de esa WiFi.
  ///
  /// Para desarrollo local, sobreescribe explícitamente:
  ///   - Emulador Android:  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
  ///   - Simulador iOS:     --dart-define=API_BASE_URL=http://localhost:3000/api
  ///   - Móvil físico:      --dart-define=API_BASE_URL=http://TU_IP_LOCAL:3000/api
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hogarsos-backend.onrender.com/api',
  );

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      // Sin receiveTimeout/sendTimeout, una respuesta que nunca llega
      // (backend colgado, no solo lento) deja el spinner girando sin
      // límite en vez de fallar con un error recuperable. 60s en
      // receive porque el backend está en el plan gratuito de Render y
      // el cold start tras inactividad puede tardar ~50s (ver
      // dev_environment notes) — un timeout más corto convertiría ese
      // caso ya conocido en un error falso en vez de solo lento.
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  Dio get client => _dio;

  /// Público a propósito: auth_service.dart lo reutiliza para restaurar
  /// la sesión al arrancar en frío, en vez de duplicar esta lógica de
  /// llamada al endpoint de refresh.
  ///
  /// Solo borra los tokens guardados cuando el SERVIDOR rechaza
  /// explícitamente el refresh token (401/403 — está caducado o
  /// revocado). Ante un error de conexión (sin red, timeout, backend
  /// caído, `adb reverse` desconectado) se preserva la sesión guardada
  /// y se devuelve false sin más: antes cualquier fallo de red aquí
  /// borraba la sesión, así que reabrir la app sin conexión momentánea
  /// mandaba al login aunque el refresh token siguiera siendo válido.
  Future<bool> intentarRefrescarToken() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Dio "limpio" sin interceptor, para evitar recursión infinita.
      final respuesta = await Dio(BaseOptions(baseUrl: _dio.options.baseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final nuevoAccessToken = respuesta.data['accessToken'] as String;
      await TokenStorage.instance.saveAccessToken(nuevoAccessToken);
      return true;
    } on DioException catch (e) {
      debugPrint('[ApiService] Fallo al refrescar token: ${e.type} — ${e.message}');
      final rechazadoPorServidor = e.response?.statusCode == 401 || e.response?.statusCode == 403;
      if (rechazadoPorServidor) {
        await TokenStorage.instance.clear();
      }
      return false;
    } catch (e) {
      debugPrint('[ApiService] Error inesperado al refrescar token: $e');
      return false;
    }
  }
}