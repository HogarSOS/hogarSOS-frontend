import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
/// iOS es un caso aparte: durante meses `FirebaseMessaging.onMessage`
/// nunca se disparaba con la app en primer plano. La causa real,
/// rastreada con un diagnóstico de timestamps en dispositivo real: con
/// el ciclo de vida Scene + engine implícito de esta app, el registro
/// de plugins (`GeneratedPluginRegistrant.register`) se ejecuta
/// DESPUÉS de que `UIApplicationDidFinishLaunchingNotification` ya se
/// disparó, así que `firebase_messaging` nunca llegaba a tiempo para
/// verla — y sin verla, nunca se autoasignaba como
/// `UNUserNotificationCenterDelegate` ni se unía al fan-out de plugins
/// de Flutter. El fix vive en `AppDelegate.swift`: se vuelve a publicar
/// esa misma notificación justo después de registrar los plugins, una
/// única vez. Con eso, Firebase ya presenta la notificación nativa por
/// su cuenta (`setForegroundNotificationPresentationOptions` más abajo,
/// con todo en `true`). `.show()` de flutter_local_notifications se
/// queda solo para Android (ver más abajo), que nunca tuvo este problema.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _notificacionesLocales = FlutterLocalNotificationsPlugin();
  bool _listenerConfigurado = false;
  StreamSubscription<String>? _tokenRefreshSub;

  // Un mensaje que el usuario pulsó para abrir la app (segundo plano) o
  // con el que la abrió desde cerrada — quien escuche este stream (ver
  // DeepLinkListener) decide a qué pantalla navegar según `data['tipo']`.
  // Broadcast porque puede no haber ningún listener todavía cuando
  // llega el primero (getInitialMessage se comprueba antes de que
  // DeepLinkListener termine de suscribirse).
  final _aperturasController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get aperturasPorNotificacion => _aperturasController.stream;

  // Solo iOS: canal propio a AppDelegate.swift (ver userNotificationCenter(_:didReceive:)
  // allí) para el toque de notificación que abrió la app desde cerrada. Necesario
  // porque getInitialMessage() de firebase_messaging puede devolver null en ese
  // caso concreto — el plugin nativo se registra como UNUserNotificationCenterDelegate
  // demasiado tarde para ver el toque de arranque en frío (carrera confirmada
  // leyendo su código fuente real, ver memoria del proyecto). Complementa a
  // comprobarMensajeInicial(), no lo sustituye.
  static const _canalNotificacionInicial = MethodChannel('es.hogarsos.app/initial_notification');

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

    // Independiente del permiso que se pida más abajo: Android necesita
    // el canal de notificaciones creado desde el primer arranque, tenga
    // o no permiso concedido todavía.
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

      // Con el timing de registro de plugins corregido en AppDelegate.swift
      // (ver comentario de clase), esto ya es lo que controla si iOS enseña
      // la notificación nativa con la app en primer plano.
      try {
        await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint('[NotificationService] setForegroundNotificationPresentationOptions falló: $e');
      }

      // Si Firebase rota el token más adelante (la app sigue abierta),
      // se vuelve a mandar sin esperar al próximo arranque. registrarToken()
      // se llama en cada login/registro/restauración de sesión — sin
      // cancelar la suscripción anterior, cada ciclo de sesión dentro del
      // mismo proceso (logout + login de nuevo) apilaba un listener más,
      // duplicando el PATCH en la siguiente rotación de token.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((nuevoToken) async {
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
    // onDidReceiveNotificationResponse: sin esto, tocar una notificación
    // mostrada por este plugin (solo pasa en Android con la app en
    // primer plano, ver el guard de plataforma más abajo) no hacía
    // absolutamente nada — ni ejecutaba código Dart ni navegaba a
    // ningún sitio, porque este plugin es independiente de FCM y
    // onMessageOpenedApp (más abajo) solo se dispara para
    // notificaciones que el propio sistema operativo entrega y
    // presenta, no para estas mostradas "a mano". Confirmado en real:
    // profesional con la app abierta, notificación de "te han
    // elegido" mostrada encima, tocarla no navegaba ni cambiaba de
    // pestaña.
    await _notificacionesLocales.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _alTocarNotificacionLocal,
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
          // El payload es lo único que _alTocarNotificacionLocal tiene
          // para reconstruir el RemoteMessage al tocarla — sin esto no
          // habría forma de saber a qué solicitud/tipo navegar.
          payload: jsonEncode(mensaje.data),
        );
      } catch (e) {
        debugPrint('[NotificationService] Error al mostrar notificación local: $e');
      }
    });

    // Notificación pulsada con la app en segundo plano (no cerrada del
    // todo) — vuelca al mismo stream que getInitialMessage() más abajo,
    // para que DeepLinkListener tenga un único sitio donde enrutar.
    FirebaseMessaging.onMessageOpenedApp.listen((mensaje) {
      _aperturasController.add(mensaje);
    });
  }

  // Solo se dispara para notificaciones mostradas por este plugin (ver
  // guard de Android en el listener de onMessage más arriba) — vuelca
  // al mismo stream que el resto de vías de apertura para que
  // DeepLinkListener siga siendo el único sitio que decide a dónde
  // navegar.
  void _alTocarNotificacionLocal(NotificationResponse respuesta) {
    final payload = respuesta.payload;
    debugPrint('[NotificationService] Notificación local tocada, payload=$payload');
    if (payload == null) return;
    try {
      final data = (jsonDecode(payload) as Map).map((clave, valor) => MapEntry(clave.toString(), valor.toString()));
      _aperturasController.add(RemoteMessage(data: data));
    } catch (e) {
      debugPrint('[NotificationService] Error al parsear el payload de la notificación local: $e');
    }
  }

  /// Comprueba si la app se abrió desde cero (proceso nuevo) pulsando una
  /// notificación — a diferencia de onMessageOpenedApp de arriba, esto NO
  /// es un stream: FCM solo devuelve un resultado no nulo la primera vez
  /// que se pregunta tras ese arranque concreto. Llamar una sola vez al
  /// arrancar (ver DeepLinkListener._iniciar), igual que ya se hace con
  /// AppLinks.getInitialLink() para el deep link de Stripe.
  Future<void> comprobarMensajeInicial() async {
    try {
      final mensaje = await _messaging.getInitialMessage();
      if (mensaje != null) _aperturasController.add(mensaje);
    } catch (e) {
      debugPrint('[NotificationService] Error leyendo el mensaje inicial: $e');
    }
  }

  /// Complementa a comprobarMensajeInicial() en iOS: pregunta al canal nativo
  /// propio (ver _canalNotificacionInicial) por el toque de notificación
  /// capturado directamente en AppDelegate.swift, para el caso de arranque en
  /// frío que getInitialMessage() puede no ver. El `data` que llega aquí es el
  /// userInfo crudo de APNs (incluye claves como "aps" además de los campos
  /// propios del backend) — DeepLinkListener solo lee 'solicitudId' y 'tipo',
  /// así que las claves de más no afectan.
  Future<void> comprobarNotificacionInicialNativa() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final userInfo = await _canalNotificacionInicial.invokeMapMethod<Object?, Object?>(
        'getInitialNotification',
      );
      if (userInfo == null) return;

      final data = userInfo.map((clave, valor) => MapEntry(clave.toString(), valor));
      final messageId = data['gcm.message_id'] as String?;
      _aperturasController.add(RemoteMessage(data: data, messageId: messageId));
    } catch (e) {
      debugPrint('[NotificationService] Error leyendo la notificación inicial nativa (iOS): $e');
    }
  }
}
