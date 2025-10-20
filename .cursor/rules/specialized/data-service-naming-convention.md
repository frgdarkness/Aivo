# Data Service Naming Convention Rules

## 🎯 Nguyên Tắc Cơ Bản

### File Naming Convention

- **_BẮT BUỘC_** sử dụng naming convention: `[Domain]DataService.swift` thay vì `Mock[Domain]Data.swift`
- **_BẮT BUỘC_** đặt data service files trong `Data/Services/` directory
- **_NGHIÊM CẤM_** sử dụng prefix "Mock" trong file names vì sẽ được tái sử dụng cho production

### Class Naming Convention

- **_BẮT BUỘC_** class names: `[Domain]DataService` (VD: `BloodPressureDataService`)
- **_BẮT BUỘC_** service classes: `[Domain]Service` (VD: `BloodPressureService`)
- **_BẮT BUỘC_** repository protocols: `[Domain]Repository` (VD: `BloodPressureRepository`)

### Directory Structure

```
Data/
├── Services/                    # All data service files
│   ├── BloodPressureService.swift
│   ├── BloodPressureDataService.swift
│   ├── HeartRateService.swift
│   ├── HeartRateDataService.swift
│   ├── GlucoseService.swift
│   ├── GlucoseDataService.swift
│   ├── WeightService.swift
│   ├── WeightDataService.swift
│   ├── MealService.swift
│   └── MealDataService.swift
└── Repositories/               # Repository implementations
    └── HealthMetricRepository.swift
```

## 🔄 Data Service Architecture Pattern

### 1. Data Service Layer (Sample Data Generation)

```swift
class BloodPressureDataService {
    static let shared = BloodPressureDataService()

    private init() {}

    func generateRecentReadings(days: Int) -> [BloodPressureReading] {
        // Generate realistic sample data
    }

    func generateCurrentReading() -> BloodPressureReading {
        // Generate current reading
    }
}
```

### 2. Service Layer (Repository Implementation)

```swift
class BloodPressureService: BloodPressureRepository {
    private let dataService = BloodPressureDataService.shared

    func getRecentReadings(days: Int) -> AnyPublisher<[BloodPressureReading], Error> {
        return Future<[BloodPressureReading], Error> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let readings = self.dataService.generateRecentReadings(days: days)
                promise(.success(readings))
            }
        }
        .eraseToAnyPublisher()
    }
}
```

### 3. Repository Protocol (Interface)

```swift
protocol BloodPressureRepository {
    func getRecentReadings(days: Int) -> AnyPublisher<[BloodPressureReading], Error>
    func getCurrentReading() -> AnyPublisher<BloodPressureReading?, Error>
    func saveReading(_ reading: BloodPressureReading) -> AnyPublisher<Void, Error>
}
```

## 🚫 Anti-Patterns (NGHIÊM CẤM)

### ❌ WRONG - Mock Naming

```swift
// DON'T DO THIS
class MockBloodPressureData { }
class MockMealData { }
class MockHeartRateService { }
```

### ❌ WRONG - Hardcode Direct Access

```swift
// DON'T DO THIS
let data = MockBloodPressureData.shared.generateReadings()
```

### ❌ WRONG - Inconsistent Directory Structure

```
// DON'T DO THIS
Data/
├── MockData/           # ❌ Avoid "Mock" directory
└── Services/
    └── MockService.swift  # ❌ Avoid "Mock" prefix
```

## ✅ Correct Patterns

### ✅ RIGHT - Professional Naming

```swift
// DO THIS
class BloodPressureDataService { }
class MealDataService { }
class HeartRateService { }
```

### ✅ RIGHT - Repository Pattern

```swift
// DO THIS
class BloodPressureService: BloodPressureRepository {
    private let dataService = BloodPressureDataService.shared

    func getRecentReadings(days: Int) -> AnyPublisher<[BloodPressureReading], Error> {
        // Async implementation
    }
}
```

### ✅ RIGHT - Consistent Structure

```
// DO THIS
Data/
├── Services/                    # ✅ Clean directory
│   ├── BloodPressureService.swift
│   ├── BloodPressureDataService.swift
│   └── MealService.swift
└── Repositories/
    └── HealthMetricRepository.swift
```

## 🔧 Migration Strategy

### From Mock to Production Ready

1. **Current State**: `MockBloodPressureData` → `BloodPressureDataService`
2. **Service Layer**: `MockBloodPressureService` → `BloodPressureService`
3. **Future State**: Replace `BloodPressureDataService` with Firebase/API calls
4. **Interface**: Repository protocols remain unchanged

### Easy Firebase Migration

```swift
// Current: Data Service
class BloodPressureDataService {
    func generateRecentReadings() -> [BloodPressureReading] {
        // Generate sample data
    }
}

// Future: Firebase Service
class BloodPressureFirebaseService {
    func getRecentReadings() -> AnyPublisher<[BloodPressureReading], Error> {
        // Firebase calls
    }
}

// Service layer remains the same
class BloodPressureService: BloodPressureRepository {
    // Switch implementation easily
}
```

## 📋 Implementation Checklist

### For New Data Services

- [ ] Create `[Domain]DataService.swift` in `Data/Services/`
- [ ] Create `[Domain]Service.swift` implementing repository protocol
- [ ] Add repository protocol in `Domain/Repositories/`
- [ ] Use async operations with `AnyPublisher<Data, Error>`
- [ ] Include realistic sample data generation
- [ ] Add proper error handling

### For Existing Code

- [ ] Rename all `Mock...Data` files to `...DataService`
- [ ] Rename all `Mock...Service` files to `...Service`
- [ ] Update all imports and references
- [ ] Move files to correct directories
- [ ] Update View files to use new service names

## 🎯 Benefits

### Code Reusability

- Data services can be reused for production
- Repository pattern allows easy implementation switching
- Professional naming convention

### Easy Migration

- Simple switch from sample data to real API
- Repository protocols remain unchanged
- Minimal refactoring required

### Maintainability

- Clear separation of concerns
- Consistent naming convention
- Professional code structure

---

**🔴 CRITICAL**: Always follow this naming convention to avoid confusion and ensure code reusability for production implementation.
