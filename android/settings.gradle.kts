pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// AGP 8 / Kotlin 2.2, NOT the AGP 9.1.0 + Kotlin 2.4.0 that `flutter create`
// wrote here. This is a downgrade on purpose, and the reason is a dependency,
// not a preference.
//
// `flutter_tesseract_ocr` 0.4.31 — the only published binding that ships
// prebuilt libtesseract for Android and iOS, which is why pubspec.yaml picks
// it — carries an AGP-7-era `android/build.gradle`:
//
//     buildscript { repositories { google(); jcenter() } ... }
//     android { compileSdkVersion 34 ... lintOptions { ... } }
//
// Every one of those three is gone in the Gradle 9 / AGP 9 generation. The
// fatal one is `jcenter()`: Gradle removed the method in 9.0, so the plugin's
// build script cannot even be *evaluated* under the template's Gradle 9.3.1 —
// the build dies during configuration with
//
//     Could not find method jcenter() for arguments [] on repository container
//
// before a single source file is compiled. Verified by running both wrappers
// against a two-line script: Gradle 9.3.1 fails as above, Gradle 8.14.3
// accepts it (deprecated, still present). `compileSdkVersion` and
// `lintOptions` are the same story one layer down — AGP 8 deprecates them,
// AGP 9 removes them — and `flutter_local_notifications` 22.3.0 uses
// `lintOptions` too, so this is not one unlucky package.
//
// We cannot fix the plugin (it is a pub.dev release, and 0.4.31 is its
// latest), so the app's toolchain moves to meet it. Both versions sit inside
// the window Flutter 3.47.3's own DependencyVersionChecker accepts — its hard
// error floors are AGP 8.11.1, Kotlin 2.2.20 and Gradle 8.14.0, so this
// configuration warns that newer exists and builds. They are also the
// versions the first-party plugins in this app already pin in their own
// buildscripts (`camera_android_camerax` and `image_picker_android` both name
// AGP 8.13.1), which is the ecosystem saying the same thing.
//
// Un-downgrade this the day `flutter_tesseract_ocr` publishes an AGP 8+
// build file — not before, and check `gradle-wrapper.properties` and
// `gradle.properties` in the same change; the three move together.
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
