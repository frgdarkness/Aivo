# 🏗️ Android Gradle Monorepo Mapping - Global Screens

> **Gradle module configuration for Android monorepo with Global Screens Clean Architecture**

---

## 📁 Module Structure

```
android-monorepo/
├── app/                    # Main application module
├── core-common/           # Common utilities and extensions
├── core-domain/           # Domain layer (business logic)
├── core-data/             # Data layer implementation
├── core-network/          # Network layer
├── core-database/         # Database layer
├── core-ui/               # UI components and theme
└── settings.gradle.kts    # Module configuration
```

---

## ⚙️ Gradle Configuration

### Root `settings.gradle.kts`
```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "AndroidMonorepo"

// Core modules
include(":app")
include(":core-common")
include(":core-domain")
include(":core-data")
include(":core-network")
include(":core-database")
include(":core-ui")
```

### Root `build.gradle.kts`
```kotlin
buildscript {
    extra.apply {
        set("compose_version", "1.5.4")
        set("kotlin_version", "1.9.10")
        set("hilt_version", "2.48")
        set("room_version", "2.6.0")
        set("retrofit_version", "2.9.0")
    }
}

plugins {
    id("com.android.application") version "8.1.2" apply false
    id("com.android.library") version "8.1.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
    id("com.google.dagger.hilt.android") version "2.48" apply false
    id("kotlin-kapt") apply false
}
```

---

## 📦 Module Dependencies

### `:app` Module
```kotlin
// app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dagger.hilt.android.plugin")
    kotlin("kapt")
}

dependencies {
    // Core modules
    implementation(project(":core-common"))
    implementation(project(":core-domain"))
    implementation(project(":core-data"))
    implementation(project(":core-ui"))
    
    // Jetpack Compose
    implementation("androidx.compose.ui:ui:${rootProject.extra["compose_version"]}")
    implementation("androidx.compose.ui:ui-tooling-preview:${rootProject.extra["compose_version"]}")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.activity:activity-compose:1.8.0")
    
    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.4")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:${rootProject.extra["hilt_version"]}")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    kapt("com.google.dagger:hilt-compiler:${rootProject.extra["hilt_version"]}")
    
    // Lifecycle
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
}
```

### `:core-common` Module
```kotlin
// core-common/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

dependencies {
    // Kotlin Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Utilities
    implementation("androidx.core:core-ktx:1.12.0")
    
    // JSON
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
}
```

### `:core-domain` Module
```kotlin
// core-domain/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("dagger.hilt.android.plugin")
    kotlin("kapt")
}

dependencies {
    implementation(project(":core-common"))
    
    // Hilt
    implementation("com.google.dagger:hilt-android:${rootProject.extra["hilt_version"]}")
    kapt("com.google.dagger:hilt-compiler:${rootProject.extra["hilt_version"]}")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

### `:core-data` Module
```kotlin
// core-data/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("dagger.hilt.android.plugin")
    kotlin("kapt")
}

dependencies {
    implementation(project(":core-common"))
    implementation(project(":core-domain"))
    implementation(project(":core-network"))
    implementation(project(":core-database"))
    
    // Hilt
    implementation("com.google.dagger:hilt-android:${rootProject.extra["hilt_version"]}")
    kapt("com.google.dagger:hilt-compiler:${rootProject.extra["hilt_version"]}")
}
```

### `:core-network` Module
```kotlin
// core-network/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("dagger.hilt.android.plugin")
    kotlin("kapt")
}

dependencies {
    implementation(project(":core-common"))
    
    // Retrofit
    implementation("com.squareup.retrofit2:retrofit:${rootProject.extra["retrofit_version"]}")
    implementation("com.squareup.retrofit2:converter-gson:${rootProject.extra["retrofit_version"]}")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:${rootProject.extra["hilt_version"]}")
    kapt("com.google.dagger:hilt-compiler:${rootProject.extra["hilt_version"]}")
}
```

### `:core-database` Module
```kotlin
// core-database/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("dagger.hilt.android.plugin")
    kotlin("kapt")
}

dependencies {
    implementation(project(":core-common"))
    
    // Room
    implementation("androidx.room:room-runtime:${rootProject.extra["room_version"]}")
    implementation("androidx.room:room-ktx:${rootProject.extra["room_version"]}")
    kapt("androidx.room:room-compiler:${rootProject.extra["room_version"]}")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:${rootProject.extra["hilt_version"]}")
    kapt("com.google.dagger:hilt-compiler:${rootProject.extra["hilt_version"]}")
}
```

### `:core-ui` Module
```kotlin
// core-ui/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

dependencies {
    implementation(project(":core-common"))
    
    // Jetpack Compose
    implementation("androidx.compose.ui:ui:${rootProject.extra["compose_version"]}")
    implementation("androidx.compose.ui:ui-tooling-preview:${rootProject.extra["compose_version"]}")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.compose.material:material-icons-extended:${rootProject.extra["compose_version"]}")
    
    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.4")
    
    // Image Loading
    implementation("io.coil-kt:coil-compose:2.5.0")
}
```

---

## 🎯 Global Screens Package Structure

### `:app` Module Structure
```
app/src/main/java/com/yourapp/
├── presentation/           # Global Screens approach
│   ├── screens/           # All screens consolidated
│   │   ├── auth/          # Authentication screens
│   │   │   ├── LoginScreen.kt
│   │   │   ├── RegisterScreen.kt
│   │   │   └── ForgotPasswordScreen.kt
│   │   ├── main/          # Main app screens
│   │   │   ├── HomeScreen.kt
│   │   │   ├── ProfileScreen.kt
│   │   │   ├── SettingsScreen.kt
│   │   │   └── DashboardScreen.kt
│   │   └── common/        # Common screens
│   │       ├── SplashScreen.kt
│   │       ├── OnboardingScreen.kt
│   │       └── ErrorScreen.kt
│   ├── viewmodels/        # All ViewModels consolidated
│   │   ├── AuthViewModel.kt
│   │   ├── HomeViewModel.kt
│   │   ├── ProfileViewModel.kt
│   │   └── SettingsViewModel.kt
│   ├── components/        # Reusable UI components (from core-ui)
│   └── navigation/        # Navigation setup
│       ├── AppNavigation.kt
│       ├── NavigationRoutes.kt
│       └── NavigationExtensions.kt
├── di/                    # Dependency injection
│   ├── AppModule.kt
│   ├── DatabaseModule.kt
│   ├── NetworkModule.kt
│   └── RepositoryModule.kt
└── MainActivity.kt
```

---

## 🔧 Build Configuration

### Version Catalog (Optional)
```toml
# gradle/libs.versions.toml
[versions]
compose = "1.5.4"
kotlin = "1.9.10"
hilt = "2.48"
room = "2.6.0"
retrofit = "2.9.0"
navigation = "2.7.4"

[libraries]
compose-ui = { group = "androidx.compose.ui", name = "ui", version.ref = "compose" }
compose-material3 = { group = "androidx.compose.material3", name = "material3", version = "1.1.2" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-compiler", version.ref = "hilt" }
navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigation" }

[plugins]
android-application = { id = "com.android.application", version = "8.1.2" }
android-library = { id = "com.android.library", version = "8.1.2" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

---

## 📋 Module Responsibilities

### `:app`
- **Global Screens**: All UI screens consolidated
- **ViewModels**: All presentation logic
- **Navigation**: App-wide navigation setup
- **Dependency Injection**: App-level DI configuration

### `:core-common`
- **Utilities**: Common extensions and helpers
- **Constants**: App-wide constants
- **Base Classes**: Base ViewModels, repositories

### `:core-domain`
- **Use Cases**: Business logic
- **Models**: Domain entities
- **Repository Interfaces**: Data access contracts

### `:core-data`
- **Repository Implementations**: Data access logic
- **Mappers**: Data transformation between layers

### `:core-network`
- **API Services**: Network communication
- **DTOs**: Data transfer objects
- **Network Configuration**: Retrofit setup

### `:core-database`
- **Room Database**: Local data storage
- **DAOs**: Database access objects
- **Entities**: Database entities

### `:core-ui`
- **Reusable Components**: Shared UI components
- **Theme**: App theming and styling
- **Common UI Utilities**: UI helpers

---

## 🚀 Benefits of This Structure

### ✅ Advantages
- **Simplified Management**: All screens in one place
- **Faster Development**: No feature module overhead
- **Easy Navigation**: Centralized navigation logic
- **Shared Components**: Reusable UI components
- **Clean Dependencies**: Clear module boundaries

### 📊 Best For
- Small to medium projects (< 50 screens)
- Rapid prototyping
- Teams with 1-5 developers
- Projects with shared UI patterns

### ⚠️ Considerations
- May become unwieldy for very large projects
- Less feature isolation compared to feature modules
- Requires good naming conventions

---

**🏗️ Optimized Gradle monorepo structure with Global Screens approach for efficient Android development with Clean Architecture principles.**