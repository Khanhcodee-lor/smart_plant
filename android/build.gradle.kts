import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
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
}
subprojects {
    afterEvaluate {
        tasks.withType<KotlinCompile>().configureEach {
            val javaTaskName = name.replace("Kotlin", "JavaWithJavac")
            val javaTarget = (project.tasks.findByName(javaTaskName) as? JavaCompile)
                ?.targetCompatibility
                ?: JavaVersion.VERSION_1_8.toString()

            compilerOptions {
                jvmTarget.set(JvmTarget.fromTarget(javaTarget))
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")

    // tflite_flutter 0.10.4 still targets Java 8, while newer Kotlin tooling
    // defaults its Kotlin tasks to the running JDK target.
    if (name == "tflite_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
