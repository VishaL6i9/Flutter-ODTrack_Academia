plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read .env file to get Firebase API Key
val envFile = file("../../.env")
var firebaseAndroidKey = "YOUR_API_KEY_HERE"
if (envFile.exists()) {
    envFile.forEachLine { line ->
        if (line.startsWith("FIREBASE_API_KEY_ANDROID=")) {
            firebaseAndroidKey = line.substringAfter("=")
        }
    }
}

// Inject key into google-services.json before build
tasks.register("injectFirebaseKey") {
    val inputFile = file("google-services.json")
    if (inputFile.exists() && firebaseAndroidKey != "YOUR_API_KEY_HERE") {
        doFirst {
            val content = inputFile.readText()
            if (content.contains("YOUR_API_KEY_HERE")) {
                inputFile.writeText(content.replace("YOUR_API_KEY_HERE", firebaseAndroidKey))
            }
        }
    }
}

// Revert key after build to prevent git leak
tasks.register("revertFirebaseKey") {
    val inputFile = file("google-services.json")
    if (inputFile.exists() && firebaseAndroidKey != "YOUR_API_KEY_HERE") {
        doLast {
             val content = inputFile.readText()
             inputFile.writeText(content.replace(firebaseAndroidKey, "YOUR_API_KEY_HERE"))
        }
    }
}

tasks.whenTaskAdded {
    if (name.contains("process") && name.contains("GoogleServices")) {
        dependsOn("injectFirebaseKey")
        finalizedBy("revertFirebaseKey")
    }
}

android {
    namespace = "com.vishal.odtrack_academia"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.vishal.odtrack_academia"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Split APKs by architecture for smaller file sizes
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = true
        }
    }

    // Build performance optimizations for Android SDK 35
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
