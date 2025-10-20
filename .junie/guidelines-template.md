# Junie AI Guidelines Template

> **🎯 Quick Start Template for Junie IDE**  
> Use this template for projects without .ai-system integration

## 🚀 Basic Setup

### Project Information
```markdown
Project Type: [Android/iOS/Web/Backend/Cross-platform]
Main Language: [Kotlin/Java/Swift/TypeScript/Python/PHP]
Framework: [Jetpack Compose/SwiftUI/React/Vue/Laravel/Spring Boot]
```

### Development Standards

**Code Quality**:
- Use meaningful variable and function names
- Follow language-specific conventions (camelCase, snake_case, etc.)
- Write self-documenting code with clear comments
- Implement proper error handling

**Testing Strategy**:
- Write unit tests for business logic
- Include integration tests for API endpoints
- Add UI tests for critical user flows
- Maintain test coverage above 80%

**Security Practices**:
- Validate all user inputs
- Use secure authentication methods
- Protect sensitive data (API keys, passwords)
- Follow OWASP security guidelines

### Platform-Specific Guidelines

#### Android Development
```markdown
- Use Jetpack Compose for modern UI
- Follow Material Design 3 guidelines
- Implement proper lifecycle management
- Use Room for local database
- Apply MVVM or Clean Architecture
```

#### iOS Development
```markdown
- Use SwiftUI for modern UI
- Follow Human Interface Guidelines
- Implement proper memory management
- Use Core Data for local storage
- Apply MVVM or VIPER architecture
```

#### Web Development
```markdown
- Use modern frameworks (React, Vue, Angular)
- Implement responsive design
- Optimize for performance (lazy loading, caching)
- Follow accessibility guidelines (WCAG)
- Use TypeScript for type safety
```

#### Backend Development
```markdown
- Design RESTful APIs
- Implement proper authentication/authorization
- Use database migrations
- Add comprehensive logging
- Implement rate limiting and caching
```

## 🔧 IntelliJ Integration

**Leverage IntelliJ Features**:
- Use built-in code inspections
- Apply automated refactoring tools
- Utilize live templates for common patterns
- Integrate with version control (Git)
- Use debugging and profiling tools

**Code Style**:
- Configure IntelliJ code style settings
- Use IntelliJ's formatting on save
- Enable import optimization
- Set up code inspection profiles

## 📋 Task Management

**Development Workflow**:
1. **Planning**: Break down features into small tasks
2. **Implementation**: Focus on one task at a time
3. **Testing**: Write tests before or during implementation
4. **Review**: Check code quality and performance
5. **Documentation**: Update relevant documentation

**Quality Checklist**:
- [ ] Code follows project conventions
- [ ] All tests pass
- [ ] No security vulnerabilities
- [ ] Performance is acceptable
- [ ] Documentation is updated

## 🚨 Common Patterns to Follow

**Error Handling**:
```kotlin
// Android/Kotlin example
try {
    val result = riskyOperation()
    handleSuccess(result)
} catch (e: Exception) {
    handleError(e)
    logError("Operation failed", e)
}
```

**Async Operations**:
```kotlin
// Use coroutines for async operations
viewModelScope.launch {
    try {
        val data = repository.fetchData()
        _uiState.value = UiState.Success(data)
    } catch (e: Exception) {
        _uiState.value = UiState.Error(e.message)
    }
}
```

**Dependency Injection**:
```kotlin
// Use Hilt or similar DI framework
@HiltViewModel
class MyViewModel @Inject constructor(
    private val repository: MyRepository
) : ViewModel()
```

## 🔄 Upgrade to .ai-system

**When your project grows, consider upgrading to the full .ai-system:**

1. Add `.ai-system/` directory to your project
2. Replace this template with full `.junie/guidelines.md`
3. Gain access to:
   - Advanced agent selection
   - Cross-IDE synchronization
   - Workflow automation
   - Enhanced task management

**Migration Command**:
```bash
# Copy .ai-system from Base-AI-Project
cp -r /path/to/Base-AI-Project/.ai-system ./
# Replace guidelines
cp .junie/guidelines.md .junie/guidelines-backup.md
# Use the full guidelines.md template
```

---

## 📚 Resources

**Documentation**:
- [IntelliJ IDEA Documentation](https://www.jetbrains.com/help/idea/)
- [Junie AI Documentation](https://www.jetbrains.com/help/junie/)
- Platform-specific documentation based on your project type

**Best Practices**:
- Clean Code by Robert Martin
- Effective Java by Joshua Bloch (for Java/Kotlin)
- Swift Style Guide (for iOS)
- React Best Practices (for React projects)

---

*This is a basic template. For advanced AI coordination and cross-IDE workflows, upgrade to the full .ai-system integration.*