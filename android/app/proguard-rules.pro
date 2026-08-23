# La app no usa la funcion de "push provisioning" de Stripe (anadir
# tarjeta a Google Pay directamente desde la app) - solo el Payment
# Sheet para cobrar. Esas clases no estan presentes en el SDK incluido
# y R8 falla el build si no se le dice explicitamente que las ignore.
# Reglas generadas por el propio Android Gradle Plugin en
# build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Firebase descubre sus componentes instanciando por REFLEXION los
# *Registrar declarados en el manifest (ComponentDiscovery). R8 no ve
# ninguna referencia estatica a esos constructores y los elimina; en el
# build 41 eso dejo a CrashlyticsRegistrar sin <init>() y el arranque
# murio en setCrashlyticsCollectionEnabled con "FirebaseCrashlytics
# component is not present" ANTES de runApp (splash infinito, causa
# raiz confirmada en logcat el 2026-08-23). La regla conserva SOLO el
# constructor vacio de las clases que implementan ComponentRegistrar
# (tambien arregla los KtxRegistrar de messaging/installations, que ya
# fallaban en silencio) - sin keeps indiscriminados de Firebase y sin
# tocar el resto del shrinking.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
