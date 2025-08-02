import org.gradle.api.tasks.Delete
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.io.File

// 👉 Repositories cho plugin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
    }
}

// 👉 Repositories cho tất cả project
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 👉 Chuyển thư mục build chính
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// 👉 Sửa lỗi Kotlin JVM target không đồng bộ
subprojects {
    afterEvaluate {
        // Dùng Kotlin plugin thì cấu hình jvmTarget cho đồng bộ
        plugins.withId("org.jetbrains.kotlin.android") {
            tasks.withType<KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
        }
        // Nếu module Java thì ép Java cũng về 1.8
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                }
            }
        }
        plugins.withId("com.android.application") {
            extensions.configure<com.android.build.gradle.AppExtension>("android") {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                }
            }
        }
    }
}

// 👉 Task clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
