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

    // DIAGNÓSTICO TEMPORAL — experimento único para averiguar si
    // firebase_messaging llega a tiempo de ver esta notificación. Ese
    // plugin registra su propio observador de
    // UIApplicationDidFinishLaunchingNotification dentro de su
    // registerWithRegistrar: (confirmado leyendo su código fuente), que
    // solo se ejecuta cuando GeneratedPluginRegistrant.register corre en
    // didInitializeImplicitFlutterEngine más abajo. Con el ciclo de vida
    // Scene que usa esta app (ver SceneDelegate.swift), el engine
    // implícito se crea en scene(_:willConnectTo:options:), que Apple
    // documenta que ocurre DESPUÉS de que esta notificación se dispare.
    // Si diag_notif_fired_at < diag_engine_init_at, firebase_messaging
    // nunca ve la notificación y por tanto nunca ejecuta su lógica de
    // delegate ni se añade al fan-out de Flutter — explicaría por qué el
    // fix del delegate de la línea de arriba no ha cambiado nada en 3
    // builds. Quitar todo el bloque de diagnóstico (aquí y en
    // didInitializeImplicitFlutterEngine) en cuanto se confirme o
    // descarte esta hipótesis.
    let diagDefaults = UserDefaults.standard
    diagDefaults.removeObject(forKey: "diag_notif_fired_at")
    diagDefaults.removeObject(forKey: "diag_engine_init_at")
    NotificationCenter.default.addObserver(
      forName: UIApplication.didFinishLaunchingNotification,
      object: nil,
      queue: nil
    ) { _ in
      UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "diag_notif_fired_at")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // DIAGNÓSTICO TEMPORAL — ver comentario en didFinishLaunchingWithOptions.
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "diag_engine_init_at")
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DiagnosticoArranque") {
      let canal = FlutterMethodChannel(
        name: "hogarsos/diagnostico_arranque",
        binaryMessenger: registrar.messenger()
      )
      canal.setMethodCallHandler { _, result in
        let defaults = UserDefaults.standard
        let delegateActual = UNUserNotificationCenter.current().delegate
        let delegateDesc = delegateActual != nil ? String(describing: type(of: delegateActual!)) : "nil"
        result([
          "notifFiredAt": defaults.double(forKey: "diag_notif_fired_at"),
          "engineInitAt": defaults.double(forKey: "diag_engine_init_at"),
          "delegateClass": delegateDesc,
        ] as [String: Any])
      }
    }

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
