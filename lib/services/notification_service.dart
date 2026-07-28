import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Notificaciones push (FCM). Deliberadamente simple en esta primera
/// versión: pide permiso, registra el token del dispositivo en el
/// backend y muestra en consola los mensajes en primer plano (Android
/// ya enseña solas las notificaciones en segundo plano/app cerrada,
/// vía el canal por defecto declarado en AndroidManifest.xml — no hace
/// falta flutter_local_notifications solo para eso).
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  bool _listenerConfigurado = false;

  /// Llamar tras un login/registro exitoso y tras restaurar sesión al
  /// arrancar — el token de FCM puede rotar en cualquier momento, así
  /// que conviene re-registrarlo en cada arranque con sesión activa,
  /// no solo la primera vez.
  Future<void> registrarToken() async {
    try {
      final permiso = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      if (permiso.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[NotificationService] Permiso de notificaciones denegado');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) return;

      await ApiService.instance.client.patch('/auth/me/fcm-token', data: {'fcmToken': token});
      debugPrint('[NotificationService] Token FCM registrado');

      _configurarListeners();

      // Si Firebase rota el token más adelante (la app sigue abierta),
      // se vuelve a mandar sin esperar al próximo arranque.
      _messaging.onTokenRefresh.listen((nuevoToken) async {
        try {
          await ApiService.instance.client.patch('/auth/me/fcm-token', data: {'fcmToken': nuevoToken});
        } catch (e) {
          debugPrint('[NotificationService] Error al refrescar token: $e');
        }
      });
    } catch (e) {
      debugPrint('[NotificationService] Error al registrar el token: $e');
    }
  }

  void _configurarListeners() {
    if (_listenerConfigurado) return;
    _listenerConfigurado = true;

    // Mensaje recibido con la app en primer plano — FCM no lo muestra
    // solo en este caso (comportamiento estándar de Android/iOS), así
    // que al menos se deja constancia en el log. Mostrar un SnackBar
    // aquí requeriría un BuildContext global; se deja como mejora
    // futura si hace falta un aviso visual también en primer plano.
    FirebaseMessaging.onMessage.listen((mensaje) {
      debugPrint('[NotificationService] Mensaje en primer plano: ${mensaje.notification?.title}');
    });
  }
}
