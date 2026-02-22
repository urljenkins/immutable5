import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
gradle.projectsEvaluated {
    subprojects {
        val targetJvm = extensions.findByType(BaseExtension::class.java)
            ?.compileOptions
            ?.targetCompatibility
            ?.toString()
            ?: JavaVersion.VERSION_17.toString()

        tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = targetJvm
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
