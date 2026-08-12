import Flutter
import UIKit
import UserNotifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Guardado aquí porque solo existe como parámetro local dentro de
  // application(_:didFinishLaunchingWithOptions:) — didInitializeImplicitFlutterEngine
  // se ejecuta después, como método distinto, y necesita este mismo diccionario para
  // republicar la notificación con su userInfo original (ver más abajo).
  private var launchOptionsOriginal: [UIApplication.LaunchOptionsKey: Any]?

  // Notificación (userInfo) que el usuario tocó para abrir la app desde cerrada,
  // capturada en userNotificationCenter(_:didReceive:) más abajo. Estática porque
  // didInitializeImplicitFlutterEngine necesita leerla después, y ese método no
  // tiene acceso directo a la instancia que recibió el toque real.
  static var notificacionInicialCapturada: [AnyHashable: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Primerísima línea, antes que GMSServices o cualquier otra cosa: es la única
    // forma de capturar el toque de una notificación que abre la app desde cerrada
    // ANTES de que exista ninguna carrera con el registro tardío de firebase_messaging
    // como delegate (ver comentario largo en didInitializeImplicitFlutterEngine sobre
    // ese mismo problema, aplicado aquí a una segunda condición interna de Firebase
    // que el fix de esa función no llega a cubrir). No sustituye ni reemplaza a
    // firebase_messaging: FlutterAppDelegate (nuestra superclase) ya reenvía estas
    // llamadas a self.lifeCycleDelegate, que es como el plugin de Firebase sigue
    // recibiéndolas normalmente una vez registrado — ver userNotificationCenter(_:didReceive:)
    // más abajo, que reenvía con super en vez de sustituir ese camino.
    UNUserNotificationCenter.current().delegate = self
    GMSServices.provideAPIKey("AIzaSyArgdKzwZ1nRnqx9Ju8AiUyPpy-YwWXJMU")
    launchOptionsOriginal = launchOptions
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Se ejecuta tanto si el usuario tocó la notificación con la app cerrada (arranque
  // en frío) como en segundo plano — en ambos casos guardamos el userInfo (solo lo
  // consume el canal nativo de más abajo si de verdad hubo un arranque en frío, ver
  // deep_link_listener.dart). Reenviar con super (en vez de llamar completionHandler
  // nosotros mismos) es lo que preserva intacto el camino ya existente hacia
  // firebase_messaging (FlutterAppDelegate → lifeCycleDelegate → FLTFirebaseMessagingPlugin,
  // que es quien de verdad debe llamar completionHandler): verificado leyendo el
  // código fuente real de FlutterAppDelegate.mm y FLTFirebaseMessagingPlugin.m que
  // ese es el único camino por el que hoy funciona onMessageOpenedApp en segundo
  // plano — llamar completionHandler aquí también lo habría roto para siempre.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    AppDelegate.notificacionInicialCapturada = response.notification.request.content.userInfo
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Único consumidor de notificacionInicialCapturada: deep_link_listener.dart la
    // pide una sola vez al arrancar, además de (no en vez de) getInitialMessage() de
    // firebase_messaging — ver comentario largo de userNotificationCenter(_:didReceive:)
    // arriba sobre por qué ese camino puede no ver el toque de arranque en frío.
    // Se limpia tras leerla para no reexponerla en un hot restart dentro del mismo
    // proceso (no aplicable a un toque de segundo plano real: ese siempre llega
    // después de que Dart ya haya preguntado una vez, así que no se pierde nada).
    let canalNotificacionInicial = FlutterMethodChannel(
      name: "es.hogarsos.app/initial_notification",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canalNotificacionInicial.setMethodCallHandler { call, result in
      guard call.method == "getInitialNotification" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(AppDelegate.notificacionInicialCapturada)
      AppDelegate.notificacionInicialCapturada = nil
    }

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
    // por proceso. Desde que UNUserNotificationCenter.current().delegate = self se
    // asigna arriba (ver application(_:didFinishLaunchingWithOptions:)), Firebase
    // (FLTFirebaseMessagingPlugin) ya no se autoasigna ese delegate — en vez de eso
    // se registra como application delegate (addApplicationDelegate:) y recibe los
    // toques de notificación reenviados por FlutterAppDelegate/lifeCycleDelegate,
    // igual que cualquier otro plugin. Verificado leyendo su código fuente real
    // (application_onDidFinishLaunchingNotification:): no altera nada de lo que
    // arregla este repost, que sigue haciendo falta igual para el registro a tiempo
    // de plugins y el primer plano.
    //
    // userInfo: launchOptionsOriginal — sin esto, getInitialMessage() en Dart
    // devolvía siempre null cuando la app se abría en frío tocando una
    // notificación push. Motivo confirmado leyendo el código fuente real de
    // firebase_messaging (FLTFirebaseMessagingPlugin.m,
    // application_onDidFinishLaunchingNotification:): su observador de ESTA
    // misma notificación lee notification.userInfo[UIApplicationLaunchOptionsRemoteNotificationKey]
    // para reconstruir el mensaje inicial — es la misma clave que ya trae el
    // launchOptions real de arriba cuando el lanzamiento fue por una
    // notificación. Sin pasar userInfo aquí (como antes), esa clave nunca
    // estaba disponible cuando el observador por fin llegaba a verla (tarde,
    // que es exactamente el problema que este método ya arregla para el resto
    // del arranque). No afecta al caso de notificación en primer plano/app ya
    // abierta: ese camino no pasa por getInitialMessage() ni por esta rama de
    // application_onDidFinishLaunchingNotification:, solo por la asignación de
    // delegate que ya ocurre igual, sea cual sea el userInfo.
    NotificationCenter.default.post(
      name: UIApplication.didFinishLaunchingNotification,
      object: UIApplication.shared,
      userInfo: launchOptionsOriginal
    )
  }
}
