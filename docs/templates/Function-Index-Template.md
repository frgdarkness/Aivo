# Function Index Template

## 📋 Function Registry Format

### Template Structure
```markdown
# Function Index - [Project Name]

## 📊 Overview
- **Total Functions**: [number]
- **High Risk Functions**: [number] (3+ callers)
- **Last Updated**: [date]
- **Auto-Generated**: [yes/no]

---

## 🔍 Function: [functionName]

### Basic Info
- **File**: `[path/to/file.js]:[lineNumber]`
- **Purpose**: [Brief description of what function does]
- **Risk Level**: [LOW/MEDIUM/HIGH/CRITICAL]
- **Last Modified**: [date]
- **Author**: [developer name]

### Function Signature
```javascript
[actual function signature with types]
```

### Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| param1 | string | ✅ | - | Description of param1 |
| param2 | object | ❌ | {} | Description of param2 |
| param2.option1 | number | ❌ | 0 | Sub-option description |

### Return Value
- **Type**: [return type]
- **Description**: [what it returns]

### Callers (Total: [number])

#### 📁 [CallerFile1.js] (Line [number])
```javascript
[actual calling code]
```
- **Context**: [why this file calls the function]
- **Parameters Used**: [list of params]
- **Risk Impact**: [what breaks if function changes]

#### 📁 [CallerFile2.js] (Line [number])
```javascript
[actual calling code]
```
- **Context**: [why this file calls the function]
- **Parameters Used**: [list of params]
- **Risk Impact**: [what breaks if function changes]

### Dependencies
- **Calls**: [list of functions this function calls]
- **Called By**: [list of functions that call this function]
- **External Libraries**: [any external deps]

### Change History
| Date | Version | Change | Impact | Files Affected |
|------|---------|--------|--------|-----------------|
| 2024-01-15 | v1.2 | Added tax parameter | Breaking | ProductCard.js, Checkout.js |
| 2024-01-10 | v1.1 | Fixed discount calculation | Non-breaking | All callers |

### Testing Coverage
- **Unit Tests**: [✅/❌] [path to test file]
- **Integration Tests**: [✅/❌] [path to test file]
- **Caller Tests**: [✅/❌] [list of caller test files]

### Migration Notes
```javascript
// If function signature changes, provide migration examples
// OLD:
calculatePrice(product, 0.1)

// NEW:
calculatePrice(product, {discount: 0.1})
```

---
```

## 🤖 Auto-Generation Script Template

### JavaScript/Node.js Scanner
```javascript
// function-scanner.js
const fs = require('fs');
const path = require('path');
const babel = require('@babel/parser');
const traverse = require('@babel/traverse').default;

class FunctionIndexGenerator {
  constructor(projectPath) {
    this.projectPath = projectPath;
    this.functions = new Map();
    this.callers = new Map();
  }

  async scanProject() {
    const files = this.getAllJSFiles(this.projectPath);
    
    for (const file of files) {
      await this.scanFile(file);
    }
    
    return this.generateIndex();
  }

  async scanFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const ast = babel.parse(content, {
      sourceType: 'module',
      plugins: ['jsx', 'typescript']
    });

    traverse(ast, {
      // Find function definitions
      FunctionDeclaration: (path) => {
        this.recordFunction(path, filePath);
      },
      
      // Find function calls
      CallExpression: (path) => {
        this.recordFunctionCall(path, filePath);
      }
    });
  }

  recordFunction(path, filePath) {
    const functionName = path.node.id.name;
    const lineNumber = path.node.loc.start.line;
    
    this.functions.set(functionName, {
      name: functionName,
      file: filePath,
      line: lineNumber,
      params: path.node.params.map(p => p.name),
      lastModified: fs.statSync(filePath).mtime
    });
  }

  recordFunctionCall(path, filePath) {
    const functionName = path.node.callee.name;
    const lineNumber = path.node.loc.start.line;
    
    if (!this.callers.has(functionName)) {
      this.callers.set(functionName, []);
    }
    
    this.callers.get(functionName).push({
      file: filePath,
      line: lineNumber,
      params: path.node.arguments.map(arg => this.getArgString(arg))
    });
  }

  generateIndex() {
    let markdown = '# Function Index\n\n';
    
    for (const [functionName, functionInfo] of this.functions) {
      const callers = this.callers.get(functionName) || [];
      const riskLevel = this.calculateRiskLevel(callers.length);
      
      markdown += this.generateFunctionSection(functionInfo, callers, riskLevel);
    }
    
    return markdown;
  }

  calculateRiskLevel(callerCount) {
    if (callerCount >= 5) return 'CRITICAL';
    if (callerCount >= 3) return 'HIGH';
    if (callerCount >= 2) return 'MEDIUM';
    return 'LOW';
  }
}

// Usage
const generator = new FunctionIndexGenerator('./src');
generator.scanProject().then(index => {
  fs.writeFileSync('./docs/function-index.md', index);
  console.log('Function index generated!');
});
```

## 📝 Manual Function Index Template

### Quick Entry Format
```markdown
## [functionName]
**File**: [file]:[line] | **Risk**: [level] | **Callers**: [count]

**Signature**: `[signature]`

**Callers**:
- [file1]:[line] - `[calling code]`
- [file2]:[line] - `[calling code]`

**Notes**: [any important notes]

---
```

### Example Entry
```markdown
## calculatePrice
**File**: utils/pricing.js:15 | **Risk**: HIGH | **Callers**: 4

**Signature**: `calculatePrice(product, options = {})`

**Callers**:
- ProductCard.js:45 - `calculatePrice(product, {discount: 0.1})`
- Checkout.js:23 - `calculatePrice(product, {tax: 0.08, shipping: 15})`
- Cart.js:67 - `calculatePrice(product, {discount: userDiscount})`
- OrderSummary.js:34 - `calculatePrice(item, {tax: regionTax})`

**Notes**: Critical pricing function - any changes require thorough testing

---
```

## 🔧 Integration with Development Workflow

### Pre-Commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check if any functions are being modified
modified_files=$(git diff --cached --name-only | grep -E '\.(js|ts|jsx|tsx)$')

if [ ! -z "$modified_files" ]; then
  echo "Checking function modifications..."
  
  # Run function impact analysis
  node scripts/check-function-impact.js $modified_files
  
  if [ $? -ne 0 ]; then
    echo "❌ Function modification detected - please review impact"
    exit 1
  fi
fi
```

### VS Code Extension Integration
```json
// .vscode/settings.json
{
  "functionIndex.enabled": true,
  "functionIndex.autoUpdate": true,
  "functionIndex.warnOnModification": true,
  "functionIndex.indexFile": "./docs/function-index.md"
}
```

## 📊 Metrics and Reporting

### Function Risk Dashboard
```markdown
# Function Risk Report

## 🔴 Critical Risk Functions (5+ callers)
- calculatePrice (6 callers)
- formatCurrency (5 callers)

## 🟡 High Risk Functions (3-4 callers)
- validateInput (4 callers)
- sendNotification (3 callers)

## 🟢 Low Risk Functions (1-2 callers)
- [list of low risk functions]

## 📈 Trends
- Functions added this week: 5
- Functions modified this week: 12
- Breaking changes this week: 2
```

Template này cung cấp framework hoàn chỉnh để implement Function Index System! 🚀