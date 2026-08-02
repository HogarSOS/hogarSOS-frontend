import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Notificaciones push (FCM). Pide permiso, registra el token del
/// dispositivo en el backend y muestra la notificación cuando llega
/// con la app en primer plano.
///
/// Android ya enseña solo las notificaciones en segundo plano/app
/// cerrada, vía el canal por defecto declarado en AndroidManifest.xml
/// — pero NO en primer plano, ahí depende 100% de la app. Antes esto
/// solo hacía un debugPrint en ese caso: el mensaje llegaba de verdad
/// (el envío desde el backend funcionaba) pero era invisible para
/// cualquiera que probara con la app abierta, que es el escenario más
/// habitual al testear. flutter_local_notifications muestra la misma
/// notificación de forma manual, en el mismo canal
/// ("hogarsos_notifications") que ya usa el caso en segundo plano, para
/// que se vea y suene igual en ambos casos.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _notificacionesLocales = FlutterLocalNotificationsPlugin();
  bool _listenerConfigurado = false;

  static const _canal = AndroidNotificationChannel(
    'hogarsos_notifications',
    'hogarSOS',
    description: 'Solicitudes, mensajes y pagos de hogarSOS',
    importance: Importance.high,
  );

  /// Llamar tras un login/registro exitoso y tras restaurar sesión al
  /// arrancar — el token de FCM puede rotar en cualquier momento, así
  /// que conviene re-registrarlo en cada arranque con sesión activa,
  /// no solo la primera vez.
  Future<void> registrarToken() async {
    // Independiente del permiso de notificaciones: aunque el usuario
    // lo deniegue ahora, el idioma queda guardado para el día que lo
    // active desde los ajustes del sistema. Mismo endpoint-por-arranque
    // que el token FCM (ver PATCH /auth/me/fcm-token más abajo) — la
    // app no tiene selector de idioma propio, sigue el locale resuelto
    // por MaterialApp (ver main.dart), que a su vez sigue el idioma
    // del sistema operativo.
    unawaited(_registrarIdioma());

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

      await _configurarListeners();

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

  /// Mismo idioma que resuelve MaterialApp en main.dart: de los dos
  /// soportados (es/en), 'en' solo si el idioma del sistema es
  /// inglés, 'es' en cualquier otro caso (incluido el propio 'es') —
  /// replica la resolución por defecto de Flutter con
  /// supportedLocales: [Locale('es'), Locale('en')].
  Future<void> _registrarIdioma() async {
    try {
      final idioma = ui.PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'es';
      await ApiService.instance.client.patch('/auth/me/idioma', data: {'idioma': idioma});
    } catch (e) {
      debugPrint('[NotificationService] Error al registrar el idioma: $e');
    }
  }

  Future<void> _configurarListeners() async {
    if (_listenerConfigurado) return;
    _listenerConfigurado = true;

    await _notificacionesLocales.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    await _notificacionesLocales
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    // Mensaje recibido con la app en primer plano — FCM no lo enseña
    // solo en este caso (comportamiento estándar de Android/iOS), hay
    // que mostrarlo a mano.
    FirebaseMessaging.onMessage.listen((mensaje) {
      final notificacion = mensaje.notification;
      debugPrint('[NotificationService] Mensaje en primer plano: ${notificacion?.title}');
      if (notificacion == null) return;

      _notificacionesLocales.show(
        mensaje.hashCode,
        notificacion.title,
        notificacion.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _canal.id,
            _canal.name,
            channelDescription: _canal.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}
