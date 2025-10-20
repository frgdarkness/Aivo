# AIVO AI MUSIC CREATOR - UI/UX SPECIFICATIONS

## 🎨 DESIGN SYSTEM

### Color Palette
```swift
// Primary Orange Theme
struct AivoColors {
    static let primary = Color(hex: 0xFF8000)      // #FF8000 - Bright Orange
    static let secondary = Color(hex: 0xFFB333)    // #FFB333 - Light Orange
    static let accent = Color(hex: 0xFF6A00)       // #FF6A00 - Dark Orange
    static let background = Color(hex: 0x000000)   // #000000 - Black
    static let surface = Color(hex: 0x1A1A1A)      // #1A1A1A - Dark Gray
    static let text = Color(hex: 0xFFFFFF)         // #FFFFFF - White
    static let textSecondary = Color(hex: 0xCCCCCC) // #CCCCCC - Light Gray
}
```

### Typography
```swift
// Font System
struct AivoFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 28, weight: .semibold)
    static let headline = Font.system(size: 22, weight: .medium)
    static let body = Font.system(size: 17, weight: .regular)
    static let caption = Font.system(size: 14, weight: .regular)
    static let small = Font.system(size: 12, weight: .regular)
}
```

### Spacing System
```swift
// Spacing Scale
struct AivoSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

## 📱 SCREEN SPECIFICATIONS

### 1. SPLASH SCREEN
**Purpose**: App launch and branding

#### Layout
- **Background**: AivoBackgroundView with orange gradient
- **Logo**: "AIVO" text with orange glow effect
- **Tagline**: "Transform Your Musical Ideas Into Reality"
- **Loading**: Orange progress bar with animation

#### Animation
- **Duration**: 3 seconds
- **Logo Fade In**: 0.5s delay, 1s duration
- **Progress Bar**: Smooth fill animation
- **Background**: Subtle gradient animation

### 2. ONBOARDING FLOW
**Purpose**: Introduce features and get user started

#### Screen 1: Welcome
- **Title**: "Welcome to Aivo"
- **Subtitle**: "AI-Powered Music Creation"
- **Illustration**: Music note with AI elements
- **Button**: "Get Started" (Orange primary)

#### Screen 2: AI Music Generation
- **Title**: "Create Songs with AI"
- **Description**: "Describe your idea, get a complete song"
- **Demo**: Animated music generation
- **Button**: "Next" (Orange primary)

#### Screen 3: Voice Transformation
- **Title**: "Transform Your Voice"
- **Description**: "Change gender, age, or style instantly"
- **Demo**: Voice transformation animation
- **Button**: "Next" (Orange primary)

#### Screen 4: Ready to Create
- **Title**: "Ready to Create?"
- **Description**: "Start your musical journey now"
- **Button**: "Start Creating" (Orange primary)

### 3. MAIN DASHBOARD
**Purpose**: Central hub for all features

#### Header
- **Logo**: "AIVO" with orange glow
- **Profile**: User avatar and settings
- **Notifications**: Bell icon with badge

#### Quick Actions
- **Create Song**: Large orange button with music icon
- **Voice Cover**: Medium button with microphone icon
- **My Projects**: Medium button with folder icon
- **Templates**: Medium button with template icon

#### Recent Projects
- **Section Title**: "Recent Projects"
- **Project Cards**: 
  - Thumbnail with waveform
  - Project name
  - Creation date
  - Play button overlay

#### Bottom Navigation
- **Home**: House icon (active)
- **Create**: Plus icon
- **Library**: Music note icon
- **Profile**: Person icon

### 4. SONG CREATION FLOW
**Purpose**: Guided music creation process

#### Step 1: Describe Your Song
- **Title**: "What kind of song do you want to create?"
- **Input Field**: Large text area with placeholder
- **Suggestions**: Quick suggestion chips
- **Examples**: "upbeat pop song about summer love"
- **Button**: "Generate Song" (Orange primary)

#### Step 2: Customize Style
- **Genre Selection**: Horizontal scrollable chips
- **Mood Slider**: Happy ← → Sad
- **Tempo Control**: BPM slider (60-200)
- **Key Selection**: Dropdown with all keys
- **Button**: "Continue" (Orange primary)

#### Step 3: AI Generation
- **Title**: "Creating Your Song..."
- **Progress Bar**: Animated progress with percentage
- **Status**: "Generating melody...", "Creating lyrics...", "Finalizing..."
- **Cancel Button**: "Cancel" (Secondary)

#### Step 4: Review & Edit
- **Waveform**: Visual representation of generated song
- **Play Controls**: Play, pause, skip, loop
- **Edit Options**: 
  - Regenerate song
  - Edit lyrics
  - Adjust tempo
  - Change key
- **Button**: "Save & Continue" (Orange primary)

### 5. VOICE TRANSFORMATION
**Purpose**: Voice recording and transformation

#### Recording Interface
- **Waveform Display**: Real-time audio visualization
- **Record Button**: Large circular button with pulse animation
- **Timer**: Recording duration display
- **Quality Indicator**: Audio level meter

#### Voice Settings
- **Gender**: Male/Female toggle
- **Age**: Young/Adult/Old slider
- **Pitch**: ±12 semitones slider
- **Style**: Warm/Bright/Deep/Airy selection

#### Preview & Export
- **Playback**: Transformed voice preview
- **A/B Comparison**: Original vs transformed
- **Export Options**: MP3, WAV, AAC
- **Share Button**: Social media integration

### 6. PROJECT LIBRARY
**Purpose**: Manage and organize projects

#### Header
- **Title**: "My Projects"
- **Search Bar**: Search projects by name
- **Filter**: Sort by date, name, type
- **View Toggle**: Grid/List view

#### Project Grid
- **Project Cards**:
  - Thumbnail with waveform
  - Project name
  - Creation date
  - Duration
  - Status (Draft/Complete)
  - Menu (Edit/Share/Delete)

#### Project Details
- **Project Info**: Name, date, duration, genre
- **Actions**: Play, Edit, Share, Export, Delete
- **Versions**: Version history
- **Collaborators**: Shared with users

### 7. PROFILE & SETTINGS
**Purpose**: User account and app settings

#### Profile Section
- **Avatar**: User profile picture
- **Name**: Display name
- **Email**: User email
- **Stats**: Songs created, hours used

#### Settings
- **Audio Quality**: 44.1kHz, 48kHz selection
- **Export Format**: MP3, WAV, AAC preference
- **Notifications**: Push notification settings
- **Privacy**: Data sharing preferences

#### Subscription
- **Current Plan**: Free/Premium/Pro
- **Usage**: Songs remaining, storage used
- **Upgrade**: Upgrade to premium
- **Billing**: Manage subscription

## 🎵 COMPONENT SPECIFICATIONS

### 1. BUTTONS

#### Primary Button
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AivoColors.primary)
                .cornerRadius(12)
                .shadow(color: AivoColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}
```

#### Secondary Button
```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(AivoColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AivoColors.primary, lineWidth: 2)
                )
        }
    }
}
```

### 2. CARDS

#### Project Card
```swift
struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with waveform
            WaveformView(audioData: project.audioData)
                .frame(height: 80)
                .cornerRadius(8)
            
            // Project info
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(project.creationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text(project.duration)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(project.genre)
                        .font(.caption)
                        .foregroundColor(AivoColors.primary)
                }
            }
        }
        .padding()
        .background(AivoColors.surface)
        .cornerRadius(12)
    }
}
```

### 3. INPUTS

#### Text Input
```swift
struct AivoTextInput: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .background(AivoColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AivoColors.primary.opacity(0.3), lineWidth: 1)
            )
    }
}
```

#### Slider
```swift
struct AivoSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("\(Int(range.lowerBound))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Slider(value: $value, in: range)
                    .accentColor(AivoColors.primary)
                
                Text("\(Int(range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
```

## 🎨 ANIMATION SPECIFICATIONS

### 1. TRANSITIONS
- **Screen Transitions**: Slide from right (0.3s)
- **Modal Presentations**: Slide up from bottom (0.3s)
- **Tab Changes**: Fade in/out (0.2s)
- **Button Press**: Scale down to 0.95 (0.1s)

### 2. LOADING ANIMATIONS
- **Song Generation**: Pulsing orange dots (2s cycle)
- **Voice Processing**: Waveform animation
- **File Upload**: Progress bar with percentage
- **App Launch**: Logo scale and fade

### 3. INTERACTIVE FEEDBACK
- **Button Hover**: Scale to 1.05 (0.2s)
- **Card Selection**: Scale to 1.02 (0.2s)
- **Slider Movement**: Smooth value updates
- **Toggle States**: Smooth color transitions

## 📱 RESPONSIVE DESIGN

### iPhone Sizes
- **iPhone SE**: 375x667 (Compact)
- **iPhone 12/13**: 390x844 (Standard)
- **iPhone 12/13 Pro Max**: 428x926 (Large)

### iPad Sizes
- **iPad Mini**: 768x1024 (Compact)
- **iPad Air**: 820x1180 (Standard)
- **iPad Pro**: 1024x1366 (Large)

### Adaptive Layouts
- **Compact**: Single column, stacked elements
- **Regular**: Two column, side-by-side elements
- **Large**: Three column, expanded layouts

## ♿ ACCESSIBILITY

### VoiceOver Support
- **Labels**: All interactive elements labeled
- **Hints**: Descriptive hints for complex actions
- **Navigation**: Logical tab order
- **Announcements**: Status changes announced

### Visual Accessibility
- **High Contrast**: High contrast mode support
- **Dynamic Type**: Scalable text sizes
- **Color Blind**: Color-blind friendly palette
- **Reduced Motion**: Respects motion preferences

### Motor Accessibility
- **Large Targets**: Minimum 44pt touch targets
- **Gesture Alternatives**: Button alternatives for gestures
- **Voice Control**: Voice control compatibility
- **Switch Control**: Switch control support

---

**Document Version**: 1.0  
**Last Updated**: December 20, 2024  
**Next Review**: January 20, 2025  
**Design System**: Aivo Orange Theme
