# Junie AI Guidelines - .ai-system Integration

> **🎯 Junie IDE Integration with Universal AI System**  
> Smart routing to .ai-system for consistent AI behavior across all IDEs

## 🚀 System Overview

This project uses the **Universal .ai-system** for consistent AI behavior across all IDEs (Trae, Cursor, Claude, Junie, etc.). Junie automatically inherits all rules, agents, and workflows from the central system.

## 🔗 Core System Import

**MANDATORY: All Junie sessions must follow .ai-system rules**

```markdown
<!-- Universal AI System Integration -->
@import "../.ai-system/index.md"
```

## 🎯 Junie-Specific Enhancements

### IntelliJ Platform Integration

**Code Analysis & Refactoring**:
- Leverage IntelliJ's powerful code analysis for better suggestions
- Use built-in refactoring tools for safe code transformations
- Integrate with IntelliJ's inspection system for quality checks

**Project Structure Awareness**:
- Understand IntelliJ project modules and dependencies
- Respect IntelliJ's source/test/resource folder conventions
- Work with IntelliJ's build system integration (Gradle, Maven, etc.)

**IDE-Native Features**:
- Use IntelliJ's live templates for code generation
- Integrate with version control (Git) through IntelliJ
- Leverage IntelliJ's debugging capabilities for issue analysis

### Smart Context Loading

**Project Type Detection**:
```markdown
<!-- Auto-detect project type and load appropriate rules -->
IF project contains build.gradle.kts OR build.gradle:
  @import "../.ai-system/rules/platforms/android-workflow.md"
  
IF project contains Package.swift:
  @import "../.ai-system/rules/platforms/ios-workflow.md"
  
IF project contains package.json:
  @import "../.ai-system/rules/platforms/frontend-rules.md"
  
IF project contains composer.json OR artisan:
  @import "../.ai-system/rules/platforms/backend-rules.md"
```

**Development Stage Awareness**:
```markdown
<!-- Load stage-specific workflows based on .project-identity -->
IF projectStage == "stage1_brainstorm":
  @import "../.ai-system/workflows/planning/kiro-spec-driven-workflow.md"
  
IF projectStage == "stage2_setup":
  @import "../.ai-system/workflows/development/task-management.md"
  
IF projectStage == "stage3_development":
  @import "../.ai-system/workflows/development/kiro-task-execution-workflow.md"
```

## 🤖 Junie Agent Selection

**Automatic Agent Routing**:
- **Complex Planning Tasks** → Route to Kiro (.kiro/specs/) for structured breakdown
- **Implementation Tasks** → Use .ai-system agent selection system
- **Quick Fixes** → Direct Junie execution with .ai-system rules
- **Cross-IDE Coordination** → Leverage .ai-system workflows

**Junie Strengths**:
- **IntelliJ Integration**: Best for Java/Kotlin/Android projects
- **Code Analysis**: Superior static analysis and refactoring suggestions
- **Enterprise Features**: Advanced debugging and profiling integration
- **Plugin Ecosystem**: Access to IntelliJ's extensive plugin library

## 📋 Task Management Integration

**Junie-Kiro Coordination**:
```markdown
<!-- When user requests complex features -->
IF task_complexity > medium:
  1. Route to Kiro for spec creation (.kiro/specs/)
  2. Generate structured tasks in Kiro format
  3. Return to Junie for implementation with .ai-system rules
  4. Use .ai-system/workflows/development/ for execution
```

**Todo List Synchronization**:
- Sync with .ai-system task management
- Maintain consistency across IDE sessions
- Track progress in centralized system

## 🔧 Development Workflow

### Code Quality Standards

**Mandatory Checks** (from .ai-system):
- Follow .ai-system/rules/core/mandatory-code-quality.md
- Apply .ai-system/rules/core/development-standards.md
- Use .ai-system/rules/patterns/ for consistent patterns

**Junie-Enhanced Quality**:
- Leverage IntelliJ's code inspections
- Use IntelliJ's formatting and style guides
- Integrate with SonarLint and other quality plugins

### Testing Integration

**Test Strategy**:
```markdown
@import "../.ai-system/workflows/testing/automated-testing-workflow.md"

<!-- Junie-specific testing enhancements -->
- Use IntelliJ's test runner for immediate feedback
- Integrate with coverage tools (JaCoCo, etc.)
- Leverage IntelliJ's test generation capabilities
```

## 🚨 Error Handling & Debugging

**Function Index Integration**:
```markdown
@import "../.ai-system/rules/development/function-index-system-rules.md"
@import "../.ai-system/rules/development/error-fixing-with-function-index.md"
```

**Junie Debug Enhancements**:
- Use IntelliJ's debugger for complex issue analysis
- Leverage IntelliJ's memory and performance profilers
- Integrate with IntelliJ's exception breakpoints

## 📱 Platform-Specific Guidelines

### Android Development (Junie's Strength)
```markdown
@import "../.ai-system/rules/platforms/android-workflow.md"

<!-- Junie Android enhancements -->
- Use Android Studio's layout inspector
- Leverage Gradle build optimization suggestions
- Integrate with Android profiling tools
```

### Kotlin/Java Projects
```markdown
<!-- Leverage IntelliJ's Kotlin/Java expertise -->
- Use IntelliJ's Kotlin-specific inspections
- Apply IntelliJ's Java refactoring tools
- Leverage IntelliJ's dependency analysis
```

## 🔄 Cross-IDE Synchronization

**State Management**:
- Sync project state with .project-identity
- Maintain consistency with other IDE sessions
- Update .ai-system memory with Junie-specific insights

**Handoff Protocol**:
```markdown
<!-- When switching between IDEs -->
1. Update .project-identity with current progress
2. Sync .ai-system memory with new insights
3. Ensure .ai-system/workflows/ reflect current state
4. Maintain task continuity across IDE switches
```

## 🎯 Performance Optimization

**Junie-Specific Optimizations**:
- Cache .ai-system rules for faster loading
- Use IntelliJ's indexing for better code understanding
- Leverage IntelliJ's background analysis for proactive suggestions

**Resource Management**:
- Optimize memory usage for large projects
- Use IntelliJ's power save mode when appropriate
- Balance AI suggestions with IDE performance

---

## 📚 Quick Reference

**Essential Commands**:
- `@ai-system` - Access universal AI system
- `@kiro` - Route to Kiro for complex planning
- `@agent-select` - Trigger smart agent selection
- `@workflow` - Access .ai-system workflows

**Documentation Links**:
- [.ai-system Documentation](../.ai-system/README.md)
- [Agent Selection Guide](../.ai-system/agents/agent-selector.md)
- [Workflow Index](../.ai-system/workflows/index.md)
- [Platform Rules](../.ai-system/rules/platforms/)

---

*This guidelines file automatically inherits all .ai-system rules and provides Junie-specific enhancements for optimal IntelliJ platform integration.*