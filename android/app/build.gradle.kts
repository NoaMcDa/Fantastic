plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fantastic.fantastic"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required, not optional polish. `flutter_local_notifications` 22.3.0
        // enables core library desugaring in its own module and publishes that
        // fact in its AAR metadata, and AGP refuses to link a library that
        // desugars into an app that does not:
        //
        //     Dependency ':flutter_local_notifications' requires
        //     core library desugaring to be enabled for :app
        //
        // It is the plugin's `java.time` use behind it — the notification
        // scheduler the adaptation-streak reminder goes through. The app is
        // minSdk 24, and `java.time` only arrives in the platform at API 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fantastic.fantastic"
        // `flutter.minSdkVersion` is 24 on Flutter 3.47.3, which clears every
        // floor this app's plugins declare — the binding ones are
        // `camera_android_camerax` (23, CameraX), `image_picker_android` (24),
        // `flutter_local_notifications` (24), `flutter_plugin_android_lifecycle`
        // (24), `flutter_tesseract_ocr` (21) and `jni`/`jni_flutter` (21, which
        // is how `path_provider_android` 2.3.1 reaches the platform now that it
        // has no Android module of its own). 24 is therefore the real floor and
        // it is already the default; it is left as the Flutter constant rather
        // than hard-coded so an SDK upgrade moves it, and a plugin that outgrows
        // it fails loudly in the manifest merger rather than at run time.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // The runtime half of `isCoreLibraryDesugaringEnabled` above: without it
    // the flag is a compile-time promise with nothing behind it. 2.1.4 is the
    // version `flutter_local_notifications` itself desugars against, so the
    // app and the library agree on one backport rather than shipping two.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
