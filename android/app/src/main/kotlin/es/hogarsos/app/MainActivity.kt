package es.hogarsos.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, no FlutterActivity: flutter_stripe necesita
// registrar un ActivityResultLauncher para el Payment Sheet nativo, algo
// que solo una FragmentActivity soporta — con FlutterActivity a secas,
// Stripe.instance.presentPaymentSheet() fallaba SIEMPRE con
// "flutter_stripe initialization failed" antes incluso de llegar a
// mostrar la hoja de pago (el pago nunca llegó a funcionar en ningún
// build hasta este fix, es requisito documentado de flutter_stripe).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        crearCanalNotificaciones()
    }

    // AndroidManifest.xml declara "hogarsos_notifications" como canal por
    // defecto para firebase_messaging, pero declararlo ahí NO lo crea. En
    // Android 8+ (API 26+), si el canal no existe de verdad en el
    // sistema, las notificaciones que llegan con la app en segundo plano
    // o cerrada se descartan en silencio — sin error, sin log, sin
    // crash, solo nunca aparecen. Esta era la causa real detrás de "las
    // notificaciones push no funcionan": el registro del token FCM y el
    // envío desde el backend ya funcionaban correctamente, pero no había
    // ningún canal del sistema donde mostrarlas.
    private fun crearCanalNotificaciones() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(
                "hogarsos_notifications",
                "Notificaciones de hogarSOS",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Solicitudes de servicio, mensajes y actualizaciones de trabajos"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(canal)
        }
    }
}
