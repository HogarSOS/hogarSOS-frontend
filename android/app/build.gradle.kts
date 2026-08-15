import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "es.hogarsos.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (añadido para el fix de notificaciones
        // en primer plano) exige desugaring de la librería core de Java —
        // sin esto, checkReleaseAarMetadata falla el build de release.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "es.hogarsos.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // ANTES esto caía silenciosamente a la clave de DEBUG si
            // faltaba key.properties: el build no fallaba, producía un
            // .aab firmado con el certificado de depuración, y solo te
            // enterabas al subirlo a Play Console ("You uploaded an APK
            // signed with a debug certificate"). Es el fallo que
            // descubres el día del lanzamiento.
            //
            // Ahora falla el build con un mensaje que dice exactamente
            // qué hacer. Un build de release SIN firma de release no es
            // un build de release.
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Falta android/key.properties: no se puede firmar una build de RELEASE.\n" +
                    "Sin él, Gradle caería a la clave de depuración y Google Play rechazaría el .aab.\n" +
                    "Crea android/key.properties con storeFile, storePassword, keyAlias y keyPassword.\n" +
                    "Para compilar sin firmar de verdad, usa --debug o --profile en su lugar."
                )
            }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // El modulo de "push provisioning" (anadir tarjeta a Google Pay) de
    // stripe_android depende de com.google.android.gms:play-services-tapandpay,
    // una libreria de acceso restringido de Google que no se resuelve desde
    // los repositorios publicos. La app no usa esa funcion (solo el Payment
    // Sheet), pero el "lint vital" de release intenta analizarla igualmente
    // y rompe el build al no poder descargarla. Se desactiva el lint vital
    // de release para poder compilar.
    lint {
        checkReleaseBuilds = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}