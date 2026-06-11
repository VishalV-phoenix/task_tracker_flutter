// =============================================
// build.gradle.kts - Kotlin DSL syntax
// This is the Android app build configuration
// =============================================

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin - must come after android plugin
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.example.task_tracker_flutter"

    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.task_tracker_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ── REQUIRED for coreLibraryDesugaring ──
    // Provides Java 8+ APIs on older Android devices
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
