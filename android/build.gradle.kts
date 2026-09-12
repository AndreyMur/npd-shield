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
        if (project.plugins.hasPlugin("com.android.library")) {
            val androidExtension = project.extensions.findByName("android") ?: return@afterEvaluate
            val methods = androidExtension.javaClass.methods

            val namespace = try {
                androidExtension.javaClass.getMethod("getNamespace").invoke(androidExtension) as String?
            } catch (_: Exception) {
                null
            }
            if (namespace.isNullOrBlank()) {
                try {
                    androidExtension.javaClass
                        .getMethod("setNamespace", String::class.java)
                        .invoke(androidExtension, project.group.toString())
                } catch (_: Exception) {
                }
            }

            val compileSdk = try {
                androidExtension.javaClass.getMethod("getCompileSdk").invoke(androidExtension) as? Int
            } catch (_: Exception) {
                try {
                    androidExtension.javaClass.getMethod("getCompileSdkVersion").invoke(androidExtension) as? Int
                } catch (_: Exception) {
                    null
                }
            }
            if (compileSdk != null && compileSdk != 36) {
                listOf("setCompileSdk", "setCompileSdkVersion").forEach { setter ->
                    try {
                        methods.firstOrNull { it.name == setter && it.parameterCount == 1 }
                            ?.invoke(androidExtension, 36)
                    } catch (_: Exception) {
                    }
                }
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
