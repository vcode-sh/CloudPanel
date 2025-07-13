# Contributing to CloudPanel DragonflyDB Installer

Thank you for your interest in contributing to this project! 🎉

## 🤝 How to Contribute

### 1. Reporting Bugs

When reporting bugs, please include:

- **OS Information**: `cat /etc/os-release`
- **Architecture**: `uname -m`
- **CloudPanel Version**: From CloudPanel dashboard
- **Installation Log**: `/var/log/dragonfly-installer.log`
- **Error Messages**: Full error output
- **Steps to Reproduce**: Detailed steps

### 2. Suggesting Features

Before suggesting a feature:
- Check existing issues to avoid duplicates
- Describe the use case clearly
- Explain why it would benefit CloudPanel users

### 3. Code Contributions

#### Development Setup

```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR_USERNAME/CloudPanel.git
cd CloudPanel

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test thoroughly

# Commit your changes
git commit -m "Add: your feature description"

# Push to your fork
git push origin feature/your-feature-name

# Create a Pull Request
```

#### Testing

Before submitting:

1. **Test on Multiple OS**:
   - Ubuntu 22.04 LTS
   - Ubuntu 24.04 LTS
   - Debian 11
   - Debian 12

2. **Test Both Architectures**:
   - x86_64
   - ARM64

3. **Test Scenarios**:
   - Fresh CloudPanel installation
   - Existing Redis with data
   - Different memory configurations
   - Error conditions

4. **Run the Test Script**:
   ```bash
   ./test-dragonfly.sh
   ```

#### Code Style

- Use bash best practices
- Add comments for complex logic
- Use meaningful variable names
- Include error handling
- Follow existing code style

#### Commit Guidelines

- Use clear, descriptive commit messages
- Start with action verb (Add, Fix, Update, Remove)
- Keep commits focused on single changes
- Include issue numbers if applicable

Examples:
```
Add: support for Debian 12
Fix: memory calculation for ARM64 systems
Update: DragonflyDB to latest version
Remove: deprecated configuration options
```

## 🧪 Testing Guidelines

### Manual Testing

1. **Clean System Test**:
   ```bash
   # Start with fresh CloudPanel installation
   sudo ./install-dragonfly-cloudpanel.sh
   ./test-dragonfly.sh
   ```

2. **Existing Redis Test**:
   ```bash
   # With Redis running and data
   redis-cli SET test "data"
   sudo ./install-dragonfly-cloudpanel.sh
   redis-cli GET test  # Should return "data"
   ```

3. **Error Handling Test**:
   ```bash
   # Test with insufficient permissions
   ./install-dragonfly-cloudpanel.sh  # Without sudo
   
   # Test with wrong OS
   # Modify script to simulate unsupported OS
   ```

### Automated Testing

If you're adding automated tests:

```bash
# Create test in tests/ directory
tests/
├── test-installation.sh
├── test-compatibility.sh
├── test-performance.sh
└── test-uninstall.sh
```

## 📝 Documentation

When contributing code:

1. **Update README.md** if adding new features
2. **Update dragonfly.md** for detailed changes
3. **Add inline comments** for complex logic
4. **Update help text** in scripts

## 🔍 Code Review Process

1. **Automated Checks**: All tests must pass
2. **Manual Review**: Maintainer will review code
3. **Testing**: May request additional testing
4. **Documentation**: Ensure docs are updated

## 🌟 Recognition

Contributors will be:
- Added to CONTRIBUTORS.md
- Mentioned in release notes
- Given credit in documentation

## 📋 Checklist for Pull Requests

- [ ] Code follows project style guidelines
- [ ] Tests pass on multiple OS/architectures
- [ ] Documentation updated if needed
- [ ] Commit messages are clear
- [ ] No breaking changes (or clearly documented)
- [ ] Error handling implemented
- [ ] Backwards compatibility maintained

## 🚀 Types of Contributions Needed

### High Priority
- Support for new OS versions
- Performance improvements
- Security enhancements
- Better error handling

### Medium Priority
- Additional configuration options
- Monitoring features
- Backup/restore improvements
- CI/CD integration

### Low Priority
- Code cleanup
- Documentation improvements
- Example configurations
- Community tools

## 🤔 Questions?

- **General Questions**: Open a GitHub Discussion
- **Bug Reports**: Open an Issue
- **Feature Requests**: Open an Issue with "enhancement" label
- **Security Issues**: Email directly (see README for contact)

## 🎯 Project Goals

Keep in mind our main objectives:
1. **Simplicity**: One-command installation
2. **Reliability**: Works on all supported systems
3. **Performance**: Optimal DragonflyDB configuration
4. **Compatibility**: Full CloudPanel integration
5. **Safety**: Easy rollback to Redis

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make CloudPanel faster with DragonflyDB! 🚀