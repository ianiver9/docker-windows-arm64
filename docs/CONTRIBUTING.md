# Contributing to Docker for Windows ARM64

Thank you for your interest in contributing to this project! This guide will help you get started with contributing to the Docker for Windows ARM64 custom build.

## 🚀 Quick Start

1. **Fork** this repository
2. **Clone** your fork locally
3. **Set up** the development environment
4. **Make** your changes
5. **Test** your changes
6. **Submit** a pull request

## 📋 Prerequisites

### Development Environment

- **Linux-based system** (Ubuntu 20.04+, Fedora 35+, or similar)
- **Go 1.21+** for building Docker components
- **Git** for version control
- **Make** for build automation
- **4GB+ RAM** and **10GB+ disk space**

### Quick Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/docker-windows-arm64.git
cd docker-windows-arm64

# Setup development environment
./scripts/setup-environment.sh

# Verify environment
./scripts/validate-environment.sh
```

## 🛠️ Development Workflow

### 1. Setting Up Your Fork

```bash
# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-OWNER/docker-windows-arm64.git

# Fetch upstream changes
git fetch upstream

# Create feature branch
git checkout -b feature/your-feature-name upstream/main
```

### 2. Making Changes

#### Code Changes

- Follow Go coding standards and conventions
- Run `go fmt` and `go vet` on your code
- Add tests for new functionality
- Update documentation as needed

#### Build Script Changes

- Test scripts on multiple Linux distributions
- Ensure backward compatibility
- Add error handling and logging
- Update help text and comments

#### Documentation Changes

- Use clear, concise language
- Include code examples where appropriate
- Update table of contents if adding new sections
- Test all commands and examples

### 3. Testing Your Changes

```bash
# Clean previous builds
./scripts/clean.sh --all

# Test environment setup
./scripts/setup-environment.sh

# Build Docker components
./scripts/build-all.sh

# Create installer package
./scripts/create-installer.sh

# Run validation
./scripts/validate-environment.sh
```

### 4. Quality Checks

#### Code Quality

```bash
# Format Go code
find . -name "*.go" -exec go fmt {} \;

# Vet Go code
find . -name "*.go" -exec go vet {} \;

# Lint (if golangci-lint is available)
golangci-lint run
```

#### Shell Script Quality

```bash
# Check shell scripts (if shellcheck is available)
find scripts/ -name "*.sh" -exec shellcheck {} \;

# Test script execution
chmod +x scripts/*.sh
```

#### Documentation Quality

```bash
# Check markdown files (if markdownlint is available)
markdownlint docs/ *.md

# Spell check (if aspell is available)
find docs/ -name "*.md" -exec aspell check {} \;
```

## 📝 Contribution Types

### 🐛 Bug Fixes

- **Issue First**: Create or reference an existing issue
- **Minimal Changes**: Keep changes focused on the specific bug
- **Test Cases**: Add tests that verify the fix
- **Documentation**: Update docs if the fix changes behavior

### ✨ New Features

- **Feature Request**: Discuss the feature in an issue first
- **Design Document**: For large features, create a design document
- **Implementation**: Follow existing patterns and conventions
- **Testing**: Comprehensive tests for new functionality
- **Documentation**: Complete documentation for new features

### 📚 Documentation

- **Accuracy**: Ensure all information is correct and up-to-date
- **Completeness**: Cover all aspects of the topic
- **Examples**: Include practical examples and use cases
- **Clarity**: Write for users of all experience levels

### 🔧 Build System

- **Compatibility**: Test on multiple Linux distributions
- **Error Handling**: Robust error handling and logging
- **Documentation**: Update build documentation
- **CI/CD**: Update GitHub Actions workflows if needed

## 🏗️ Project Structure

```
docker-windows-arm64/
├── README.md                    # Main project documentation
├── LICENSE                     # Apache License 2.0
├── .gitignore                  # Git ignore rules
├── .github/
│   └── workflows/              # GitHub Actions CI/CD
├── scripts/
│   ├── build-all.sh           # Complete build process
│   ├── create-installer.sh    # Installer creation
│   ├── setup-environment.sh   # Environment setup
│   └── clean.sh               # Cleanup utilities
├── installer/
│   ├── Install-Docker.bat     # Windows installer
│   └── Docker-ARM64-Installer.ps1
├── docs/
│   ├── BUILD.md               # Build instructions
│   ├── INSTALL.md             # Installation guide
│   ├── TROUBLESHOOTING.md     # Common issues
│   └── CONTRIBUTING.md        # This file
├── build/                     # Build outputs (gitignored)
└── releases/                  # Release packages (gitignored)
```

## 📦 Build System Details

### Build Scripts

| Script | Purpose | Dependencies |
|--------|---------|-------------|
| `build-all.sh` | Complete build | Go, Git, Make |
| `create-installer.sh` | Package installer | Previous build |
| `setup-environment.sh` | Dev environment | OS package manager |
| `clean.sh` | Cleanup | None |

### Build Process

1. **Environment Setup**: Install dependencies and configure Go
2. **Source Retrieval**: Clone Docker CLI and Engine repositories
3. **Cross-Compilation**: Build for Windows ARM64 target
4. **Verification**: Validate binary architecture and functionality
5. **Packaging**: Create installer with all components

### Testing Strategy

- **Unit Tests**: Go test coverage for custom code
- **Integration Tests**: Full build process validation
- **System Tests**: Installer testing on Windows ARM64
- **Compatibility Tests**: Multiple Linux distribution support

## 🔍 Code Review Process

### Pull Request Guidelines

1. **Clear Title**: Descriptive title summarizing the change
2. **Detailed Description**: What, why, and how of the change
3. **Issue Reference**: Link to related issues
4. **Testing**: Describe how the change was tested
5. **Breaking Changes**: Clearly mark any breaking changes

### Review Criteria

- **Functionality**: Does the change work as intended?
- **Code Quality**: Is the code clean, readable, and maintainable?
- **Testing**: Are there adequate tests for the change?
- **Documentation**: Is documentation updated appropriately?
- **Compatibility**: Does it maintain backward compatibility?

### Review Process

1. **Automated Checks**: CI/CD pipeline must pass
2. **Code Review**: At least one maintainer review
3. **Testing**: Manual testing if needed
4. **Approval**: Maintainer approval required
5. **Merge**: Squash and merge preferred

## 🚀 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Workflow

1. **Version Bump**: Update version in relevant files
2. **Changelog**: Update CHANGELOG.md with changes
3. **Tag**: Create annotated Git tag (e.g., `v1.2.3`)
4. **Release**: GitHub Actions automatically creates release
5. **Announcement**: Announce release in discussions

### Pre-Release Testing

- Build on all supported platforms
- Test installer on Windows ARM64 systems
- Verify all documentation is current
- Check for security vulnerabilities

## 🐛 Issue Reporting

### Bug Reports

When reporting bugs, please include:

- **Environment**: OS, Go version, hardware details
- **Steps**: Detailed reproduction steps
- **Expected**: What you expected to happen
- **Actual**: What actually happened
- **Logs**: Relevant error messages or logs
- **Configuration**: Build configuration or custom settings

### Feature Requests

For feature requests, please include:

- **Use Case**: Why is this feature needed?
- **Description**: Detailed description of the feature
- **Alternatives**: Alternative solutions considered
- **Implementation**: Suggestions for implementation

### Security Issues

For security vulnerabilities:

- **Do NOT** create public issues
- **Email** maintainers directly
- **Include** detailed vulnerability information
- **Allow** time for fix before disclosure

## 🤝 Community Guidelines

### Code of Conduct

- **Be Respectful**: Treat all contributors with respect
- **Be Inclusive**: Welcome contributors of all backgrounds
- **Be Constructive**: Provide helpful, constructive feedback
- **Be Professional**: Maintain professional communication

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Pull Requests**: Code review and collaboration

### Getting Help

- **Documentation**: Check existing documentation first
- **Search**: Search existing issues and discussions
- **Ask**: Create new issue or discussion if needed
- **Patience**: Allow time for community response

## 🏆 Recognition

### Contributors

All contributors are recognized in:

- **GitHub Contributors**: Automatic GitHub recognition
- **Release Notes**: Major contributors mentioned in releases
- **Documentation**: Contributor acknowledgments

### Maintainers

Current maintainers are responsible for:

- **Code Review**: Reviewing and approving pull requests
- **Release Management**: Creating and managing releases
- **Issue Triage**: Categorizing and prioritizing issues
- **Community**: Fostering positive community environment

## 📋 Checklist for Contributors

### Before Submitting

- [ ] Fork repository and create feature branch
- [ ] Make changes following project conventions
- [ ] Test changes thoroughly
- [ ] Update documentation as needed
- [ ] Commit with clear, descriptive messages
- [ ] Push to your fork

### Pull Request

- [ ] Create pull request with clear title and description
- [ ] Reference related issues
- [ ] Ensure CI/CD checks pass
- [ ] Respond to review feedback
- [ ] Squash commits if requested

### After Merge

- [ ] Delete feature branch
- [ ] Sync fork with upstream
- [ ] Update local repository

## 📚 Additional Resources

### Documentation

- **[Build Guide](BUILD.md)** - Detailed build instructions
- **[Installation Guide](INSTALL.md)** - Installation and setup
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions

### External Resources

- **[Go Documentation](https://golang.org/doc/)** - Go language reference
- **[Docker Documentation](https://docs.docker.com/)** - Official Docker docs
- **[GitHub Flow](https://guides.github.com/introduction/flow/)** - Git workflow guide

### Tools

- **[golangci-lint](https://golangci-lint.run/)** - Go linting
- **[shellcheck](https://www.shellcheck.net/)** - Shell script analysis
- **[markdownlint](https://github.com/DavidAnson/markdownlint)** - Markdown linting

---

Thank you for contributing to Docker for Windows ARM64! Your contributions help make Docker accessible to more users and platforms. 🎉