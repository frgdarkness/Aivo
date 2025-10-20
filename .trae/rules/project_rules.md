# Trae AI Project Rules - Optimized

## 🔴 CORE DECLARATIONS
- **AI Model**: State model version before responses
- **Language**: Vietnamese responses, English code
- **Analysis**: Max-level programming logic analysis
- **Task Completion**: Update history.txt → .project-identity after tasks
- **UI Consistency**: Follow existing app structure (nav, animations, UX)
- **Kiro Spec**: Mandatory Requirements.md + Design.md + Tasks.md

## 🔴 UI FIRST ENFORCEMENT
**Trigger**: New projects without existing code logic
**Validation**: 
- ☐ Check existing code logic
- ☐ UI coverage for all user flows
- ☐ CRUD operations have UI screens
- ☐ UI testability confirmed

**Block Development If**: Missing UI coverage, incomplete flows, untestable UI
**Continue Only If**: All UI designed, flows validated, CRUD UI complete

## 🔴 PROJECT IDENTITY CHECK
**Pre-Task**: Read .project-identity → Load stage workflows
- `stage1_brainstorm`: kiro-spec-driven-workflow.md
- `stage2_setup`: task-management.md  
- `stage3_development`: platform-specific rules

## 🔴 TASK BATCHING (9+1 Pattern)
**Problem**: todo_write max 10 tasks, Kiro has 40+ tasks
**Solution**: 9 Kiro tasks + 1 "Load next batch" task
**Sync**: Trae completion → Auto-update Kiro tasks.md with [x]

## 🔴 KIRO TASK EXECUTION
### Pre-Task (MANDATORY)
- ☐ Read Requirements.md (business logic)
- ☐ Check Design.md (UI/UX specs)  
- ☐ Locate task in Tasks.md
- ☐ Validate dependencies

### During Task
- Reference Requirements.md for logic
- Follow Design.md for implementation
- Update Tasks.md status immediately

### Post-Task (IMMEDIATE)
- ☐ Mark [x] in Tasks.md
- ☐ Update progress %
- ☐ Document effort vs estimate
- ☐ Validate against Requirements.md + Design.md

**Blocking Rules**:
- 🚫 No task start without reading Requirements.md + Design.md
- 🚫 No batch task updates
- 🚫 No deviation from Design.md without documentation

## 🔴 FUNCTION INDEX ENFORCEMENT
**Pre-Function**: Search index → Validate signature → Check dependencies
**Post-Function**: Update index → Document callers → Test integration
**Modification**: Discover ALL callers → Impact analysis → Test ALL callers

**Block**: Duplicate names, circular dependencies, unvalidated modifications

## 🔴 ERROR FIXING PRINCIPLE
1. **Dependency Analysis**: Check function callers across files
2. **Impact Assessment**: Analyze cross-file effects
3. **Pre-Fix Validation**: Verify function structure compatibility
4. **Risk Prevention**: Avoid "fix A, break B" scenarios

## 🔴 WORKFLOW ROUTING
**Auto .ai-system Triggers**: "spec", "PRD", "requirements", "task creation", complex features, "god mode"
**Prefer .trae**: Simple fixes, debugging, optimization, quick questions
**Hybrid**: .ai-system planning → .trae execution
**God Mode**: Full project development → .ai-system/workflows/planning/god-mode-workflow.md

## 📋 AGENT INDEX
- **iOS**: swift, swiftui → ios-workflow.md
- **Android**: kotlin, compose → android-workflow.md + TSDDR-2.0-Guide.md
- **APK Mod**: apk, reverse engineering → apk-modification-workflow.md
- **Frontend**: react, vue, typescript → frontend-rules.md
- **Backend**: nodejs, laravel, api → backend-rules.md
- **Mobile Cross**: flutter, react native → TSDDR-2.0-Guide.md
- **DevOps**: docker, k8s, cicd → deployment-automation.md
- **Function Index**: conflicts, dependencies → function-index-system-rules.md
- **God Mode**: full project development → god-mode-workflow.md

## 🔴 CRITICAL IMAGE HANDLING
- **Priority**: Analyze attached images with current task context
- **Design to Prompt**: Auto-trigger when image without specific context

## 🎯 PERFORMANCE TARGETS
- Selection accuracy >90%
- Response time <2s  
- Code quality >8.5/10
- User satisfaction >4.5/5
