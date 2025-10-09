// ✅ 1. BUILDSCRIPT HARUS DI ATAS (dengan repositories)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.3")
    }
}

// ✅ 2. ALL PROJECTS (untuk dependency resolution)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ 3. BUILD DIRECTORY CONFIG
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
    project.evaluationDependsOn(":app")
}

// ✅ 4. CLEAN TASK
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}