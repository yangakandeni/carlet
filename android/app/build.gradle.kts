plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    // Note: Google Services plugin must be applied after the Flutter plugin.
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load local.properties to access API keys
import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

// Load signing configuration from key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.techolosh.carletdev"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID set by flavor - see flavorDimensions below
        // Dev: com.techolosh.carletdev
        // Prod: com.techolosh.carlet
        
        minSdk = 27
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Read Maps API Key from local.properties (not committed to git)
        val mapsApiKey = localProperties.getProperty("MAPS_API_KEY", "")
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }
    
    flavorDimensions += "environment"
    
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.techolosh.carletdev"
            resValue("string", "app_name", "Carlet (Dev)")
        }
        
        create("prod") {
            dimension = "environment"
            applicationId = "com.techolosh.carlet"
            resValue("string", "app_name", "Carlet")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Only use release signing config if key.properties exists
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Apply Google Services plugin after the Flutter Gradle plugin to ensure proper ordering
apply(plugin = "com.google.gms.google-services")

// When product flavors exist, Gradle produces flavor-specific APK names
// (e.g. app-dev-debug.apk). The Flutter tool expects `app-debug.apk` when no
// flavor is provided. Create a small task to copy the most likely debug APK
// to `app-debug.apk` so `flutter run` without `--flavor` works during development.
val copyDebugApk = tasks.register("copyDebugApk") {
    doLast {
        val outputsDir = file("$buildDir/outputs/flutter-apk")
        val devApk = file("${outputsDir.path}/app-dev-debug.apk")
        val prodApk = file("${outputsDir.path}/app-prod-debug.apk")
        val target = file("${outputsDir.path}/app-debug.apk")
        if (devApk.exists()) {
            devApk.copyTo(target, overwrite = true)
        } else if (prodApk.exists()) {
            prodApk.copyTo(target, overwrite = true)
        }
    }
}

// Attach the copy task to any assemble*Debug task (flavored or unflavored)
tasks.matching { it.name.startsWith("assemble") && it.name.endsWith("Debug") }.all {
    finalizedBy(copyDebugApk)
}
