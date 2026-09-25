allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Pin dynamic androidx.test versions so Gradle offline mode doesn't need a
    // version-listing network request.  1.5.2 is the highest version already
    // present in the local Gradle cache from previous auth-suite builds.
    configurations.all {
        resolutionStrategy {
            force("androidx.test:runner:1.5.1")
            force("androidx.test:rules:1.2.0")
        }
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
    
    // Override outdated Kotlin language settings from old plugins
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}
