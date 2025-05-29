plugins {
    id("com.android.application")
    id("kotlin-android")
    // Il plugin Flutter va applicato dopo quelli Android/Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pool_app"

    /* ---------- VERSIONI SDK ---------- */
    compileSdk = flutter.compileSdkVersion        // fornito dal plugin Flutter
    ndkVersion = "27.0.12077973"                  // NDK richiesto dai plugin Firebase

    defaultConfig {
        applicationId = "com.example.pool_app"

        // Alza la minSdk a 23 (per Firebase) con sintassi Kotlin DSL
        minSdk = 23
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    /* ---------- OPZIONI JAVA/KOTLIN ---------- */
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }

    /* ---------- BUILD TYPES ---------- */
    buildTypes {
        release {
            // Per ora firmiamo con la chiave debug (cambia in futuro)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."   // percorso al progetto Flutter
}
