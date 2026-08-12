import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_keys.dart';
import 'api_service.dart';

/// Notificaciones push (FCM). Pide permiso, registra el token del
/// dispositivo en el backend y muestra la notificación cuando llega
/// con la app en primer plano.
///
/// Android no enseña la notificación del sistema con la app en primer
/// plano por defecto — flutter_local_notifications la muestra de forma
/// manual, en el mismo canal ("hogarsos_notifications") que ya usa el
/// caso en segundo plano/app cerrada, para que se vea y suene igual
/// siempre.
///
/// iOS es un caso aparte: tras varios builds de diagnóstico (vibración
/// y SnackBar en `FirebaseMessaging.onMessage`, ninguno llegó a
/// dispararse nunca en dispositivo real) se rastreó la causa hasta el
/// código fuente de `firebase_messaging` y de `FlutterAppDelegate`:
/// iOS solo permite un `UNUserNotificationCenterDelegate` activo, y
/// aunque Firebase sabe reenviar a otros plugins cuando coexiste con
/// ellos, solo lo hace si *algo* asigna ese delegate explícitamente —
/// si nadie lo hacía (nuestro caso), Firebase tomaba el delegate por
/// su cuenta con un camino de arranque distinto al esperado. El fix
/// real vive en `AppDelegate.swift` (una sola línea); aquí solo hace
/// falta volver a dejar que Firebase presente la notificación nativa
/// (`setForegroundNotificationPresentationOptions` más abajo, con todo
/// en `true`). `.show()` de flutter_local_notifications se queda solo
/// para Android (ver más abajo), que nunca tuvo este problema.
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

    // DIAGNÓSTICO TEMPORAL — se adelanta aquí, fuera del try/catch de
    // permiso+token de abajo, para descartar que un fallo silencioso en
    // algún paso anterior (denegación de permiso, timeout de getToken,
    // fallo de red en el PATCH) esté impidiendo que este listener
    // llegue a registrarse siquiera. Quitar junto con el resto del
    // diagnóstico de _configurarListeners() en cuanto se confirme la
    // causa real del bug de sonido en primer plano.
    unawaited(_configurarListeners());

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

      // Antes estaba todo en false salvo el badge, porque sin la línea
      // que falta en AppDelegate.swift (ver comentario de clase) esta
      // opción nunca llegaba a aplicarse de forma fiable. Con el
      // delegate nativo bien asignado, esto ya es lo que controla si
      // iOS enseña la notificación con la app en primer plano.
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      // DIAGNÓSTICO TEMPORAL — vibración distinta a la del listener onMessage,
      // para confirmar que esta llamada termina sin lanzar una excepción que el
      // catch general de más abajo esté tragando en silencio. Quitar junto con
      // el resto del diagnóstico en cuanto se confirme la causa real.
      HapticFeedback.mediumImpact();

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

    // Sin `iOS:` a propósito — pasar DarwinInitializationSettings hace
    // que este plugin se declare UNUserNotificationCenterDelegate, y
    // solo puede haber uno activo a la vez. Ahora ese rol lo tiene
    // AppDelegate.swift (ver comentario de clase más arriba), así que
    // aquí solo se inicializa el lado Android.
    await _notificacionesLocales.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _notificacionesLocales
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    // Mensaje recibido con la app en primer plano. Con el fix de
    // AppDelegate.swift, en iOS la presentación (banner+sonido+badge)
    // ya la hace el propio Firebase de forma nativa vía
    // setForegroundNotificationPresentationOptions — este listener ya
    // no necesita mostrar nada él mismo ahí, solo en Android (ver el
    // guard de plataforma más abajo), que nunca tuvo este problema.
    FirebaseMessaging.onMessage.listen((mensaje) {
      final notificacion = mensaje.notification;
      debugPrint('[NotificationService] Mensaje en primer plano: ${notificacion?.title}');

      // DIAGNÓSTICO TEMPORAL — dos señales independientes de si este
      // listener llega a dispararse en iOS con la app en primer plano:
      // la vibración no depende del árbol de widgets (a diferencia del
      // SnackBar de abajo), así que si esta también falla en notarse,
      // descarta que el problema sea solo de scaffoldMessengerKey.
      // Quitar todo el bloque en cuanto se confirme la causa real del
      // bug de sonido en primer plano (ver memoria del proyecto).
      HapticFeedback.heavyImpact();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('DEBUG onMessage: ${notificacion?.title ?? "sin notification"}')),
      );

      if (notificacion == null) return;

      // Solo Android: en iOS la presentación ya la hace Firebase de
      // forma nativa (ver más arriba). Llamar aquí también en iOS
      // duplicaría la notificación.
      if (defaultTargetPlatform != TargetPlatform.android) return;

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
          ),
        );
      } catch (e) {
        debugPrint('[NotificationService] Error al mostrar notificación local: $e');
      }
    });
  }
}
