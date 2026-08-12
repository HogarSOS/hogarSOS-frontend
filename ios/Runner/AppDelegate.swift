import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyArgdKzwZ1nRnqx9Ju8AiUyPpy-YwWXJMU")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Bug de meses: en iOS, con la app en primer plano, FirebaseMessaging.onMessage
    // nunca llegaba a dispararse en Dart. Causa real, confirmada con diagnóstico real
    // en dispositivo (timestamps exactos: la notificación de arranque de iOS se
    // disparaba 108ms ANTES de que este método se ejecutara — ver memoria del
    // proyecto): con el ciclo de vida Scene + engine implícito que usa esta app, este
    // método (que dispara el registro de plugins, incluido firebase_messaging) se
    // ejecuta DESPUÉS de que UIApplicationDidFinishLaunchingNotification ya se
    // disparó. firebase_messaging registra su propio observador de esa notificación
    // dentro de su registerWithRegistrar: (llamado justo arriba, confirmado leyendo
    // su código fuente real) — llegando tarde nunca la ve, así que nunca ejecuta su
    // lógica de asignarse como UNUserNotificationCenterDelegate ni se añade al
    // fan-out de plugins de Flutter (addApplicationDelegate:).
    //
    // El fix: volver a publicar la misma notificación aquí, ahora que el observador
    // de Firebase ya existe — la recibe y hace exactamente lo que habría hecho si
    // hubiera llegado a tiempo la primera vez (incluida su propia llamada a
    // registerForRemoteNotifications, no hace falta duplicarla nosotros). Publicarla
    // más de una vez SÍ es peligroso (el propio código de Firebase advierte de un
    // bucle de reenvío infinito si su lógica de delegate se ejecuta dos veces), así
    // que esto debe ocurrir EXACTAMENTE UNA VEZ — este método solo se llama una vez
    // por proceso, y ya no hay ninguna asignación manual de
    // UNUserNotificationCenter.current().delegate en este archivo: con el timing
    // corregido, Firebase se autoasigna el delegate directamente con su propio
    // código ya probado, sin depender de que FlutterAppDelegate reenvíe llamadas.
    NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: UIApplication.shared)
  }
}
