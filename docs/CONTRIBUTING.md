# Contributing to ObservabilitySDK4D

Thank you for your interest in contributing to ObservabilitySDK4D! We welcome contributions from the community and are pleased that you want to help make this project better.

## ?? Language Support

This project supports documentation in multiple languages:
- **English** (`docs/en/`)
- **Portuguese** (`docs/pt-BR/`)
- **Spanish** (`docs/es/`)

When contributing to documentation, please consider updating all language versions if applicable.

## ?? Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/ObservabilitySDK4D.git
   cd ObservabilitySDK4D
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## ?? Contribution Guidelines

### Code Style

- Follow existing Pascal/Delphi coding conventions
- Use meaningful variable and method names
- Add documentation for public methods and classes
- Maintain compatibility with Delphi 10.3+

### Testing

- Add unit tests for new functionality
- Ensure existing tests pass
- Test with multiple providers when applicable
- Include integration tests for new providers

### Documentation

- Update relevant documentation in all languages
- Include code examples for new features
- Update the provider support matrix if applicable
- Add changelog entries for significant changes

### Commit Messages

Use clear and descriptive commit messages:
```
Add: New feature description
Fix: Bug fix description
Docs: Documentation update description
Refactor: Code refactoring description
```

## ?? Development Setup

### Prerequisites

- Delphi 10.3 Rio or later
- Git for version control
- Docker for testing provider integrations

### Provider Development

When adding a new provider:

1. Create a new unit in `source/providers/`
2. Implement the `IObservabilityProvider` interface
3. Add configuration classes in `source/core/`
4. Create samples and Docker environment in `Samples/`
5. Update documentation and support matrix

### Testing Environment

Use the provided Docker environments for testing:

```bash
# Test with Elastic APM
cd Samples/Elastic
.\elastic.ps1 start

# Test with Jaeger
cd Samples/Jaeger
.\jaeger.ps1 start

# Test with Sentry
cd Samples/Sentry
.\sentry.ps1 start

# Test with Datadog
cd Samples/Datadog
.\datadog.ps1 start
```

## ?? Pull Request Process

1. **Update documentation** in all supported languages
2. **Add or update tests** for your changes
3. **Ensure all tests pass**
4. **Update the README** if you change functionality
5. **Create a pull request** with a clear description

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Breaking change

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Documentation updated (all languages)
- [ ] Tests added for new functionality
- [ ] No breaking changes (or breaking changes documented)
```

## ?? Reporting Issues

When reporting issues, please include:

- **Delphi version** and platform (Windows/Linux)
- **Provider type** and configuration
- **Minimal reproduction code**
- **Expected vs actual behavior**
- **Debug output** (if applicable)

### Issue Template

```markdown
## Environment
- Delphi Version: 
- Platform: Windows/Linux
- SDK Version: 
- Provider: Elastic/Jaeger/Sentry/Datadog/Console

## Description
Clear description of the issue

## Reproduction Steps
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What you expected to happen

## Actual Behavior
What actually happened

## Code Sample
```pascal
// Minimal code to reproduce the issue
```

## Additional Context
Any additional information
```

## ?? Feature Requests

We welcome feature requests! Please:

1. **Check existing issues** to avoid duplicates
2. **Describe the use case** clearly
3. **Explain the expected behavior**
4. **Consider backwards compatibility**

## ?? Documentation Guidelines

### Writing Style

- Use clear, concise language
- Include practical examples
- Explain concepts before diving into code
- Maintain consistency across languages

### Code Examples

- Always test code examples
- Use realistic scenarios
- Include error handling
- Show best practices

### Multi-Language Support

When updating documentation:

1. Update the English version first
2. Translate to Portuguese and Spanish
3. Ensure technical terms are consistent
4. Adapt examples to local conventions when appropriate

## ?? Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Help others learn and grow
- Provide constructive feedback
- Follow the project's code of conduct

### Communication

- Use GitHub Issues for bug reports
- Use GitHub Discussions for questions and ideas
- Be patient with response times
- Provide clear and detailed information

## ?? Release Process

Releases follow semantic versioning (SemVer):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

## ?? Recognition

Contributors will be recognized in:
- Release notes
- Contributors section
- Documentation acknowledgments

## ?? Getting Help

Need help contributing? Reach out through:

- **GitHub Discussions**: For questions and ideas
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check existing docs first

---

Thank you for contributing to ObservabilitySDK4D! Your efforts help make Delphi applications more observable and maintainable. ??