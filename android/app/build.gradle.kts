import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: the SAME keystore the Kotlin Claro Pulse app was signed with
// (C:/Users/jenac/keystores/claro-pulse-release.jks, alias claro-pulse). Play only accepts this
// Flutter app as an update to the existing listing, and phones only upgrade in place, when it is
// signed with that key. android/key.properties (git-ignored) first, then the environment, under
// the Kotlin app's own variable names so CI can reuse them. Never commit the keystore or passwords.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun signingValue(propKey: String, envKey: String): String? =
    keyProperties.getProperty(propKey) ?: System.getenv(envKey)

val releaseStoreFile: String? = signingValue("storeFile", "RELEASE_KEYSTORE_PATH")
val releaseStorePassword: String? = signingValue("storePassword", "RELEASE_KEYSTORE_PASSWORD")
val releaseKeyAlias: String? = signingValue("keyAlias", "RELEASE_KEY_ALIAS")
val releaseKeyPassword: String? = signingValue("keyPassword", "RELEASE_KEY_PASSWORD")
val hasReleaseSigning: Boolean = releaseStoreFile != null && file(releaseStoreFile).exists() &&
    releaseStorePassword != null && releaseKeyAlias != null && releaseKeyPassword != null

android {
    namespace = "in.claroenergy.claropulse"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "in.claroenergy.claropulse"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Unsigned rather than debug-signed when the key is missing, same as the Kotlin app:
            // a debug-signed build installs on a test phone and then can never be upgraded by a
            // real release. build-release-aab.ps1 refuses to build without the key.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
        }
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
