import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyArgdKzwZ1nRnqx9Ju8AiUyPpy-YwWXJMU")

    // Bug de meses: en iOS, con la app en primer plano, FirebaseMessaging.onMessage
    // nunca llegaba a dispararse en Dart (confirmado con vibración/SnackBar en varios
    // builds, ninguno se disparó nunca). Causa real, confirmada leyendo el código
    // fuente de firebase_messaging y de FlutterAppDelegate (no adivinada): iOS solo
    // permite UN UNUserNotificationCenterDelegate activo a la vez. FlutterAppDelegate
    // ya trae la lógica para reenviar las notificaciones a cada plugin que la
    // necesite (Firebase incluido, vía `addApplicationDelegate:` en su propio
    // código) — pero SOLO si algo llega a asignarlo como delegate explícitamente; si
    // nadie lo hace (nuestro caso hasta ahora), Firebase pasa a asumir que no hay
    // nadie más y toma el delegate él solo, con un camino de arranque distinto al
    // que espera cuando coexiste con otros plugins. Esta única línea activa el
    // reenvío ya integrado en Flutter — no hace falta implementar
    // `willPresent`/`didReceive` a mano.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
