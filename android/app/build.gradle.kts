import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Local upload-key material is never committed. No debug-key release fallback.
val uploadPropertiesFile = rootProject.file("key.properties")
val uploadProperties = Properties().apply {
    if (uploadPropertiesFile.exists()) uploadPropertiesFile.inputStream().use { load(it) }
}

android {
    namespace = "com.legendstudy.app"
    compileSdk = flutter.compileSdkVersion
    // Required by the Supabase transitive native plugins.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Owner-approved production identity; signing and store setup are separate.
        applicationId = "com.legendstudy.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadPropertiesFile.exists()) {
            create("release") {
                fun required(name: String): String = requireNotNull(uploadProperties.getProperty(name)) {
                    "Missing upload signing property: $name"
                }
                storeFile = rootProject.file(required("storeFile"))
                storePassword = required("storePassword")
                keyAlias = required("keyAlias")
                keyPassword = required("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (uploadPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

// JVM tests cover owned activation lease decisions; OS DND still needs a device.
dependencies { testImplementation("junit:junit:4.12") }
