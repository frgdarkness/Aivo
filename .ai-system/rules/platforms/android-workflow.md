# 🤖 Android Development Workflow - Universal Standards

> **⚡ Comprehensive Android development guidelines with blueprint-first approach**  
> MVVM + Clean Architecture with Jetpack Compose for modern Android apps

---

## 🎯 Core Architecture Principles

### Mandatory Architecture: MVVM + Clean Architecture

- **UI Layer**: Jetpack Compose + ViewModels
- **Domain Layer**: Use Cases + Models + Repository Interfaces
- **Data Layer**: Repository Implementations + Data Sources
- **Unidirectional Data Flow**: UI → ViewModel → UseCase → Repository

### Tech Stack Standards

```kotlin
// UI Framework
implementation "androidx.compose.ui:compose-ui:$compose_version"
implementation "androidx.compose.material3:material3:$material3_version"
implementation "androidx.activity:activity-compose:$activity_compose_version"
implementation "androidx.navigation:navigation-compose:$nav_compose_version"

// Dependency Injection - Choose one:
implementation "com.google.dagger:hilt-android:$hilt_version" // Large projects
// OR
implementation "io.insert-koin:koin-android:$koin_version" // Simpler projects

// Async Programming
implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:$coroutines_version"

// Networking
implementation "com.squareup.retrofit2:retrofit:$retrofit_version"
implementation "com.squareup.okhttp3:okhttp:$okhttp_version"
implementation "org.jetbrains.kotlinx:kotlinx-serialization-json:$serialization_version"

// Database
implementation "androidx.room:room-runtime:$room_version"
implementation "androidx.room:room-ktx:$room_version"
kapt "androidx.room:room-compiler:$room_version"

// Image Loading
implementation "io.coil-kt:coil-compose:$coil_version"

// Logging
implementation "com.jakewharton.timber:timber:$timber_version"

// Testing
testImplementation "junit:junit:$junit_version"
testImplementation "org.mockito.kotlin:mockito-kotlin:$mockito_version"
testImplementation "org.jetbrains.kotlinx:kotlinx-coroutines-test:$coroutines_version"
androidTestImplementation "androidx.compose.ui:ui-test-junit4:$compose_version"
```

---

## 📁 Standard Package Structure - Global Screens Approach

> **🎯 Global Screens Approach**: For small to medium projects, consolidate all screens in a common directory for easier management and navigation.

```
com.base.app/
├── base/                 # Base classes and utilities
│   ├── activity/         # BaseActivity, BaseComposeActivity
│   ├── fragment/         # BaseFragment (if needed)
│   ├── viewmodel/        # BaseViewModel with common functionality
│   ├── adapter/          # BaseAdapter for RecyclerView (if needed)
│   └── view/             # Base Custom Views and Composables
├── core/                 # Core modules and utilities
│   ├── di/               # Dependency Injection modules
│   ├── network/          # Network components (Retrofit, OkHttp)
│   ├── storage/          # Local storage (Room, SharedPreferences)
│   ├── analytics/        # Analytics tracking (Firebase, etc.)
│   ├── navigation/       # Navigation components
│   └── utils/            # Utility classes and extensions
├── data/                 # Data layer implementation
│   ├── repository/       # Repository implementations
│   ├── datasource/       # Data sources (remote, local)
│   │   ├── remote/       # API services and DTOs
│   │   └── local/        # Room entities and DAOs
│   ├── model/            # Data models (entities, DTOs)
│   └── mapper/           # Data mappers between layers
├── domain/               # Domain layer (business logic)
│   ├── usecase/          # Use cases (business logic)
│   ├── model/            # Domain models
│   └── repository/       # Repository interfaces
└── presentation/         # UI layer (presentation) - Global Screens
    ├── screens/          # All screens consolidated
    │   ├── auth/         # Authentication screens
    │   │   ├── LoginScreen.kt
    │   │   ├── RegisterScreen.kt
    │   │   └── ForgotPasswordScreen.kt
    │   ├── main/         # Main app screens
    │   │   ├── HomeScreen.kt
    │   │   ├── ProfileScreen.kt
    │   │   ├── SettingsScreen.kt
    │   │   └── DashboardScreen.kt
    │   └── common/       # Common screens
    │       ├── SplashScreen.kt
    │       ├── OnboardingScreen.kt
    │       └── ErrorScreen.kt
    ├── components/       # Shared UI components
    │   ├── button/       # Custom buttons
    │   ├── input/        # Input components
    │   ├── layout/       # Layout components
    │   ├── dialog/       # Dialog components
    │   └── common/       # Common UI elements
    ├── viewmodels/       # All ViewModels consolidated
    │   ├── AuthViewModel.kt
    │   ├── HomeViewModel.kt
    │   ├── ProfileViewModel.kt
    │   └── SettingsViewModel.kt
    ├── navigation/       # Navigation setup
    │   ├── AppNavigation.kt
    │   ├── NavigationRoutes.kt
    │   └── NavigationExtensions.kt
    └── theme/            # App theme and styling
        ├── Color.kt      # Color definitions
        ├── Typography.kt # Typography definitions
        ├── Dimensions.kt # Spacing and dimensions
        └── Theme.kt      # Main theme
```

---

## 🔄 Blueprint-First Development Process

### Step 1: Create Feature Blueprint

**MANDATORY**: Create blueprint before writing any code

#### Feature Blueprint Template

```markdown
# FEATURE BLUEPRINT: [Feature Name]

## DESCRIPTION

[Detailed feature description and user stories]

## DOMAIN LAYER

### Models

- **[Model1]**: [Description, properties]
- **[Model2]**: [Description, properties]

### Use Cases

- **[UseCase1]**:
  - Input: [Parameters]
  - Output: [Return type]
  - Description: [Business logic description]
- **[UseCase2]**: [Similar format]

### Repository Interfaces

- **[Repository1]**: [Methods and descriptions]

## DATA LAYER

### Repository Implementation

- **[Repository1Impl]**: [Implementation details]

### Data Sources

#### Remote Data Source

- **API Endpoints**:
  - `GET /api/[endpoint]`: [Description, parameters]
  - `POST /api/[endpoint]`: [Description, request body]

#### Local Data Source

- **Room Entities**:
  - **[Entity1]**: [Table structure, relationships]

### Data Models

- **DTOs**: [API response models]
- **Entities**: [Database models]
- **Mappers**: [Conversion logic]

## UI LAYER

### ViewModels

- **[ViewModel1]**:
  - States: [UI states]
  - Events: [User events]
  - Actions: [ViewModel actions]

### Screens

- **[Screen1]**:
  - Layout: [Screen layout description]
  - Components: [Used components]
  - Navigation: [Navigation flow]

### Components

- **[Component1]**: [Purpose, reusability, props]

## RESOURCES

### Strings

- `feature_title`: "[Title]"
- `feature_description`: "[Description]"
- `error_message`: "[Error message]"

### Colors

- `feature_primary`: [Color value]
- `feature_accent`: [Color value]

### Drawables

- `ic_feature_icon`: [Icon description]
- `img_feature_placeholder`: [Image description]

## TESTING STRATEGY

### Unit Tests

- **ViewModels**: [Test scenarios]
- **Use Cases**: [Test scenarios]
- **Repositories**: [Test scenarios]

### UI Tests

- **Screens**: [User interaction tests]
- **Components**: [Component behavior tests]

## DEPENDENCIES

- **New Dependencies**: [List any new dependencies needed]
- **Existing Components**: [List reusable components]
```

### Step 2: Create Package Structure - Global Screens Approach

1. Create screen in appropriate category under `presentation/screens/`
2. Create ViewModel in `presentation/viewmodels/`
3. Create reusable components in `presentation/components/`
4. Update navigation in `presentation/navigation/`

   ```
   presentation/screens/[category]/     # Screen category (auth, main, common)
   ├── [ScreenName]Screen.kt           # Composable screen
   
   presentation/viewmodels/             # All ViewModels
   ├── [Feature]ViewModel.kt           # Feature ViewModel
   
   presentation/components/[type]/      # Reusable components
   ├── [Component]Component.kt         # UI component
   
   domain/usecase/[feature]/           # Use cases (unchanged)
   data/repository/[feature]/          # Repository implementation (unchanged)
   ```

### Step 3: Implementation Order - Global Screens Approach

1. **Domain Layer First** (unchanged):

   - Create domain models
   - Create repository interfaces
   - Create use cases

2. **Data Layer Second** (unchanged):

   - Create data models (DTOs, Entities)
   - Create data sources (API, Database)
   - Create repository implementations
   - Create mappers

3. **Presentation Layer Last** (Global Screens):
   - Create ViewModels in `presentation/viewmodels/`
   - Create reusable components in `presentation/components/`
   - Create screens in appropriate `presentation/screens/[category]/`
   - Update navigation in `presentation/navigation/`

### Step 4: Update Registry

1. Update `blueprint/module-registry.md` with new components
2. Update `blueprint/component-catalog.md` with UI components
3. Update navigation graph
4. Update dependency injection modules

---

## 🚫 Anti-Duplication Rules

### MANDATORY Pre-Creation Checks - Global Screens Approach

Before creating any new class/function/resource:

1. **Search Project**: Use IDE search for similar names/functionality
2. **Check Module Registry**: Review `blueprint/module-registry.md`
3. **Check Component Catalog**: Review `blueprint/component-catalog.md`
4. **Check Core Utils**: Look in `core/utils` for utility functions
5. **Check Presentation Components**: Look in `presentation/components/` for reusable UI
6. **Check Existing Screens**: Look in `presentation/screens/` for similar screens
7. **Check ViewModels**: Look in `presentation/viewmodels/` for similar logic
8. **Prefer Extension**: Extend existing code rather than create new

### Duplication Detection Rules

When similar logic exists in 2+ places:

1. **Extract to Base Class**: Create base class for common functionality
2. **Create Extension Function**: For common operations
3. **Update All Occurrences**: Refactor to use shared code
4. **Document in Registry**: Update component registry

### Similarity Handling

When code is similar but slightly different:

1. **Find Common Pattern**: Identify shared logic
2. **Parameterize Differences**: Make differences configurable
3. **Create Generic Version**: Build flexible, reusable solution
4. **Refactor Existing Code**: Update to use generic version

---

## 🏗️ Base Classes and Templates

### Base ViewModel

```kotlin
abstract class BaseViewModel : ViewModel() {
    protected val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState = _uiState.asStateFlow()

    protected val _events = Channel<UiEvent>()
    val events = _events.receiveAsFlow()

    protected fun handleError(error: Throwable) {
        Timber.e(error, "Error in ${this::class.simpleName}")
        _uiState.value = UiState.Error(error.message ?: "Unknown error")
    }

    protected fun emitEvent(event: UiEvent) {
        viewModelScope.launch {
            _events.send(event)
        }
    }
}

sealed class UiState {
    object Loading : UiState()
    object Success : UiState()
    data class Error(val message: String) : UiState()
}

sealed class UiEvent {
    data class ShowSnackbar(val message: String) : UiEvent()
    data class Navigate(val route: String) : UiEvent()
    object NavigateBack : UiEvent()
}
```

### Base Use Case

```kotlin
abstract class BaseUseCase<in P, R> {
    suspend operator fun invoke(parameters: P): Result<R> = runCatching {
        execute(parameters)
    }

    protected abstract suspend fun execute(parameters: P): R
}

// Example implementation
class GetUserUseCase @Inject constructor(
    private val userRepository: UserRepository
) : BaseUseCase<String, User>() {

    override suspend fun execute(parameters: String): User {
        return userRepository.getUser(parameters)
    }
}
```

### Base Repository

```kotlin
abstract class BaseRepository {
    protected suspend fun <T> safeApiCall(
        apiCall: suspend () -> T
    ): Result<T> = runCatching {
        apiCall()
    }.onFailure { error ->
        Timber.e(error, "API call failed in ${this::class.simpleName}")
    }

    protected suspend fun <T> safeDatabaseCall(
        databaseCall: suspend () -> T
    ): Result<T> = runCatching {
        databaseCall()
    }.onFailure { error ->
        Timber.e(error, "Database call failed in ${this::class.simpleName}")
    }
}
```

### Base Composables

```kotlin
@Composable
fun BaseButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    type: ButtonType = ButtonType.PRIMARY,
    isLoading: Boolean = false
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled && !isLoading,
        colors = ButtonDefaults.buttonColors(
            containerColor = when (type) {
                ButtonType.PRIMARY -> MaterialTheme.colorScheme.primary
                ButtonType.SECONDARY -> MaterialTheme.colorScheme.secondary
                ButtonType.OUTLINE -> Color.Transparent
            }
        )
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(16.dp),
                color = MaterialTheme.colorScheme.onPrimary
            )
        } else {
            Text(text)
        }
    }
}

enum class ButtonType {
    PRIMARY, SECONDARY, OUTLINE
}

@Composable
fun BaseTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String? = null,
    keyboardType: KeyboardType = KeyboardType.Text,
    visualTransformation: VisualTransformation = VisualTransformation.None
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(label) },
            isError = isError,
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            visualTransformation = visualTransformation,
            modifier = Modifier.fillMaxWidth()
        )

        if (isError && errorMessage != null) {
            Text(
                text = errorMessage,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
            )
        }
    }
}
```

---

## 🧪 Testing Standards

### Unit Test Template

```kotlin
@ExperimentalCoroutinesTest
class FeatureViewModelTest {

    @Mock private lateinit var getUserUseCase: GetUserUseCase
    @Mock private lateinit var updateUserUseCase: UpdateUserUseCase

    private lateinit var viewModel: FeatureViewModel
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        MockKAnnotations.init(this)
        Dispatchers.setMain(testDispatcher)
        viewModel = FeatureViewModel(getUserUseCase, updateUserUseCase)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `loadUser success updates state correctly`() = runTest {
        // Given
        val expectedUser = User("1", "John Doe", "john@example.com")
        coEvery { getUserUseCase("1") } returns Result.success(expectedUser)

        // When
        viewModel.loadUser("1")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertTrue(state is UserUiState.Success)
        assertEquals(expectedUser, (state as UserUiState.Success).user)
    }

    @Test
    fun `loadUser failure updates state with error`() = runTest {
        // Given
        val errorMessage = "Network error"
        coEvery { getUserUseCase("1") } returns Result.failure(Exception(errorMessage))

        // When
        viewModel.loadUser("1")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertTrue(state is UserUiState.Error)
        assertEquals(errorMessage, (state as UserUiState.Error).message)
    }
}
```

### UI Test Template

```kotlin
@ExperimentalComposeUiApi
class FeatureScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun userScreen_displaysUserInfo_whenStateIsSuccess() {
        // Given
        val user = User("1", "John Doe", "john@example.com")
        val uiState = UserUiState.Success(user)

        // When
        composeTestRule.setContent {
            UserScreen(
                uiState = uiState,
                onAction = {}
            )
        }

        // Then
        composeTestRule.onNodeWithText("John Doe").assertIsDisplayed()
        composeTestRule.onNodeWithText("john@example.com").assertIsDisplayed()
    }

    @Test
    fun userScreen_displaysLoading_whenStateIsLoading() {
        // Given
        val uiState = UserUiState.Loading

        // When
        composeTestRule.setContent {
            UserScreen(
                uiState = uiState,
                onAction = {}
            )
        }

        // Then
        composeTestRule.onNodeWithTag("loading_indicator").assertIsDisplayed()
    }

    @Test
    fun userScreen_displaysError_whenStateIsError() {
        // Given
        val errorMessage = "Something went wrong"
        val uiState = UserUiState.Error(errorMessage)

        // When
        composeTestRule.setContent {
            UserScreen(
                uiState = uiState,
                onAction = {}
            )
        }

        // Then
        composeTestRule.onNodeWithText(errorMessage).assertIsDisplayed()
    }
}
```

---

## 🚀 Performance Optimization

### Build Configuration

```kotlin
// build.gradle (app level)
android {
    compileSdk 34

    defaultConfig {
        minSdk 24
        targetSdk 34

        // ABI Filtering - ARM only for smaller APK
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a'
        }
    }

    buildTypes {
        release {
            minifyEnabled = true
            shrinkResources = true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    // Enable Android App Bundle
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion compose_version
    }
}
```

### Resource Optimization

- **MANDATORY**: Use Vector Drawables for icons
- **MANDATORY**: Use WebP format for images
- **MANDATORY**: Compress images before adding to project
- **MANDATORY**: Remove unused resources with `shrinkResources = true`

### Code Optimization

- **MANDATORY**: Use R8/ProGuard for code minification
- **MANDATORY**: Avoid reflection when possible
- **MANDATORY**: Use `@Keep` annotation for necessary classes
- **RECOMMENDED**: Use `implementation` instead of `api` in Gradle

---

## 🔥 Firebase Integration

### Application Setup

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Timber logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(CrashReportingTree())
        }

        // Firebase Crashlytics
        FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(!BuildConfig.DEBUG)

        // Performance Monitoring
        FirebasePerformance.getInstance().isPerformanceCollectionEnabled = true

        // Analytics
        FirebaseAnalytics.getInstance(this).setAnalyticsCollectionEnabled(true)
    }
}

private class CrashReportingTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        if (priority == Log.VERBOSE || priority == Log.DEBUG) {
            return
        }

        FirebaseCrashlytics.getInstance().log(message)

        if (t != null) {
            FirebaseCrashlytics.getInstance().recordException(t)
        }
    }
}
```

### Performance Monitoring

```kotlin
// Repository with Performance Monitoring
class NetworkRepository @Inject constructor(
    private val apiService: ApiService
) : BaseRepository() {

    suspend fun fetchUserData(userId: String): Result<User> {
        val trace = FirebasePerformance.getInstance().newTrace("fetch_user_data")
        trace.start()

        return safeApiCall {
            val result = apiService.getUser(userId)
            trace.putAttribute("success", "true")
            trace.putAttribute("user_id", userId)
            result
        }.onFailure { error ->
            trace.putAttribute("success", "false")
            trace.putAttribute("error", error.message ?: "unknown")
        }.also {
            trace.stop()
        }
    }
}
```

---

## ✅ Quality Checklist

### Architecture Compliance

- [ ] MVVM + Clean Architecture implemented correctly
- [ ] Unidirectional Data Flow maintained
- [ ] Proper separation of concerns across layers
- [ ] Dependency injection setup correctly

### Code Quality

- [ ] Blueprint created before implementation
- [ ] Package structure follows standards
- [ ] No code duplication detected
- [ ] Base classes used appropriately
- [ ] UI components reused when possible
- [ ] Error handling implemented comprehensively

### Testing

- [ ] Unit tests cover ViewModels and Use Cases (>80% coverage)
- [ ] UI tests cover critical user flows
- [ ] Repository tests include error scenarios
- [ ] Integration tests validate data flow

### Performance

- [ ] R8/ProGuard configuration working
- [ ] Vector Drawables used for icons
- [ ] WebP format used for images
- [ ] APK size optimized (under target threshold)
- [ ] Performance monitoring setup
- [ ] Memory leaks checked and resolved

### Documentation

- [ ] Feature blueprint completed
- [ ] Module registry updated
- [ ] Component catalog updated
- [ ] API documentation current
- [ ] README files updated

### Security

- [ ] Input validation implemented
- [ ] Sensitive data encrypted
- [ ] Network security configured
- [ ] ProGuard rules protect sensitive code
- [ ] No hardcoded secrets in code

---

## 🔧 APK Reverse Engineering & Modification

> **📋 Specialized APK Modification Workflow**  
> For detailed APK reverse engineering, Google Services integration, and SDK modification procedures

**📋 Dedicated Workflow**: [APK Modification Workflow](apk-modification-workflow.md)

### Quick Reference

- **Method Limit Monitoring**: `find smali* -name "*.smali" | wc -l`
- **Emergency Protocol**: Stop → Backup → Rollback → Validate
- **Integration Focus**: Firebase SDK, Google Services, SafeAds
- **Safety First**: Always backup before major modifications

### When to Use APK Modification Workflow

- APK reverse engineering and decompilation
- Firebase SDK updates and integration
- Google Services version upgrades
- SafeAds implementation and optimization
- Method count management (64K limit)
- Smali code analysis and modification

**🔗 See**: [Complete APK Modification Guide](apk-modification-workflow.md)

---

**🤖 Modern Android development with Jetpack Compose, Clean Architecture, and comprehensive quality standards for scalable, maintainable applications. Enhanced with specialized APK modification capabilities for Firebase SDK updates and Google Services integration.**
