# 🎨 Icon Generation Workflow với Nano Banana

## 🎯 Overview
Workflow tự động generate icon thông minh sử dụng Nano Banana + Gemini API với style đồng nhất và planning system.

## 🔄 Workflow Triggers

### Auto Triggers
- User mentions: `icon`, `generate icon`, `tạo icon`, `design assets`
- `.project-identity` có `iconGeneration.enabled: true`
- `.env` có `GEMINI_API_KEY` và enhanced icon prompts
- Project stage >= `stage3_development`

### Manual Triggers
- User request: "Generate icons for [app/feature]"
- Design phase: "Create icon set for UI"
- Asset preparation: "Prepare app icons"

## 📋 Phase 1: Project Analysis & Icon Planning

### 1.1 Project Context Analysis
```markdown
☐ Analyze .project-identity for:
  - projectType (android/ios/web/backend)
  - projectColors (primary, secondary, accent)
  - keyFeatures and mainFrameworks
  - platformSpecificRules

☐ Determine icon requirements:
  - App icon (launcher/main)
  - Navigation icons (bottom nav, tabs)
  - Feature icons (actions, tools)
  - Status icons (success, error, warning)
  - Content icons (media, documents)
```

### 1.2 Intelligent Icon Categorization
```typescript
interface IconPlanningSystem {
  categories: {
    app_identity: ["launcher", "splash", "notification"],
    navigation: ["home", "search", "profile", "settings"],
    actions: ["add", "edit", "delete", "share", "save"],
    content: ["image", "video", "document", "folder"],
    status: ["success", "error", "warning", "info"],
    tools: ["camera", "gallery", "filter", "crop"]
  },
  
  platformRequirements: {
    android: ["adaptive_icon", "round_icon", "monochrome"],
    ios: ["app_icon", "tab_bar", "toolbar", "navigation"],
    web: ["favicon", "pwa_icons", "social_media"]
  }
}
```

## 🎨 Phase 2: Style Guide Generation

### 2.1 Dynamic Style Analysis
```markdown
☐ Extract project colors from .project-identity
☐ Analyze existing design assets (if any)
☐ Determine style consistency rules:
  - Color palette harmony
  - Icon style (outline/filled/mixed)
  - Corner radius consistency
  - Stroke width standards
  - Shadow/elevation rules
```

### 2.2 Nano Banana Style Templates
Based on [Awesome-Nano-Banana-images](https://github.com/PicoTrex/Awesome-Nano-Banana-images):

```markdown
# Style Templates từ Nano Banana Examples

## 🎭 Style 1: Minimalist Outline (插画变手办 inspired)
- **Characteristics**: Clean lines, minimal details, consistent stroke width
- **Best for**: Navigation icons, tool icons
- **Prompt Template**: "Minimalist outline icon of {icon_name}, clean lines, 2px stroke, transparent background, {primary_color} color"

## 🎨 Style 2: Filled with Gradient
- **Characteristics**: Solid fills with subtle gradients
- **Best for**: App icons, feature highlights
- **Prompt Template**: "Filled icon of {icon_name}, gradient from {primary_color} to {secondary_color}, rounded corners, transparent background"

## 🌟 Style 3: Duotone Modern
- **Characteristics**: Two-color system, modern aesthetic
- **Best for**: Status icons, category icons
- **Prompt Template**: "Duotone icon of {icon_name}, {primary_color} and {accent_color}, modern flat design, transparent background"

## 🔮 Style 4: 3D Isometric (手办 style)
- **Characteristics**: Slight 3D effect, isometric perspective
- **Best for**: App launcher icons, hero icons
- **Prompt Template**: "Isometric 3D icon of {icon_name}, slight depth, {primary_color} with subtle shadows, transparent background"
```

## 🤖 Phase 3: Intelligent Icon Planning

### 3.1 Context-Aware Icon List Generation
```python
def generate_icon_plan(project_type, features, platform):
    """
    Intelligent icon planning based on project context
    """
    base_icons = ["home", "search", "profile", "settings"]
    
    if project_type == "photo_editor":
        return base_icons + [
            "camera", "gallery", "filters", "crop", "rotate", 
            "brightness", "contrast", "saturation", "blur",
            "text", "sticker", "frame", "export", "share"
        ]
    
    elif project_type == "social_media":
        return base_icons + [
            "post", "like", "comment", "share", "message",
            "notification", "follow", "story", "live", "explore"
        ]
    
    elif project_type == "ecommerce":
        return base_icons + [
            "cart", "wishlist", "payment", "order", "delivery",
            "category", "filter", "sort", "review", "support"
        ]
    
    # Auto-detect from project features
    return auto_detect_icons(features)
```

### 3.2 Batch Generation Planning
```markdown
☐ Group icons by style consistency
☐ Plan generation order (critical icons first)
☐ Prepare size variants for each platform:
  - Android: 24dp, 48dp, 72dp, 96dp
  - iOS: 22pt, 25pt, 30pt (@1x, @2x, @3x)
  - Web: 16px, 24px, 32px, 48px
```

## 🚀 Phase 4: Nano Banana Generation

### 4.1 Enhanced Prompt Construction
```typescript
interface IconPromptBuilder {
  buildPrompt(iconName: string, style: string, context: ProjectContext): string {
    const basePrompt = process.env.PROMPT_GENERATE_ICON;
    const styleTemplate = getStyleTemplate(style);
    const colorScheme = context.projectColors;
    
    return `${basePrompt}
    
Icon Name: ${iconName}
Style: ${styleTemplate}
Colors: Primary ${colorScheme.primary}, Secondary ${colorScheme.secondary}
Platform: ${context.platform}
Size: 512x512px
Background: Transparent
Quality: High-resolution, crisp edges
Consistency: Match existing icon set style

Additional Requirements:
- Follow ${context.platform} design guidelines
- Ensure accessibility (WCAG compliant)
- Optimize for ${context.platform} specific requirements
- Maintain visual hierarchy and clarity`;
  }
}
```

### 4.2 API Integration Flow
```markdown
☐ Validate GEMINI_API_KEY availability
☐ Construct enhanced prompts using .env templates
☐ Call Nano Banana via Gemini API
☐ Process and validate generated icons
☐ Apply platform-specific optimizations
☐ Save to organized asset structure
```

## 📁 Phase 5: Asset Organization

### 5.1 Smart Asset Structure
```
assets/icons/
├── generated/
│   ├── android/
│   │   ├── drawable-mdpi/
│   │   ├── drawable-hdpi/
│   │   ├── drawable-xhdpi/
│   │   └── drawable-xxhdpi/
│   ├── ios/
│   │   ├── 1x/
│   │   ├── 2x/
│   │   └── 3x/
│   └── web/
│       ├── svg/
│       └── png/
├── style-guide/
│   ├── icon-style-guide.md
│   ├── color-palette.json
│   └── usage-examples.md
└── generation-log/
    ├── prompts-used.md
    ├── generation-history.json
    └── quality-checklist.md
```

### 5.2 Quality Assurance
```markdown
☐ Validate icon consistency across set
☐ Check platform compliance
☐ Verify accessibility standards
☐ Test icon clarity at different sizes
☐ Ensure transparent background
☐ Validate color contrast ratios
```

## 🔄 Phase 6: Integration & Documentation

### 6.1 Code Integration
```markdown
☐ Generate platform-specific icon constants
☐ Create icon usage documentation
☐ Update design system documentation
☐ Provide implementation examples
```

### 6.2 Workflow Completion
```markdown
☐ Update .project-identity with generated assets
☐ Log generation process and decisions
☐ Create reusable templates for future use
☐ Document lessons learned and optimizations
```

## 🎯 Example: Photo Editor App Icon Set

### Context Analysis
```json
{
  "projectType": "photo_editor",
  "platform": "android",
  "primaryColor": "#2196F3",
  "secondaryColor": "#FF9800",
  "style": "modern_filled_with_outline"
}
```

### Generated Icon Plan
```markdown
# Photo Editor Icon Set Plan

## Core Navigation (4 icons)
1. **Home** - House outline with photo frame
2. **Gallery** - Grid of photo thumbnails
3. **Camera** - Camera lens with capture button
4. **Profile** - User avatar with edit indicator

## Editing Tools (8 icons)
1. **Crop** - Crop tool with corner handles
2. **Rotate** - Circular arrow around image
3. **Filters** - Magic wand with sparkles
4. **Brightness** - Sun icon with rays
5. **Contrast** - Half-filled circle
6. **Saturation** - Color wheel segment
7. **Blur** - Gaussian blur effect
8. **Sharpen** - Diamond with sharp edges

## Actions (6 icons)
1. **Save** - Download arrow to folder
2. **Share** - Share network symbol
3. **Undo** - Left curved arrow
4. **Redo** - Right curved arrow
5. **Reset** - Refresh circular arrow
6. **Export** - Upload arrow from box
```

## 🚨 Error Handling & Fallbacks

### API Failures
```markdown
☐ Retry mechanism with exponential backoff
☐ Fallback to alternative prompts
☐ Manual intervention triggers
☐ Partial generation recovery
```

### Quality Issues
```markdown
☐ Automated quality checks
☐ Style consistency validation
☐ Manual review checkpoints
☐ Regeneration triggers
```

## 📊 Success Metrics

- **Consistency Score**: >90% style matching across icon set
- **Platform Compliance**: 100% adherence to platform guidelines
- **Generation Speed**: <30 seconds per icon
- **Quality Rating**: >4.5/5 user satisfaction
- **Accessibility**: 100% WCAG compliance

---

> **🎨 Smart Icon Generation System**
> Từ ý tưởng đến icon hoàn chỉnh với Nano Banana + AI intelligence