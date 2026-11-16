plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStore = providers.environmentVariable("ALMUADHAN_KEYSTORE_PATH").orNull
val releaseStorePassword = providers.environmentVariable("ALMUADHAN_KEYSTORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("ALMUADHAN_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("ALMUADHAN_KEY_PASSWORD").orNull
val releaseSigningAvailable = listOf(releaseStore, releaseStorePassword, releaseKeyAlias, releaseKeyPassword)
    .all { !it.isNullOrBlank() }

android {
    namespace = "com.sakina.app"
    compileSdk = 36

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.almuadhan.app"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningAvailable) {
            create("appRelease") {
                storeFile = file(checkNotNull(releaseStore))
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("appRelease")
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
