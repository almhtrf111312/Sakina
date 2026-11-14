plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sakina.app"
    compileSdk = 36

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sakina.app"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Fixed signing key (committed) so every CI build can be installed over the previous one.
    signingConfigs {
        create("sakina") {
            storeFile = file("sakina-release.jks")
            storePassword = "sakina2026"
            keyAlias = "sakina"
            keyPassword = "sakina2026"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("sakina")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
