import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_keys.dart';
import 'api_service.dart';

/// Notificaciones push (FCM). Pide permiso, registra el token del
/// dispositivo en el backend y muestra la notificación cuando llega
/// con la app en primer plano.
///
/// Ni Android ni iOS enseñan la notificación del sistema con la app en
/// primer plano por defecto — en ambos casos depende 100% de la app.
/// flutter_local_notifications la muestra de forma manual en los dos
/// casos, en el mismo canal ("hogarsos_notifications") que ya usa el
/// caso en segundo plano/app cerrada, para que se vea y suene igual
/// siempre.
///
/// En iOS se probó primero `setForegroundNotificationPresentationOptions`
/// (dejar que el propio sistema presente la notificación nativa) pero
/// resultó nada fiable en la práctica: confirmado en dispositivo real
/// que solo actualizaba el badge, sin alerta ni sonido. Se dejó
/// desactivada (`alert: false, sound: false` en `registrarToken`) y se
/// pasó al mismo patrón manual que ya usaba Android.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _notificacionesLocales = FlutterLocalNotificationsPlugin();
  bool _listenerConfigurado = false;

  static const _canal = AndroidNotificationChannel(
    'hogarsos_notifications',
    'Hogar SOS',
    description: 'Solicitudes, mensajes y pagos de Hogar SOS',
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

      // Solo en iOS: pedir el token de FCM demasiado pronto falla en
      // silencio (excepción "apns-token-not-set") — iOS tarda un
      // momento en registrar el token nativo de APNs de forma asíncrona
      // tras conceder el permiso, y FCM lo necesita antes de poder
      // emitir el suyo. Android no tiene este paso intermedio.
      //
      // Esperar a getAPNSToken() por sí solo NO fue suficiente en la
      // práctica (probado en dispositivo real, build 5: el token seguía
      // sin registrarse pese al permiso concedido y la app reabierta) —
      // getToken() en sí puede seguir fallando varias veces justo
      // después de que getAPNSToken() ya devuelva algo, así que ahora
      // se reintenta la llamada completa (no solo la espera previa),
      // capturando cada fallo individual en vez de dejar que uno solo
      // aborte todo el registro.
      String? token;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var intento = 0; intento < 6 && token == null; intento++) {
          if (intento > 0) await Future.delayed(const Duration(seconds: 2));
          try {
            token = await _messaging.getToken();
          } catch (e) {
            debugPrint('[NotificationService] getToken() falló en iOS (intento $intento): $e');
          }
        }
      } else {
        token = await _messaging.getToken();
      }
      if (token == null) return;

      await ApiService.instance.client.patch('/auth/me/fcm-token', data: {'fcmToken': token});
      debugPrint('[NotificationService] Token FCM registrado');

      // Deliberadamente todo en false salvo el badge: dejar que iOS
      // presente la notificación nativa en primer plano resultó nada
      // fiable en la práctica (confirmado en dispositivo real: solo se
      // actualizaba el badge, sin alerta ni sonido) — en vez de eso,
      // _configurarListeners() la muestra a mano con
      // flutter_local_notifications, igual que ya hacía Android.
      await _messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);

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
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _notificacionesLocales
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    // Mensaje recibido con la app en primer plano, en Android y en iOS
    // por igual — ninguno de los dos la enseña solo, hay que mostrarla
    // a mano en ambos casos (ver comentario de clase más arriba).
    FirebaseMessaging.onMessage.listen((mensaje) {
      final notificacion = mensaje.notification;
      debugPrint('[NotificationService] Mensaje en primer plano: ${notificacion?.title}');

      // DIAGNÓSTICO TEMPORAL — confirma si este listener llega a
      // dispararse en iOS con la app en primer plano (sin necesitar
      // consola de Xcode). Quitar en cuanto se confirme la causa real
      // del bug de sonido en primer plano (ver memoria del proyecto).
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('DEBUG onMessage: ${notificacion?.title ?? "sin notification"}')),
      );

      if (notificacion == null) return;

      try {
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
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      } catch (e) {
        debugPrint('[NotificationService] Error al mostrar notificación local: $e');
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('DEBUG error .show(): $e')),
        );
      }
    });
  }
}
