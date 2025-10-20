# Source Analysis Phase - Giai Đoạn Phân Tích Dự Án Nguồn

> **🔍 Deep Source Code & Architecture Analysis**  
> Comprehensive analysis of source applications for accurate recreation

## 🎯 PHASE OVERVIEW

**Objective**: Thoroughly analyze source application to understand architecture, patterns, and implementation details

**Duration**: 2-4 hours for medium complexity apps

**Output**: Complete source analysis report with actionable recreation plan

## 🔴 MANDATORY PRE-ANALYSIS SETUP

### Environment Preparation

```bash
# Create analysis workspace
mkdir -p analysis/
cd analysis/

# Setup analysis tools
npm install -g @storybook/cli
pip install jadx-py apktool-py
brew install jadx apktool class-dump
```

### Analysis Directory Structure

```
analysis/
├── source/                 # Original source files
├── decompiled/            # Decompiled code
├── resources/             # Extracted resources
├── documentation/         # Analysis reports
├── screenshots/           # UI screenshots
├── flows/                 # User flow diagrams
└── recreation-plan/       # Implementation roadmap
```

## 📱 PLATFORM-SPECIFIC ANALYSIS

### Android APK Analysis

#### 1. APK Decompilation

```bash
# Method 1: Using jadx (Recommended)
jadx -d decompiled/ source.apk

# Method 2: Using apktool for resources
apktool d source.apk -o decompiled/

# Method 3: Manual extraction
unzip source.apk -d extracted/
d2j-dex2jar classes.dex
```

#### 2. Manifest Analysis

**Critical Information to Extract**:
```xml
<!-- AndroidManifest.xml Analysis Checklist -->
☐ Package name and version
☐ Minimum SDK and target SDK
☐ Permissions (dangerous, normal, signature)
☐ Activities and their intent filters
☐ Services (foreground, background)
☐ Broadcast receivers
☐ Content providers
☐ Application class and theme
☐ Hardware requirements
☐ Network security config
```

#### 3. Resource Analysis

**Resource Extraction Process**:
```markdown
☐ Extract all drawable resources (PNG, SVG, XML)
☐ Analyze layout files (activities, fragments, dialogs)
☐ Extract color definitions (colors.xml)
☐ Analyze style and theme definitions
☐ Extract string resources for localization
☐ Analyze dimension and size definitions
☐ Extract animation definitions
☐ Analyze menu definitions
```

#### 4. Code Structure Analysis

**Java/Kotlin Code Analysis**:
```java
// Analysis Focus Areas

1. Application Architecture:
   - Package structure
   - Dependency injection setup
   - Database implementation
   - Network layer architecture

2. Activity/Fragment Lifecycle:
   - onCreate, onResume patterns
   - State management
   - Fragment transactions
   - Back stack management

3. Data Flow:
   - Repository patterns
   - ViewModel implementations
   - LiveData/StateFlow usage
   - Database queries

4. UI Patterns:
   - RecyclerView adapters
   - Custom view implementations
   - Animation and transitions
   - Theme and styling
```

### iOS IPA Analysis

#### 1. IPA Extraction

```bash
# Extract IPA contents
unzip app.ipa -d extracted/
cd extracted/Payload/App.app/

# Analyze Info.plist
plutil -p Info.plist

# Extract binary information
class-dump -H App > headers.h
otool -L App  # Check linked libraries
```

#### 2. Swift/Objective-C Analysis

**Code Analysis Focus**:
```swift
// Swift Analysis Checklist
☐ App architecture (MVC, MVVM, VIPER)
☐ Storyboard vs programmatic UI
☐ Core Data or other persistence
☐ Network layer implementation
☐ Navigation patterns
☐ Custom UI components
☐ Animation implementations
☐ Third-party dependencies
```

#### 3. Resource Analysis

```markdown
☐ Extract all image assets (@1x, @2x, @3x)
☐ Analyze Storyboard files
☐ Extract XIB files
☐ Analyze color assets
☐ Extract localization files (.strings)
☐ Analyze font files
☐ Extract sound and video assets
```

### Web Application Analysis

#### 1. Source Code Analysis

```bash
# Clone or download source
git clone <repository>
cd project/

# Analyze package.json
cat package.json | jq '.dependencies'

# Analyze build configuration
cat webpack.config.js
cat vite.config.js
cat next.config.js
```

#### 2. Framework Detection

**Auto-Detection Script**:
```javascript
function detectFramework(packageJson) {
  const deps = {...packageJson.dependencies, ...packageJson.devDependencies};
  
  if (deps.react) return 'React';
  if (deps.vue) return 'Vue.js';
  if (deps['@angular/core']) return 'Angular';
  if (deps.svelte) return 'Svelte';
  if (deps.next) return 'Next.js';
  if (deps.nuxt) return 'Nuxt.js';
  
  return 'Vanilla JavaScript';
}
```

## 🏗️ ARCHITECTURE PATTERN DETECTION

### Pattern Recognition Algorithm

```python
def detect_architecture_pattern(source_code):
    patterns = {
        'MVC': check_mvc_pattern(source_code),
        'MVP': check_mvp_pattern(source_code),
        'MVVM': check_mvvm_pattern(source_code),
        'Clean Architecture': check_clean_architecture(source_code),
        'Redux/Flux': check_redux_pattern(source_code),
        'Repository Pattern': check_repository_pattern(source_code)
    }
    
    return max(patterns, key=patterns.get)

def check_mvvm_pattern(code):
    score = 0
    if 'ViewModel' in code: score += 3
    if 'LiveData' in code: score += 2
    if 'DataBinding' in code: score += 2
    if 'Observer' in code: score += 1
    return score
```

### Architecture Mapping

**Pattern Translation Matrix**:
```markdown
Source Pattern → Target Pattern

MVC → MVVM + Repository
- Model → Entity + Repository
- View → View + ViewModel
- Controller → ViewModel + UseCase

MVP → Clean Architecture
- Model → Entity + Repository
- View → View + ViewModel
- Presenter → UseCase + ViewModel

Flux/Redux → State Management
- Store → State Management (Redux/MobX/Zustand)
- Actions → Actions/Events
- Reducers → Reducers/Mutations
```

## 🔍 DEPENDENCY ANALYSIS

### Third-Party Library Detection

**Android Dependencies**:
```gradle
// build.gradle analysis
defaultConfig {
    // Extract version codes, SDK versions
}

dependencies {
    // Categorize dependencies:
    // - UI Libraries (Material, ConstraintLayout)
    // - Network (Retrofit, OkHttp, Volley)
    // - Image Loading (Glide, Picasso)
    // - Database (Room, SQLite)
    // - Dependency Injection (Dagger, Hilt)
    // - Testing (JUnit, Espresso)
}
```

**iOS Dependencies**:
```ruby
# Podfile analysis
target 'App' do
  # Categorize pods:
  # - UI (SnapKit, Alamofire)
  # - Network (Alamofire, URLSession)
  # - Image (Kingfisher, SDWebImage)
  # - Database (CoreData, Realm)
  # - Testing (Quick, Nimble)
end
```

### Dependency Mapping Strategy

```json
{
  "dependencyMapping": {
    "android": {
      "retrofit": ["dio", "http", "axios"],
      "glide": ["cached_network_image", "image_picker"],
      "room": ["sqflite", "hive", "isar"]
    },
    "ios": {
      "alamofire": ["dio", "http"],
      "kingfisher": ["cached_network_image"],
      "coredata": ["sqflite", "hive"]
    }
  }
}
```

## 📊 DATA FLOW ANALYSIS

### Database Schema Extraction

**Android Room/SQLite**:
```sql
-- Extract from Room entities or SQLite schema
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Analyze relationships
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    title TEXT,
    content TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**iOS Core Data**:
```swift
// Extract from .xcdatamodeld
entity User {
    @NSManaged var id: Int32
    @NSManaged var name: String
    @NSManaged var email: String
    @NSManaged var posts: NSSet?
}

entity Post {
    @NSManaged var id: Int32
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var user: User?
}
```

### API Endpoint Discovery

**Network Call Analysis**:
```javascript
// Extract API endpoints from code
const apiEndpoints = {
  baseUrl: 'https://api.example.com',
  endpoints: {
    auth: {
      login: 'POST /auth/login',
      register: 'POST /auth/register',
      refresh: 'POST /auth/refresh'
    },
    users: {
      profile: 'GET /users/profile',
      update: 'PUT /users/profile',
      avatar: 'POST /users/avatar'
    },
    posts: {
      list: 'GET /posts',
      create: 'POST /posts',
      update: 'PUT /posts/:id',
      delete: 'DELETE /posts/:id'
    }
  }
};
```

## 🎨 UI/UX PATTERN ANALYSIS

### Design System Extraction

**Color Palette Analysis**:
```xml
<!-- colors.xml analysis -->
<resources>
    <color name="primary">#1976D2</color>
    <color name="primary_dark">#1565C0</color>
    <color name="accent">#03DAC6</color>
    <color name="background">#FFFFFF</color>
    <color name="surface">#F5F5F5</color>
    <color name="error">#B00020</color>
</resources>
```

**Typography System**:
```xml
<!-- styles.xml analysis -->
<style name="TextAppearance.Headline1">
    <item name="android:textSize">96sp</item>
    <item name="android:fontFamily">@font/roboto_light</item>
    <item name="android:letterSpacing">-0.015625</item>
</style>
```

### Component Pattern Recognition

**UI Component Inventory**:
```markdown
☐ Navigation patterns (drawer, tabs, bottom nav)
☐ List patterns (simple, card-based, grid)
☐ Form patterns (validation, input types)
☐ Dialog patterns (alerts, confirmations, custom)
☐ Loading patterns (spinners, skeletons, progress)
☐ Empty state patterns
☐ Error state patterns
☐ Animation patterns (transitions, micro-interactions)
```

## 📋 ANALYSIS REPORT GENERATION

### Automated Report Template

```markdown
# Source Analysis Report

## Executive Summary
- **App Name**: {app_name}
- **Platform**: {platform}
- **Architecture**: {architecture_pattern}
- **Complexity**: {complexity_level}
- **Estimated Recreation Time**: {time_estimate}

## Technical Stack
- **Language**: {primary_language}
- **Framework**: {framework}
- **Dependencies**: {dependency_count} libraries
- **Database**: {database_type}
- **Network**: {network_library}

## Feature Analysis
- **Core Features**: {core_feature_count}
- **Screens**: {screen_count}
- **API Endpoints**: {api_endpoint_count}
- **Database Tables**: {table_count}

## Recreation Recommendations
- **Target Platform**: {recommended_platform}
- **Architecture**: {recommended_architecture}
- **Key Challenges**: {challenge_list}
- **Implementation Priority**: {priority_order}

## Resource Requirements
- **Development Time**: {dev_time_estimate}
- **Team Size**: {team_size_recommendation}
- **Skill Requirements**: {required_skills}
```

### Quality Metrics

**Analysis Completeness Score**:
```javascript
function calculateCompletenessScore(analysis) {
  const criteria = {
    architectureIdentified: analysis.architecture ? 20 : 0,
    dependenciesMapped: analysis.dependencies.length > 0 ? 15 : 0,
    uiComponentsExtracted: analysis.uiComponents.length > 0 ? 15 : 0,
    apiEndpointsDocumented: analysis.apiEndpoints.length > 0 ? 15 : 0,
    databaseSchemaMapped: analysis.databaseSchema ? 15 : 0,
    resourcesExtracted: analysis.resources.length > 0 ? 10 : 0,
    businessLogicAnalyzed: analysis.businessLogic ? 10 : 0
  };
  
  return Object.values(criteria).reduce((sum, score) => sum + score, 0);
}
```

## 🔧 ANALYSIS TOOLS & SCRIPTS

### Automated Analysis Script

```python
#!/usr/bin/env python3

import os
import json
import subprocess
from pathlib import Path

class SourceAnalyzer:
    def __init__(self, source_path):
        self.source_path = Path(source_path)
        self.analysis_result = {}
    
    def analyze(self):
        if self.source_path.suffix == '.apk':
            return self.analyze_android_apk()
        elif self.source_path.suffix == '.ipa':
            return self.analyze_ios_ipa()
        else:
            return self.analyze_source_code()
    
    def analyze_android_apk(self):
        # Decompile APK
        subprocess.run(['jadx', '-d', 'decompiled/', str(self.source_path)])
        
        # Analyze manifest
        manifest = self.parse_android_manifest()
        
        # Extract resources
        resources = self.extract_android_resources()
        
        # Analyze code structure
        code_analysis = self.analyze_java_kotlin_code()
        
        return {
            'platform': 'Android',
            'manifest': manifest,
            'resources': resources,
            'code': code_analysis
        }
    
    def generate_report(self):
        # Generate comprehensive analysis report
        pass

if __name__ == '__main__':
    analyzer = SourceAnalyzer('/path/to/source')
    result = analyzer.analyze()
    print(json.dumps(result, indent=2))
```

## 🎯 SUCCESS CRITERIA

**Analysis Quality Metrics**:
- **Completeness**: >90% of app features identified
- **Accuracy**: >95% correct architecture pattern detection
- **Resource Coverage**: 100% of UI assets extracted
- **API Coverage**: >90% of endpoints documented
- **Time Efficiency**: Analysis completed within estimated timeframe

---

**🔍 Next Phase**: Screen Structure Analysis - detailed UI component mapping and layout recreation planning