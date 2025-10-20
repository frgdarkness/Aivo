# Dependency Mapping System

## 🗺️ Track Caller-Callee Relationships

### Core Objective
> **"Visualize và track tất cả function dependencies để predict impact của modifications"**

## 🔍 Dependency Discovery Engine

### Static Analysis Scanner
```javascript
class DependencyScanner {
  constructor(projectPath) {
    this.projectPath = projectPath;
    this.dependencyGraph = new Map();
    this.reverseGraph = new Map(); // callee -> callers
    this.fileGraph = new Map(); // file-level dependencies
  }
  
  async scanProject() {
    const files = await this.getAllSourceFiles();
    const results = {
      functions: new Map(),
      files: new Map(),
      crossFileReferences: [],
      circularDependencies: [],
      orphanedFunctions: [],
      hotspotFunctions: [] // functions with many callers
    };
    
    // Phase 1: Extract all function definitions
    for (const file of files) {
      const functions = await this.extractFunctions(file);
      results.functions.set(file, functions);
    }
    
    // Phase 2: Find all function calls
    for (const file of files) {
      const calls = await this.extractFunctionCalls(file);
      await this.mapDependencies(file, calls, results);
    }
    
    // Phase 3: Analysis
    results.circularDependencies = this.detectCircularDependencies();
    results.orphanedFunctions = this.findOrphanedFunctions();
    results.hotspotFunctions = this.identifyHotspots();
    
    return results;
  }
  
  async extractFunctions(filePath) {
    const content = await fs.readFile(filePath, 'utf8');
    const ast = this.parseToAST(content);
    const functions = [];
    
    this.traverseAST(ast, (node) => {
      if (this.isFunctionDeclaration(node)) {
        functions.push({
          name: node.name,
          type: node.type, // function, method, arrow, async
          parameters: this.extractParameters(node),
          returnType: this.inferReturnType(node),
          startLine: node.loc.start.line,
          endLine: node.loc.end.line,
          complexity: this.calculateComplexity(node),
          isExported: this.isExported(node),
          isAsync: node.async,
          dependencies: [] // will be filled in phase 2
        });
      }
    });
    
    return functions;
  }
  
  async extractFunctionCalls(filePath) {
    const content = await fs.readFile(filePath, 'utf8');
    const ast = this.parseToAST(content);
    const calls = [];
    
    this.traverseAST(ast, (node) => {
      if (this.isFunctionCall(node)) {
        calls.push({
          functionName: this.extractFunctionName(node),
          arguments: this.extractArguments(node),
          line: node.loc.start.line,
          column: node.loc.start.column,
          context: this.extractContext(node),
          isConditional: this.isInConditionalBlock(node),
          isInLoop: this.isInLoop(node),
          callType: this.determineCallType(node) // direct, method, callback
        });
      }
    });
    
    return calls;
  }
}
```

### Dynamic Analysis Tracker
```javascript
class RuntimeDependencyTracker {
  constructor() {
    this.callStack = [];
    this.executionGraph = new Map();
    this.performanceMetrics = new Map();
  }
  
  // Instrument functions for runtime tracking
  instrumentFunction(originalFunction, functionName, filePath) {
    const self = this;
    
    return function(...args) {
      const callId = self.generateCallId();
      const startTime = performance.now();
      
      // Record call start
      self.recordFunctionCall({
        callId,
        functionName,
        filePath,
        arguments: args,
        caller: self.getCurrentCaller(),
        timestamp: Date.now(),
        startTime
      });
      
      try {
        const result = originalFunction.apply(this, args);
        
        // Handle async functions
        if (result instanceof Promise) {
          return result.then(asyncResult => {
            self.recordFunctionReturn(callId, asyncResult, performance.now() - startTime);
            return asyncResult;
          }).catch(error => {
            self.recordFunctionError(callId, error, performance.now() - startTime);
            throw error;
          });
        }
        
        // Handle sync functions
        self.recordFunctionReturn(callId, result, performance.now() - startTime);
        return result;
        
      } catch (error) {
        self.recordFunctionError(callId, error, performance.now() - startTime);
        throw error;
      }
    };
  }
  
  recordFunctionCall(callInfo) {
    this.callStack.push(callInfo);
    
    // Update execution graph
    if (!this.executionGraph.has(callInfo.functionName)) {
      this.executionGraph.set(callInfo.functionName, {
        totalCalls: 0,
        callers: new Set(),
        callees: new Set(),
        averageExecutionTime: 0,
        errors: 0
      });
    }
    
    const functionStats = this.executionGraph.get(callInfo.functionName);
    functionStats.totalCalls++;
    
    if (callInfo.caller) {
      functionStats.callers.add(callInfo.caller);
      
      // Update caller's callees
      if (this.executionGraph.has(callInfo.caller)) {
        this.executionGraph.get(callInfo.caller).callees.add(callInfo.functionName);
      }
    }
  }
  
  generateDependencyReport() {
    const report = {
      totalFunctions: this.executionGraph.size,
      totalCalls: 0,
      hotspots: [],
      bottlenecks: [],
      unusedFunctions: [],
      circularCalls: [],
      dependencyChains: []
    };
    
    this.executionGraph.forEach((stats, functionName) => {
      report.totalCalls += stats.totalCalls;
      
      // Identify hotspots (frequently called)
      if (stats.totalCalls > 100) {
        report.hotspots.push({ functionName, calls: stats.totalCalls });
      }
      
      // Identify bottlenecks (slow execution)
      if (stats.averageExecutionTime > 100) {
        report.bottlenecks.push({ 
          functionName, 
          avgTime: stats.averageExecutionTime 
        });
      }
      
      // Identify unused functions
      if (stats.totalCalls === 0) {
        report.unusedFunctions.push(functionName);
      }
    });
    
    return report;
  }
}
```

## 📊 Dependency Visualization

### Graph Generation
```javascript
class DependencyVisualizer {
  constructor(dependencyData) {
    this.data = dependencyData;
    this.graphOptions = {
      layout: 'hierarchical', // hierarchical, force-directed, circular
      showMetrics: true,
      highlightCriticalPaths: true,
      groupByFile: false
    };
  }
  
  generateMermaidDiagram() {
    let mermaid = 'graph TD\n';
    const nodes = new Set();
    const edges = [];
    
    // Generate nodes and edges
    this.data.functions.forEach((functions, file) => {
      functions.forEach(func => {
        const nodeId = this.sanitizeNodeId(`${file}_${func.name}`);
        const label = `${func.name}\n(${func.parameters.length} params)`;
        
        nodes.add(`${nodeId}["${label}"]`);
        
        func.dependencies.forEach(dep => {
          const depNodeId = this.sanitizeNodeId(`${dep.file}_${dep.name}`);
          edges.push(`${nodeId} --> ${depNodeId}`);
        });
      });
    });
    
    // Add nodes
    nodes.forEach(node => {
      mermaid += `  ${node}\n`;
    });
    
    // Add edges
    edges.forEach(edge => {
      mermaid += `  ${edge}\n`;
    });
    
    // Add styling
    mermaid += this.generateStyling();
    
    return mermaid;
  }
  
  generateD3ForceGraph() {
    const nodes = [];
    const links = [];
    const nodeMap = new Map();
    
    // Create nodes
    this.data.functions.forEach((functions, file) => {
      functions.forEach(func => {
        const nodeId = `${file}_${func.name}`;
        const node = {
          id: nodeId,
          name: func.name,
          file: file,
          type: func.type,
          complexity: func.complexity,
          callerCount: this.getCallerCount(func.name),
          group: this.getFileGroup(file)
        };
        
        nodes.push(node);
        nodeMap.set(nodeId, node);
      });
    });
    
    // Create links
    this.data.functions.forEach((functions, file) => {
      functions.forEach(func => {
        const sourceId = `${file}_${func.name}`;
        
        func.dependencies.forEach(dep => {
          const targetId = `${dep.file}_${dep.name}`;
          
          if (nodeMap.has(targetId)) {
            links.push({
              source: sourceId,
              target: targetId,
              strength: dep.callCount || 1,
              type: dep.callType || 'direct'
            });
          }
        });
      });
    });
    
    return { nodes, links };
  }
  
  generateInteractiveHTML() {
    const graphData = this.generateD3ForceGraph();
    
    return `
<!DOCTYPE html>
<html>
<head>
  <title>Function Dependency Map</title>
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <style>
    .node { cursor: pointer; }
    .node:hover { stroke: #000; stroke-width: 2px; }
    .link { stroke: #999; stroke-opacity: 0.6; }
    .tooltip { position: absolute; background: rgba(0,0,0,0.8); color: white; padding: 8px; border-radius: 4px; }
  </style>
</head>
<body>
  <div id="graph"></div>
  <div id="controls">
    <button onclick="toggleLayout()">Toggle Layout</button>
    <button onclick="highlightHotspots()">Highlight Hotspots</button>
    <button onclick="showCriticalPath()">Critical Path</button>
  </div>
  
  <script>
    const data = ${JSON.stringify(graphData)};
    
    // D3.js visualization code
    const width = 1200, height = 800;
    
    const svg = d3.select("#graph")
      .append("svg")
      .attr("width", width)
      .attr("height", height);
    
    const simulation = d3.forceSimulation(data.nodes)
      .force("link", d3.forceLink(data.links).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-300))
      .force("center", d3.forceCenter(width / 2, height / 2));
    
    // Render links
    const link = svg.append("g")
      .selectAll("line")
      .data(data.links)
      .enter().append("line")
      .attr("class", "link")
      .attr("stroke-width", d => Math.sqrt(d.strength));
    
    // Render nodes
    const node = svg.append("g")
      .selectAll("circle")
      .data(data.nodes)
      .enter().append("circle")
      .attr("class", "node")
      .attr("r", d => 5 + d.complexity * 2)
      .attr("fill", d => this.getNodeColor(d))
      .call(d3.drag()
        .on("start", dragstarted)
        .on("drag", dragged)
        .on("end", dragended));
    
    // Add labels
    const label = svg.append("g")
      .selectAll("text")
      .data(data.nodes)
      .enter().append("text")
      .text(d => d.name)
      .attr("font-size", 10)
      .attr("dx", 12)
      .attr("dy", 4);
    
    // Simulation tick
    simulation.on("tick", () => {
      link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);
      
      node
        .attr("cx", d => d.x)
        .attr("cy", d => d.y);
      
      label
        .attr("x", d => d.x)
        .attr("y", d => d.y);
    });
    
    // Drag functions
    function dragstarted(event, d) {
      if (!event.active) simulation.alphaTarget(0.3).restart();
      d.fx = d.x;
      d.fy = d.y;
    }
    
    function dragged(event, d) {
      d.fx = event.x;
      d.fy = event.y;
    }
    
    function dragended(event, d) {
      if (!event.active) simulation.alphaTarget(0);
      d.fx = null;
      d.fy = null;
    }
  </script>
</body>
</html>
    `;
  }
}
```

### Impact Analysis Engine
```javascript
class ImpactAnalyzer {
  constructor(dependencyGraph) {
    this.graph = dependencyGraph;
    this.impactCache = new Map();
  }
  
  analyzeModificationImpact(functionName, modificationType) {
    const cacheKey = `${functionName}_${modificationType}`;
    
    if (this.impactCache.has(cacheKey)) {
      return this.impactCache.get(cacheKey);
    }
    
    const impact = {
      directImpact: this.getDirectCallers(functionName),
      indirectImpact: this.getIndirectCallers(functionName),
      riskLevel: 'LOW',
      affectedFiles: new Set(),
      breakingChanges: [],
      suggestedActions: []
    };
    
    // Calculate risk level
    const totalAffected = impact.directImpact.length + impact.indirectImpact.length;
    
    if (totalAffected === 0) {
      impact.riskLevel = 'NONE';
    } else if (totalAffected <= 2) {
      impact.riskLevel = 'LOW';
    } else if (totalAffected <= 5) {
      impact.riskLevel = 'MEDIUM';
    } else if (totalAffected <= 10) {
      impact.riskLevel = 'HIGH';
    } else {
      impact.riskLevel = 'CRITICAL';
    }
    
    // Analyze modification type impact
    switch (modificationType) {
      case 'SIGNATURE_CHANGE':
        impact.breakingChanges = this.analyzeSignatureChange(functionName);
        break;
      case 'RETURN_TYPE_CHANGE':
        impact.breakingChanges = this.analyzeReturnTypeChange(functionName);
        break;
      case 'PARAMETER_REMOVAL':
        impact.breakingChanges = this.analyzeParameterRemoval(functionName);
        break;
      case 'LOGIC_CHANGE':
        impact.breakingChanges = this.analyzeLogicChange(functionName);
        break;
    }
    
    // Generate suggestions
    impact.suggestedActions = this.generateSuggestions(impact);
    
    // Collect affected files
    [...impact.directImpact, ...impact.indirectImpact].forEach(caller => {
      impact.affectedFiles.add(caller.file);
    });
    
    this.impactCache.set(cacheKey, impact);
    return impact;
  }
  
  getDirectCallers(functionName) {
    const callers = [];
    
    this.graph.functions.forEach((functions, file) => {
      functions.forEach(func => {
        func.dependencies.forEach(dep => {
          if (dep.name === functionName) {
            callers.push({
              name: func.name,
              file: file,
              line: dep.line,
              callType: dep.callType,
              isConditional: dep.isConditional
            });
          }
        });
      });
    });
    
    return callers;
  }
  
  getIndirectCallers(functionName, visited = new Set()) {
    if (visited.has(functionName)) {
      return []; // Prevent infinite recursion
    }
    
    visited.add(functionName);
    const indirectCallers = [];
    const directCallers = this.getDirectCallers(functionName);
    
    directCallers.forEach(caller => {
      const nestedCallers = this.getIndirectCallers(caller.name, visited);
      indirectCallers.push(...nestedCallers);
    });
    
    return indirectCallers;
  }
  
  generateDependencyChain(fromFunction, toFunction) {
    const chains = [];
    const visited = new Set();
    
    const findChains = (current, target, path) => {
      if (visited.has(current)) return;
      if (current === target) {
        chains.push([...path, current]);
        return;
      }
      
      visited.add(current);
      const callers = this.getDirectCallers(current);
      
      callers.forEach(caller => {
        findChains(caller.name, target, [...path, current]);
      });
      
      visited.delete(current);
    };
    
    findChains(fromFunction, toFunction, []);
    return chains;
  }
}
```

## 🔄 Real-time Dependency Tracking

### File Watcher Integration
```javascript
class RealTimeDependencyTracker {
  constructor(projectPath) {
    this.projectPath = projectPath;
    this.dependencyGraph = new Map();
    this.watchers = new Map();
    this.updateQueue = [];
    this.isProcessing = false;
  }
  
  startWatching() {
    const chokidar = require('chokidar');
    
    const watcher = chokidar.watch(this.projectPath, {
      ignored: /node_modules|.git/,
      persistent: true,
      ignoreInitial: false
    });
    
    watcher
      .on('add', (filePath) => this.handleFileChange(filePath, 'ADD'))
      .on('change', (filePath) => this.handleFileChange(filePath, 'CHANGE'))
      .on('unlink', (filePath) => this.handleFileChange(filePath, 'DELETE'));
    
    this.watchers.set('main', watcher);
  }
  
  async handleFileChange(filePath, changeType) {
    if (!this.isSourceFile(filePath)) return;
    
    const updateTask = {
      filePath,
      changeType,
      timestamp: Date.now()
    };
    
    this.updateQueue.push(updateTask);
    
    if (!this.isProcessing) {
      await this.processUpdateQueue();
    }
  }
  
  async processUpdateQueue() {
    this.isProcessing = true;
    
    while (this.updateQueue.length > 0) {
      const task = this.updateQueue.shift();
      await this.processFileUpdate(task);
    }
    
    this.isProcessing = false;
  }
  
  async processFileUpdate(task) {
    const { filePath, changeType } = task;
    
    try {
      switch (changeType) {
        case 'ADD':
        case 'CHANGE':
          await this.updateFileDependencies(filePath);
          break;
        case 'DELETE':
          this.removeFileDependencies(filePath);
          break;
      }
      
      // Notify subscribers
      this.notifyDependencyChange(filePath, changeType);
      
    } catch (error) {
      console.error(`Error processing file update for ${filePath}:`, error);
    }
  }
  
  async updateFileDependencies(filePath) {
    const scanner = new DependencyScanner(this.projectPath);
    const functions = await scanner.extractFunctions(filePath);
    const calls = await scanner.extractFunctionCalls(filePath);
    
    // Update dependency graph
    this.dependencyGraph.set(filePath, {
      functions,
      calls,
      lastUpdated: Date.now()
    });
    
    // Update cross-references
    this.updateCrossReferences(filePath, functions, calls);
  }
  
  notifyDependencyChange(filePath, changeType) {
    const event = {
      type: 'DEPENDENCY_CHANGE',
      filePath,
      changeType,
      timestamp: Date.now(),
      affectedFunctions: this.getAffectedFunctions(filePath)
    };
    
    // Emit to subscribers (IDE extensions, CI/CD, etc.)
    this.emit('dependencyChange', event);
  }
}
```

## 📈 Metrics and Analytics

### Dependency Health Metrics
```javascript
class DependencyMetrics {
  constructor(dependencyGraph) {
    this.graph = dependencyGraph;
  }
  
  calculateHealthScore() {
    const metrics = {
      totalFunctions: 0,
      totalDependencies: 0,
      circularDependencies: 0,
      orphanedFunctions: 0,
      hotspotFunctions: 0,
      averageFanOut: 0,
      averageFanIn: 0,
      maxDepth: 0,
      couplingScore: 0,
      cohesionScore: 0
    };
    
    // Calculate basic metrics
    this.graph.functions.forEach((functions, file) => {
      metrics.totalFunctions += functions.length;
      
      functions.forEach(func => {
        metrics.totalDependencies += func.dependencies.length;
        
        // Fan-out (dependencies)
        const fanOut = func.dependencies.length;
        metrics.averageFanOut += fanOut;
        
        // Fan-in (callers)
        const fanIn = this.getCallerCount(func.name);
        metrics.averageFanIn += fanIn;
        
        // Hotspot detection
        if (fanIn > 5) {
          metrics.hotspotFunctions++;
        }
        
        // Orphan detection
        if (fanIn === 0 && !func.isExported) {
          metrics.orphanedFunctions++;
        }
      });
    });
    
    // Calculate averages
    if (metrics.totalFunctions > 0) {
      metrics.averageFanOut /= metrics.totalFunctions;
      metrics.averageFanIn /= metrics.totalFunctions;
    }
    
    // Calculate coupling and cohesion
    metrics.couplingScore = this.calculateCoupling();
    metrics.cohesionScore = this.calculateCohesion();
    
    // Calculate overall health score (0-100)
    const healthScore = this.calculateOverallHealth(metrics);
    
    return {
      ...metrics,
      healthScore,
      recommendations: this.generateRecommendations(metrics)
    };
  }
  
  calculateCoupling() {
    let totalCoupling = 0;
    let totalPairs = 0;
    
    this.graph.functions.forEach((functions, file) => {
      functions.forEach(func => {
        const externalDeps = func.dependencies.filter(dep => dep.file !== file);
        totalCoupling += externalDeps.length;
        totalPairs++;
      });
    });
    
    return totalPairs > 0 ? totalCoupling / totalPairs : 0;
  }
  
  calculateCohesion() {
    let totalCohesion = 0;
    let fileCount = 0;
    
    this.graph.functions.forEach((functions, file) => {
      const internalCalls = functions.reduce((sum, func) => {
        const internalDeps = func.dependencies.filter(dep => dep.file === file);
        return sum + internalDeps.length;
      }, 0);
      
      const totalCalls = functions.reduce((sum, func) => {
        return sum + func.dependencies.length;
      }, 0);
      
      if (totalCalls > 0) {
        totalCohesion += internalCalls / totalCalls;
        fileCount++;
      }
    });
    
    return fileCount > 0 ? totalCohesion / fileCount : 0;
  }
  
  generateTrendReport(historicalData) {
    const trends = {
      functionGrowth: [],
      dependencyGrowth: [],
      couplingTrend: [],
      healthTrend: []
    };
    
    historicalData.forEach((snapshot, index) => {
      trends.functionGrowth.push({
        date: snapshot.date,
        count: snapshot.metrics.totalFunctions,
        change: index > 0 ? 
          snapshot.metrics.totalFunctions - historicalData[index-1].metrics.totalFunctions : 0
      });
      
      trends.dependencyGrowth.push({
        date: snapshot.date,
        count: snapshot.metrics.totalDependencies,
        change: index > 0 ? 
          snapshot.metrics.totalDependencies - historicalData[index-1].metrics.totalDependencies : 0
      });
      
      trends.couplingTrend.push({
        date: snapshot.date,
        score: snapshot.metrics.couplingScore
      });
      
      trends.healthTrend.push({
        date: snapshot.date,
        score: snapshot.metrics.healthScore
      });
    });
    
    return trends;
  }
}
```

## 🎯 Integration Examples

### VS Code Extension Integration
```javascript
// VS Code extension integration
class VSCodeDependencyExtension {
  constructor() {
    this.dependencyTracker = new RealTimeDependencyTracker(vscode.workspace.rootPath);
    this.decorationTypes = new Map();
  }
  
  activate(context) {
    // Register commands
    const showDependencies = vscode.commands.registerCommand(
      'extension.showDependencies',
      () => this.showFunctionDependencies()
    );
    
    const analyzeImpact = vscode.commands.registerCommand(
      'extension.analyzeImpact',
      () => this.analyzeModificationImpact()
    );
    
    // Register hover provider
    const hoverProvider = vscode.languages.registerHoverProvider(
      { scheme: 'file', language: 'javascript' },
      {
        provideHover: (document, position) => {
          return this.provideDependencyHover(document, position);
        }
      }
    );
    
    context.subscriptions.push(showDependencies, analyzeImpact, hoverProvider);
    
    // Start dependency tracking
    this.dependencyTracker.startWatching();
  }
  
  async showFunctionDependencies() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) return;
    
    const functionName = this.getFunctionAtCursor(editor);
    if (!functionName) return;
    
    const dependencies = await this.dependencyTracker.getDependencies(functionName);
    
    // Create webview panel
    const panel = vscode.window.createWebviewPanel(
      'functionDependencies',
      `Dependencies: ${functionName}`,
      vscode.ViewColumn.Two,
      { enableScripts: true }
    );
    
    const visualizer = new DependencyVisualizer(dependencies);
    panel.webview.html = visualizer.generateInteractiveHTML();
  }
  
  async provideDependencyHover(document, position) {
    const range = document.getWordRangeAtPosition(position);
    const word = document.getText(range);
    
    const functionInfo = await this.dependencyTracker.getFunctionInfo(word);
    if (!functionInfo) return;
    
    const callerCount = functionInfo.callers.length;
    const dependencyCount = functionInfo.dependencies.length;
    
    const hoverText = new vscode.MarkdownString();
    hoverText.appendMarkdown(`**Function: ${word}**\n\n`);
    hoverText.appendMarkdown(`📞 **Callers**: ${callerCount}\n`);
    hoverText.appendMarkdown(`🔗 **Dependencies**: ${dependencyCount}\n`);
    hoverText.appendMarkdown(`⚠️ **Risk Level**: ${functionInfo.riskLevel}\n`);
    
    if (callerCount > 0) {
      hoverText.appendMarkdown(`\n**Called by:**\n`);
      functionInfo.callers.slice(0, 5).forEach(caller => {
        hoverText.appendMarkdown(`- ${caller.name} (${caller.file})\n`);
      });
      
      if (callerCount > 5) {
        hoverText.appendMarkdown(`- ... and ${callerCount - 5} more\n`);
      }
    }
    
    return new vscode.Hover(hoverText, range);
  }
}
```

### CI/CD Pipeline Integration
```yaml
# GitHub Actions workflow
name: Dependency Analysis

on:
  pull_request:
    branches: [ main ]

jobs:
  dependency-analysis:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: 0  # Full history for comparison
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '16'
    
    - name: Install dependencies
      run: npm install
    
    - name: Run dependency analysis
      run: |
        node scripts/analyze-dependencies.js \
          --base-ref origin/main \
          --head-ref HEAD \
          --output dependency-report.json
    
    - name: Check breaking changes
      run: |
        node scripts/check-breaking-changes.js \
          --report dependency-report.json \
          --threshold HIGH
    
    - name: Comment PR with analysis
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const report = JSON.parse(fs.readFileSync('dependency-report.json'));
          
          let comment = '## 🔍 Dependency Analysis Report\n\n';
          
          if (report.riskLevel === 'HIGH' || report.riskLevel === 'CRITICAL') {
            comment += '⚠️ **HIGH RISK CHANGES DETECTED**\n\n';
          }
          
          comment += `- **Functions Modified**: ${report.modifiedFunctions.length}\n`;
          comment += `- **Risk Level**: ${report.riskLevel}\n`;
          comment += `- **Affected Files**: ${report.affectedFiles.length}\n\n`;
          
          if (report.breakingChanges.length > 0) {
            comment += '### 💥 Breaking Changes\n\n';
            report.breakingChanges.forEach(change => {
              comment += `- **${change.function}**: ${change.description}\n`;
            });
          }
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });
```

Dependency Mapping System này sẽ cung cấp visibility hoàn toàn về function relationships và predict impact của mọi thay đổi! 🗺️🔍