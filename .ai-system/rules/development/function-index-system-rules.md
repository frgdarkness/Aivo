# Function Index System Rules

> **"Test All, Break None" - Comprehensive Function Dependency Management**

## 🎯 Core Mission

**Prevent cascading failures when modifying functions by ensuring all callers are tested and validated automatically.**

## 🔴 MANDATORY ACTIVATION TRIGGERS

**AI MUST activate Function Index System when:**

- ✅ User mentions "function conflicts", "dependency issues", "caller problems"
- ✅ User reports "sửa file A lỗi file B", "modify function breaks other files"
- ✅ User requests "function safety", "dependency management", "caller validation"
- ✅ Detecting function signature changes in code modifications
- ✅ User mentions "function index", "caller discovery", "auto-testing"
- ✅ Project has `functionIndexSystem: true` in .project-identity

## 🏗️ System Architecture Rules

### 1. Function Registry Management

**MANDATORY: Maintain Function Registry**

```markdown
☐ Create/update function registry for all project functions
☐ Track function signatures, parameters, return types
☐ Record all caller locations and usage patterns
☐ Monitor function modification history
☐ Maintain compatibility matrix between functions
```

**Registry Structure Requirements:**
- Function name, file path, line number
- Parameter types and names
- Return type and structure
- All caller locations with context
- Usage patterns and frequency
- Modification history and impact

### 2. Caller Discovery Engine

**MANDATORY: Comprehensive Caller Analysis**

```markdown
☐ Static analysis - AST parsing for direct calls
☐ Dynamic analysis - Runtime call tracking
☐ Import/export analysis - Module dependencies
☐ Indirect calls - Function references and callbacks
☐ Cross-file dependencies - Inter-module calls
```

**Discovery Scope:**
- Direct function calls: `functionName()`
- Method calls: `obj.functionName()`
- Dynamic calls: `obj[functionName]()`
- Function references: `const fn = functionName`
- Callback usage: `callback(functionName)`
- Import/export chains: Module dependency tracking

### 3. Signature Validation Protocol

**MANDATORY: Breaking Change Detection**

```markdown
☐ Parameter compatibility analysis
☐ Return type compatibility check
☐ Semantic compatibility validation
☐ Runtime compatibility testing
☐ Breaking change impact assessment
```

**Validation Levels:**
- **Level 1**: Syntax compatibility (parameter count, types)
- **Level 2**: Semantic compatibility (parameter meaning, behavior)
- **Level 3**: Runtime compatibility (actual execution testing)
- **Level 4**: Performance compatibility (execution time, memory)

### 4. Auto-Testing Integration

**MANDATORY: Comprehensive Caller Testing**

```markdown
☐ Generate tests for all discovered callers
☐ Execute integration tests automatically
☐ Run regression tests for indirect callers
☐ Perform edge case testing
☐ Validate performance impact
```

**Test Generation Strategy:**
- **Unit Tests**: Modified function itself
- **Integration Tests**: Direct callers with actual arguments
- **Regression Tests**: All callers with representative data
- **Edge Case Tests**: Boundary conditions and error scenarios
- **Performance Tests**: Execution time and resource usage

## 📋 Function Index System Principles

### 1. Index File Location & Format

**MANDATORY: External Index Management**

```markdown
☐ Function index MUST be placed outside .ai-system/ directory
☐ Use JSON format for optimal AI processing speed
☐ Maintain single-line compact format to minimize reading time
☐ Keep schema file synchronized with index structure
```

**File Structure Requirements:**
- **Primary Index**: `function-index.json` (project root)
- **Schema Definition**: `function-index.schema.json` (project root)
- **Example Template**: `function-index.example.json` (project root)
- **Location Rationale**: External placement prevents .ai-system bloat during frequent updates

### 2. Schema Synchronization Rules

**MANDATORY: Consistent Format Standards**

```markdown
☐ All JSON files MUST use compact single-line format
☐ Schema validation MUST be enforced before index updates
☐ Version compatibility MUST be maintained across updates
☐ Breaking schema changes MUST increment major version
```

**Format Optimization:**
- **Compact JSON**: Single-line format reduces AI token consumption
- **Schema Validation**: Ensures data integrity and consistency
- **Version Control**: Semantic versioning for schema evolution
- **Performance**: Optimized for AI reading and processing speed

### 3. Manual vs Automated Approach

**PRINCIPLE: Manual Curation Over Automation**

```markdown
☐ NO automatic script generation for function discovery
☐ NO automated code generation for index maintenance
☐ Focus on manual principles and guidelines
☐ Emphasize human oversight and validation
```

**Rationale:**
- **Quality Control**: Human review ensures accuracy and relevance
- **Context Awareness**: Manual curation captures semantic relationships
- **Flexibility**: Adaptable to project-specific requirements
- **Reliability**: Reduces false positives from automated detection

### 4. Integration with AI System Rules

**MANDATORY: Seamless Rule Integration**

```markdown
☐ Function index MUST sync with .ai-system rules when needed
☐ Index updates MUST trigger validation against system rules
☐ Conflicts between index and rules MUST be resolved manually
☐ Index serves as source of truth for function relationships
```

**Integration Points:**
- **Rule Validation**: Cross-reference with existing .ai-system rules
- **Conflict Resolution**: Manual review process for discrepancies
- **Truth Source**: Function index as authoritative dependency map
- **Sync Mechanism**: Controlled synchronization without automation

## 🚫 CRITICAL BLOCKING RULES

### Function Modification Blocks

**AI MUST BLOCK function modifications when:**

- ❌ Caller discovery is incomplete or failed
- ❌ Breaking changes detected without migration plan
- ❌ Auto-generated tests are failing
- ❌ No compatibility validation performed
- ❌ User hasn't confirmed understanding of impact

### Safety Protocols

**MANDATORY Safety Checks:**

```markdown
🔴 BEFORE modifying any function:
☐ Discover ALL callers (direct + indirect)
☐ Analyze compatibility impact
☐ Generate comprehensive test suite
☐ Execute all tests and validate results
☐ Get user confirmation for breaking changes
☐ Create migration plan if needed
```

**Error Recovery Protocol:**

```markdown
IF tests fail after function modification:
1. 🛑 STOP immediately - do not proceed
2. 📊 Analyze failure patterns and root causes
3. 🔄 Suggest function overloading or versioning
4. 🛠️ Provide migration strategies for callers
5. ✅ Only proceed after user approval
```

## 🎯 AI Behavior Rules

### Pre-Modification Analysis

**🔴 CRITICAL ERROR FIXING PRINCIPLE: Function Dependency Check Before Modification**

**MANDATORY: Khi được yêu cầu fix lỗi, TUYỆT ĐỐI KHÔNG VỘI VÃ sửa đổi function mà phải:**

1. **🔍 Cross-File Dependency Discovery**: Ra soát function đó có được gọi ở các file khác hay không
2. **📊 Caller Impact Assessment**: Phân tích tác động đến tất cả caller functions
3. **⚠️ Risk Prevention Analysis**: Tránh trường hợp "fix lỗi file A lại lỗi file B do sai cấu trúc function"

**MANDATORY: Before ANY function change**

```markdown
1. 🔍 "Analyzing function dependencies..."
2. 📋 "Discovering all callers across the codebase..."
3. 🧪 "Generating auto-tests for discovered callers..."
4. ⚡ "Running compatibility validation..."
5. 📊 "Impact assessment: X direct callers, Y indirect callers"
6. ❓ "Proceed with modification? (y/n)"
```

### During Modification

**MANDATORY: Real-time Validation**

```markdown
☐ Monitor signature changes in real-time
☐ Update caller compatibility matrix
☐ Re-run affected tests automatically
☐ Alert on breaking changes immediately
☐ Suggest alternative approaches if needed
```

### Post-Modification Validation

**MANDATORY: Comprehensive Testing**

```markdown
☐ Execute full test suite for all callers
☐ Validate integration points
☐ Check performance impact
☐ Update function registry
☐ Generate modification report
```

## 🔄 Integration with Existing Workflows

### CI/CD Integration

**Auto-trigger on:**
- Pre-commit hooks
- Pull request creation
- Code review process
- Deployment pipeline

### IDE Integration

**Real-time features:**
- Function caller highlighting
- Impact analysis on hover
- Auto-test generation shortcuts
- Breaking change warnings

### Git Workflow Integration

**Automatic processes:**
- Function change detection
- Caller impact analysis
- Test generation and execution
- Commit blocking on failures

## 📊 Success Metrics

### Coverage Metrics

```markdown
🎯 Target: 95% caller discovery accuracy
📊 Measure: Discovered callers vs actual callers
⏱️ Frequency: Every function modification
```

### Reliability Metrics

```markdown
🎯 Target: 99% test generation success rate
📊 Measure: Successful test generation attempts
⏱️ Frequency: Daily monitoring
```

### Performance Metrics

```markdown
🎯 Target: Analysis completion < 30 seconds
📊 Measure: Time from function change to test results
⏱️ Frequency: Per execution
```

### Quality Metrics

```markdown
🎯 Target: 80% reduction in function-related bugs
📊 Measure: Bug reports categorized by function changes
⏱️ Frequency: Monthly analysis
```

## 🛠️ Implementation Phases

### Phase 1: Foundation (Week 1-2)
- ✅ Caller Discovery Engine
- ✅ Basic Function Registry
- ✅ Simple Test Generation
- ✅ CI/CD Hooks

### Phase 2: Intelligence (Week 3-4)
- ✅ Smart Compatibility Analysis
- ✅ Advanced Test Prioritization
- ✅ Risk Assessment Engine
- ✅ Performance Optimization

### Phase 3: Integration (Week 5-6)
- ✅ IDE Extensions
- ✅ Real-time Monitoring
- ✅ Advanced Analytics
- ✅ Cross-language Support

### Phase 4: Production (Week 7-8)
- ✅ Monitoring Dashboard
- ✅ Alert Systems
- ✅ Documentation
- ✅ Training Materials

## 🎨 User Experience Rules

### Communication Style

**MANDATORY: Clear Progress Communication**

```markdown
✅ "🔍 Discovering callers for function 'formatUser'..."
✅ "📊 Found 15 callers across 8 files"
✅ "🧪 Generating 23 auto-tests..."
✅ "⚡ Running compatibility validation..."
✅ "✅ All tests passed! Safe to proceed."
✅ "❌ 3 tests failed. Review required."
```

### Error Handling

**MANDATORY: Helpful Error Messages**

```markdown
❌ "Function modification blocked: 3 callers will break"
🔧 "Suggested fix: Use function overloading"
📋 "Alternative: Create migration plan for callers"
❓ "Would you like me to generate overloaded version?"
```

### Progress Tracking

**MANDATORY: Transparent Progress Updates**

```markdown
📊 "Progress: Caller Discovery (100%) → Test Generation (75%) → Validation (0%)"
⏱️ "Estimated completion: 2 minutes"
🎯 "Next: Running integration tests..."
```

---

**Remember: "When one function changes, all its relationships must be validated - The art of comprehensive testing"** 🎯✨