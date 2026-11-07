import com.android.build.api.variant.LibraryAndroidComponentsExtension

allprojects {
    repositories {
        // Optional cache of verified official engine artifacts for slow connections.
        val localEngineCache = rootProject.file("../../.tooling/android-maven")
        if (localEngineCache.isDirectory) {
            maven {
                url = uri(localEngineCache)
                content { includeGroup("io.flutter") }
            }
        }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Flutter plugins with native code must use the same installed NDK as the app.
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension>("androidComponents") {
            finalizeDsl { android ->
                android.ndkVersion = "29.0.14206865"
                android.externalNativeBuild.cmake.version = "3.31.6"
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
