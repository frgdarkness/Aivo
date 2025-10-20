# Build Verification Workflow

## 🎯 Nguyên Tắc Cơ Bản

### Build Verification Requirement

- **_BẮT BUỘC_** build project sau mỗi task completion để verify không có compilation errors
- **_BẮT BUỘC_** fix tất cả build errors trước khi tiếp tục task tiếp theo
- **_BẮT BUỘC_** verify app có thể launch và navigate đến dashboard vừa implement
- **_NGHIÊM CẤM_** skip build verification step trong bất kỳ task nào

### Build Verification Checklist

- [ ] Project builds successfully without errors
- [ ] No compilation warnings (hoặc đã documented)
- [ ] App launches successfully
- [ ] Navigation to new dashboard works
- [ ] Basic UI rendering works correctly
- [ ] No runtime crashes on basic interactions

## 🔄 Build Verification Process

### Step 1: Build Project

```bash
# Build project
xcodebuild -project "Health Care 3.xcodeproj" -scheme "Health Care 3" -destination "platform=iOS Simulator,name=iPhone 15" build
```

### Step 2: Verify Build Success

```bash
# Check build result
if [ $? -eq 0 ]; then
    echo "✅ Build successful - No compilation errors"
else
    echo "❌ Build failed - Fix errors before continuing"
    exit 1
fi
```

### Step 3: Test Basic Functionality

- [ ] Launch app in simulator
- [ ] Navigate to implemented dashboard
- [ ] Verify UI renders correctly
- [ ] Test basic interactions (scroll, tap)
- [ ] Check for runtime errors in console

## 📋 Task Completion Workflow

### Before Marking Task Complete

1. **Code Implementation** ✅
2. **Build Verification** ✅ ← **BẮT BUỘC**
3. **Basic Testing** ✅ ← **BẮT BUỘC**
4. **Update Documentation** ✅
5. **Mark Task Complete** ✅

### Build Error Handling

```swift
// Common build errors to watch for:
// 1. Missing imports
// 2. Type mismatches
// 3. Undeclared variables
// 4. Missing files
// 5. Circular dependencies
// 6. Protocol conformance issues
```

## 🚨 Error Resolution Protocol

### When Build Fails

1. **STOP** - Do not continue with next task
2. **ANALYZE** - Read error messages carefully
3. **FIX** - Address root cause, not symptoms
4. **REBUILD** - Verify fix works
5. **TEST** - Ensure functionality still works
6. **CONTINUE** - Only then proceed to next task

### Common Build Error Fixes

```swift
// Missing Import
import Foundation
import SwiftUI

// Type Mismatch
let value: String = "text"  // Instead of let value = 123

// Undeclared Variable
private let dataService = DataService.shared  // Declare before use

// Missing File Reference
// Check file exists and is added to target

// Protocol Conformance
extension View: SomeProtocol { }  // Implement required methods
```

## 📊 Build Status Tracking

### Todo Integration

```markdown
## Task Status Legend

- ✅ Completed (with build verification)
- ⏳ In Progress
- ❌ Not Started
- 🔧 Build Failed (needs fix)
```

### Build Verification Log

```
Task: Implement Blood Pressure Dashboard
Build Status: ✅ Success
Build Time: 45 seconds
Errors: 0
Warnings: 2 (documented)
Launch Test: ✅ Pass
Navigation Test: ✅ Pass
```

## 🔧 Integration with Development Workflow

### For Each Dashboard Implementation

1. **Create Data Service** → Build & Verify
2. **Create UI Components** → Build & Verify
3. **Create Main View** → Build & Verify
4. **Update Navigation** → Build & Verify
5. **Test Complete Flow** → Build & Verify
6. **Mark Task Complete** ✅

### For Refactoring Tasks

1. **Rename Files** → Build & Verify
2. **Update References** → Build & Verify
3. **Update Imports** → Build & Verify
4. **Test Functionality** → Build & Verify
5. **Mark Task Complete** ✅

## 🎯 Quality Assurance Benefits

### Early Error Detection

- Catch compilation errors immediately
- Prevent error accumulation
- Reduce debugging time
- Maintain code quality

### Project Stability

- Ensure project always builds
- Prevent breaking changes
- Maintain development momentum
- Professional development practice

### Team Collaboration

- Anyone can build and run project
- Clear error reporting
- Consistent development environment
- Reduced merge conflicts

## 📋 Implementation Guidelines

### Build Commands

```bash
# Quick build check
xcodebuild -project "Health Care 3.xcodeproj" -scheme "Health Care 3" build

# Full build with testing
xcodebuild -project "Health Care 3.xcodeproj" -scheme "Health Care 3" -destination "platform=iOS Simulator,name=iPhone 15" build test

# Clean build (if needed)
xcodebuild clean -project "Health Care 3.xcodeproj" -scheme "Health Care 3"
```

### Build Verification Script

```bash
#!/bin/bash
# build-verify.sh

echo "🔨 Building Health Care 3 project..."

xcodebuild -project "Health Care 3.xcodeproj" -scheme "Health Care 3" -destination "platform=iOS Simulator,name=iPhone 15" build

if [ $? -eq 0 ]; then
    echo "✅ Build successful - Ready for next task"
    exit 0
else
    echo "❌ Build failed - Fix errors before continuing"
    exit 1
fi
```

## 🚀 Automation Integration

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🔨 Pre-commit build verification..."
./build-verify.sh

if [ $? -ne 0 ]; then
    echo "❌ Commit blocked - Build verification failed"
    exit 1
fi

echo "✅ Build verification passed - Proceeding with commit"
```

### CI/CD Integration

```yaml
# .github/workflows/build.yml
name: Build Verification
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Project
        run: xcodebuild -project "Health Care 3.xcodeproj" -scheme "Health Care 3" build
```

---

**🔴 CRITICAL**: Build verification is MANDATORY after every task completion. Never skip this step to maintain project quality and stability.
