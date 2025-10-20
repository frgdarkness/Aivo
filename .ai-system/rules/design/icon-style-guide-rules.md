# 🎨 Icon Style Guide Rules

## 🎯 Core Principles

### Universal Design Standards
- **Consistency**: All icons must follow the same visual language
- **Clarity**: Icons should be instantly recognizable at any size
- **Simplicity**: Avoid unnecessary details that don't scale well
- **Accessibility**: Meet WCAG 2.1 AA standards for contrast and clarity

### Nano Banana Integration
- Leverage [Awesome-Nano-Banana-images](https://github.com/PicoTrex/Awesome-Nano-Banana-images) examples
- Focus on "插画变手办" (illustration to figurine) style transformation
- Maintain consistent prompt engineering for style coherence

## 🎨 Style Templates

### Template 1: Minimalist Outline
```markdown
**Use Cases**: Navigation, tools, secondary actions
**Characteristics**:
- 2px consistent stroke width
- Rounded line caps and joins
- No fills, outline only
- Transparent background
- Single color from project palette

**Prompt Pattern**:
"Minimalist outline icon of {icon_name}, clean lines, 2px stroke weight, rounded caps, {primary_color}, transparent background, simple geometric shapes, no fills"
```

### Template 2: Filled Modern
```markdown
**Use Cases**: Primary actions, app icons, feature highlights
**Characteristics**:
- Solid fills with optional subtle gradients
- Rounded corners (4px radius)
- Consistent visual weight
- Primary color with accent highlights

**Prompt Pattern**:
"Modern filled icon of {icon_name}, solid {primary_color} fill, 4px rounded corners, subtle gradient to {secondary_color}, transparent background, clean geometric design"
```

### Template 3: Duotone System
```markdown
**Use Cases**: Categories, status indicators, content types
**Characteristics**:
- Two-color maximum
- Primary color for main elements
- Secondary/accent for details
- Flat design aesthetic

**Prompt Pattern**:
"Duotone icon of {icon_name}, {primary_color} main elements, {accent_color} details, flat design, no shadows, transparent background, modern minimalist style"
```

### Template 4: 3D Isometric (手办 Style)
```markdown
**Use Cases**: App launchers, hero icons, premium features
**Characteristics**:
- Slight 3D perspective
- Subtle depth and shadows
- Isometric or slight angle view
- Enhanced visual appeal

**Prompt Pattern**:
"Isometric 3D icon of {icon_name}, slight depth perspective, {primary_color} with subtle shadows, soft lighting, transparent background, figurine-like quality, clean edges"
```

## 🎯 Platform-Specific Guidelines

### Android Material Design
```markdown
**Size Standards**: 24dp base unit
**Grid System**: 24x24dp with 2dp padding
**Style Requirements**:
- Adaptive icons for API 26+
- Monochrome variants for themed icons
- Consistent visual weight
- Material Design 3 principles

**Prompt Additions**:
"following Material Design 3 guidelines, adaptive icon compatible, clean geometric shapes"
```

### iOS Human Interface Guidelines
```markdown
**Size Standards**: 22pt base unit
**Grid System**: 22x22pt with 1pt padding
**Style Requirements**:
- SF Symbols compatibility
- Multiple weight variants
- Consistent baseline alignment
- iOS design language

**Prompt Additions**:
"following iOS Human Interface Guidelines, SF Symbols style, consistent baseline, multiple weights"
```

### Web Accessibility
```markdown
**Size Standards**: 16px minimum
**Requirements**:
- SVG format preferred
- Scalable vector graphics
- WCAG 2.1 AA compliance
- High contrast support

**Prompt Additions**:
"web-optimized, scalable vector format, high contrast, accessibility compliant"
```

## 🎨 Color System Integration

### Dynamic Color Extraction
```typescript
interface ColorSystem {
  primary: string;      // From .project-identity
  secondary: string;    // From .project-identity  
  accent: string;       // From .project-identity
  surface: string;      // Background contexts
  onSurface: string;    // Text/icon on surface
  error: string;        // Error states
}

// Auto-generate color variations
function generateIconColors(baseColors: ColorSystem): IconColorPalette {
  return {
    primary: baseColors.primary,
    primaryVariant: adjustBrightness(baseColors.primary, -10),
    secondary: baseColors.secondary,
    accent: baseColors.accent,
    neutral: generateNeutral(baseColors.primary),
    success: generateSuccess(baseColors.accent),
    warning: generateWarning(baseColors.secondary),
    error: baseColors.error
  };
}
```

### Color Usage Rules
```markdown
**Primary Color**: Main icon elements, primary actions
**Secondary Color**: Supporting elements, gradients
**Accent Color**: Highlights, notifications, active states
**Neutral Colors**: Inactive states, disabled elements
**Semantic Colors**: Success (green), Warning (orange), Error (red)
```

## 📐 Size & Spacing Standards

### Base Grid System
```markdown
**Base Unit**: 8px/dp/pt grid system
**Icon Sizes**:
- Micro: 16px (inline text icons)
- Small: 24px (navigation, tools)
- Medium: 32px (buttons, cards)
- Large: 48px (headers, features)
- XL: 64px (app icons, heroes)
- XXL: 128px+ (splash, marketing)
```

### Padding & Margins
```markdown
**Internal Padding**: 10% of icon size
**External Margins**: 25% of icon size for touch targets
**Stroke Width**: 
- 16-24px icons: 1.5px
- 32-48px icons: 2px
- 64px+ icons: 3px
```

## 🔍 Quality Assurance Rules

### Automated Checks
```markdown
☐ **Transparency**: Background must be fully transparent
☐ **Size**: Exactly 512x512px for generation
☐ **Format**: SVG preferred, PNG acceptable
☐ **Colors**: Only use approved project colors
☐ **Consistency**: Match established style template
☐ **Clarity**: Readable at 16px minimum size
```

### Manual Review Checklist
```markdown
☐ **Visual Hierarchy**: Clear primary and secondary elements
☐ **Cultural Sensitivity**: Appropriate for global audience
☐ **Brand Alignment**: Matches project personality and tone
☐ **Accessibility**: Sufficient contrast ratios
☐ **Scalability**: Maintains clarity across all sizes
☐ **Platform Compliance**: Meets specific platform requirements
```

## 🚀 Generation Optimization

### Prompt Engineering Best Practices
```markdown
**Structure**:
1. Base description of icon
2. Style template application
3. Color specification
4. Technical requirements
5. Platform-specific additions
6. Quality modifiers

**Example Optimized Prompt**:
"Minimalist outline icon of a camera, clean geometric lines, 2px stroke weight, rounded line caps, #2196F3 blue color, transparent background, following Material Design 3 guidelines, simple and recognizable, high-resolution vector quality, no unnecessary details"
```

### Batch Generation Rules
```markdown
**Consistency Enforcement**:
- Use same style template for related icons
- Maintain color harmony across icon set
- Apply same technical specifications
- Generate in logical groups (navigation, tools, actions)

**Quality Control**:
- Review first icon of each style before batch
- Validate color accuracy
- Check size and format compliance
- Test readability at target sizes
```

## 📊 Style Validation Matrix

### Icon Category Mapping
```markdown
| Category | Recommended Style | Primary Use | Color Scheme |
|----------|------------------|-------------|--------------|
| Navigation | Minimalist Outline | Bottom nav, tabs | Primary only |
| Actions | Filled Modern | Buttons, FABs | Primary + accent |
| Tools | Minimalist Outline | Toolbars, menus | Primary only |
| Status | Duotone System | Notifications, badges | Semantic colors |
| Content | Filled Modern | Media, documents | Primary + secondary |
| App Identity | 3D Isometric | Launcher, splash | Full palette |
```

### Platform Optimization Matrix
```markdown
| Platform | Preferred Format | Size Range | Special Requirements |
|----------|-----------------|------------|---------------------|
| Android | Vector Drawable | 24-192dp | Adaptive icons, monochrome |
| iOS | SF Symbols | 22-44pt | Multiple weights, baseline |
| Web | SVG | 16-64px | Accessibility, scalability |
| Cross-platform | SVG + PNG | 16-512px | Universal compatibility |
```

## 🔄 Workflow Integration

### Auto-Trigger Conditions
```markdown
**Style Guide Activation**:
- .project-identity has iconGeneration.enabled: true
- Project colors are defined
- Platform type is specified
- Icon generation request detected

**Style Selection Logic**:
1. Analyze project type and platform
2. Extract color scheme from .project-identity
3. Select appropriate style template
4. Apply platform-specific modifications
5. Generate optimized prompts
```

### Continuous Improvement
```markdown
**Feedback Loop**:
- Track generation success rates
- Monitor style consistency scores
- Collect user satisfaction feedback
- Refine prompts based on results
- Update style templates as needed
```

---

> **🎨 Intelligent Style System**
> Consistent, beautiful, platform-optimized icons through smart style guide automation