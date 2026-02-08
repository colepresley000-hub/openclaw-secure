# Contributing to ShieldClaw

Thank you for your interest in contributing to ShieldClaw! This document provides guidelines for contributing to the project.

## 🤝 How to Contribute

### Reporting Security Vulnerabilities

**⚠️ IMPORTANT: Do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability, please email security@yourproject.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will respond within 48 hours.

### Reporting Bugs

Before submitting a bug report:
1. Check if the issue already exists
2. Verify you're using the latest version
3. Test with the default configuration

Include in your bug report:
- ShieldClaw version
- Operating system and version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs (redact sensitive info!)
- Configuration (redact secrets!)

### Suggesting Features

We welcome feature suggestions! Please:
1. Check if the feature is already requested
2. Explain the use case
3. Describe the proposed solution
4. Consider backwards compatibility
5. Think about security implications

### Code Contributions

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clear, commented code
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

4. **Test thoroughly**
   ```bash
   ./scripts/health-check.sh
   # Add your own tests
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "feat: add new security feature"
   ```

   Use conventional commits:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation
   - `security:` - Security improvement
   - `refactor:` - Code refactoring
   - `test:` - Testing
   - `chore:` - Maintenance

6. **Push and create a pull request**

## 🎯 Development Guidelines

### Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Keep functions focused and small
- Avoid hardcoded values

### Security First

Every contribution must:
- Not introduce security vulnerabilities
- Maintain existing security guarantees
- Be reviewed for injection risks
- Follow principle of least privilege

### Testing

- Test with various input types
- Include edge cases
- Test security boundaries
- Verify error handling

### Documentation

Update documentation for:
- New features
- Changed behavior
- New configuration options
- Security considerations

## 📝 Pull Request Process

1. **Update the README** if needed
2. **Update CHANGELOG.md** with your changes
3. **Ensure all tests pass**
4. **Request review** from maintainers
5. **Address feedback** promptly
6. **Squash commits** if requested

### PR Checklist

- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No security issues introduced
- [ ] Backwards compatible (or breaking change documented)
- [ ] CHANGELOG.md updated

## 🔒 Security Considerations

When contributing, always consider:

### Input Validation
- All user input must be validated
- Never trust data from external sources
- Sanitize before processing

### Prompt Injection
- New features must resist injection
- Test with attack patterns
- Update SOUL.md if needed

### Secrets Management
- Never log secrets
- Never commit secrets
- Use environment variables

### Error Handling
- Don't leak sensitive info in errors
- Log errors securely
- Provide user-friendly messages

## 🏗️ Project Structure

```
shieldclaw/
├── openclaw.json          # Main configuration
├── SOUL.md               # Security prompt template
├── scripts/              # Utility scripts
│   ├── setup.sh         # Setup wizard
│   ├── kill-switch.sh   # Emergency stop
│   └── health-check.sh  # Diagnostics
├── .env.example         # Environment template
├── README.md            # Main documentation
└── CONTRIBUTING.md      # This file
```

## 💬 Communication

- **GitHub Discussions** - General questions and ideas
- **GitHub Issues** - Bug reports and feature requests
- **Pull Requests** - Code contributions
- **Email** - Security issues only

## 🎓 Learning Resources

### Security
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Prompt Injection Guide](https://learnprompting.org/docs/prompt_hacking/injection)
- [Anthropic Safety Best Practices](https://docs.anthropic.com/claude/docs/intro-to-claude)

### Development
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)
- [JSON Schema](https://json-schema.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## 📜 Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards

**Positive behavior:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

**Unacceptable behavior:**
- Harassment, trolling, or derogatory comments
- Public or private harassment
- Publishing others' private information
- Other unethical or unprofessional conduct

### Enforcement

Violations may result in:
1. Warning
2. Temporary ban
3. Permanent ban

Report violations to: conduct@yourproject.com

## ❓ Questions?

Don't hesitate to ask! We're here to help:

- Open a Discussion on GitHub
- Ask in your Pull Request
- Check existing issues and docs

## 🙏 Thank You

Every contribution helps make ShieldClaw better and more secure. We appreciate your time and effort!

---

**Happy Contributing! 🛡️**
