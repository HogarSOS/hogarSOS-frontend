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
