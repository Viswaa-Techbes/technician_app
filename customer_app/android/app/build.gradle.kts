plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.techbes.customer_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.techbes.customer_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

tasks.register("copyBrandingAssets") {
    doFirst {
        val sourceFile = file("C:/Users/Viswaas-E/.gemini/antigravity-ide/brain/035171da-79e8-4e91-82c9-32f5857f77a7/media__1785338459115.png")
        if (sourceFile.exists()) {
            println("Gradle: Copying branding logo to assets and Android resources...")
            // 1. Copy to assets/logos/logo.png
            val assetLogoFile = file("../../assets/logos/logo.png")
            assetLogoFile.parentFile.mkdirs()
            sourceFile.copyTo(assetLogoFile, overwrite = true)

            // 2. Copy to Android mipmap resource directories
            val mipmapDirs = listOf(
                "src/main/res/mipmap-mdpi",
                "src/main/res/mipmap-hdpi",
                "src/main/res/mipmap-xhdpi",
                "src/main/res/mipmap-xxhdpi",
                "src/main/res/mipmap-xxxhdpi"
            )
            for (dir in mipmapDirs) {
                val destFile = file("$dir/ic_launcher.png")
                destFile.parentFile.mkdirs()
                sourceFile.copyTo(destFile, overwrite = true)
            }
        } else {
            println("Gradle: Branding logo source file does not exist at ${sourceFile.absolutePath}")
        }
    }
}

tasks.named("preBuild") {
    dependsOn("copyBrandingAssets")
}
