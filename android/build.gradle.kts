allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all subprojects to use Java 17
subprojects {
    afterEvaluate {
        // Configure Java toolchain for all Java projects
        if (plugins.hasPlugin("java")) {
            configure<JavaPluginExtension> {
                toolchain {
                    languageVersion.set(JavaLanguageVersion.of(17))
                }
            }
        }
        
        // Force Java 17 for all Android projects
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
}
val customBuildDir = file("C:/GradleBuilds/ODTrack")
rootProject.layout.buildDirectory.set(customBuildDir)

subprojects {
    project.layout.buildDirectory.set(customBuildDir.resolve(project.name))
}

// Automatically recreate the build/app junction if it's missing (e.g. after flutter clean)
val localBuild = file("${project.rootDir}/../build")
val localAppLink = file("${localBuild.absolutePath}/app")
if (!localAppLink.exists()) {
    if (!localBuild.exists()) localBuild.mkdirs()
    val targetAppDir = file("${customBuildDir.absolutePath}/app")
    if (!targetAppDir.exists()) targetAppDir.mkdirs()
    
    val cmd = arrayOf("cmd", "/c", "mklink /j \"${localAppLink.absolutePath}\" \"${targetAppDir.absolutePath}\"")
    println("Recreating build/app junction: ${cmd.joinToString(" ")}")
    ProcessBuilder(*cmd).start().waitFor()
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
