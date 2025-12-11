# Contributing to L2 HWID Spoofer

Thank you for your interest in contributing to the L2 HWID Spoofer project! This document provides guidelines for contributing.

## 📋 Code of Conduct

By participating in this project, you agree to:
- Use this software only for educational and research purposes
- Not use contributions for malicious purposes
- Respect other contributors
- Provide constructive feedback

## 🎯 How to Contribute

### Reporting Issues

1. **Check existing issues** - Make sure the issue hasn't been reported
2. **Use issue templates** - Fill in all required information
3. **Provide details**:
   - OS version (Windows 10/11)
   - Hardware specs (CPU, motherboard)
   - Steps to reproduce
   - Error messages/logs

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly**:
   - Test in VM first
   - Test on physical hardware if safe
   - Run detection tests
5. **Commit with clear messages**:
   ```bash
   git commit -m "feat: Add monitor EDID spoofing support"
   ```
6. **Push and create PR**

### Commit Message Format

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance

## 🔧 Development Areas

### High Priority
- [ ] Monitor EDID spoofing (CRU integration)
- [ ] MAC address spoofing enhancement
- [ ] USB device spoofing
- [ ] Performance optimization

### Medium Priority
- [ ] GUI improvements
- [ ] Multi-language support
- [ ] Cloud profile sync
- [ ] Video tutorials

### Documentation
- [ ] Visual guides with screenshots
- [ ] Video walkthroughs
- [ ] Troubleshooting expansion
- [ ] Translation

## 🧪 Testing Guidelines

### Before Submitting

1. **Test in Virtual Machine**
   - VMware or VirtualBox with nested virtualization
   
2. **Test EFI Components**
   - Use USB boot (non-destructive)
   - Verify signature chain
   
3. **Test Hypervisor**
   - Run detection test suite
   - Verify no BSOD
   - Check performance impact

### Detection Tests

Run these before/after changes:
```cmd
cd Hypervisor-Test-Spoofer\04-Testing\detection-tests
cl test_cpuid.c && test_cpuid.exe
cl test_timing.c && test_timing.exe
cl test_redpill.c && test_redpill.exe
```

## 📁 Project Structure

When adding new features, follow the existing structure:

```
Feature Category/
├── source-file.c       # C source
├── source-file.h       # Header
├── script.ps1          # PowerShell
└── README.md           # Documentation
```

## 📝 Documentation Standards

- Use clear, concise language
- Include code examples
- Add ASCII diagrams for complex concepts
- Update README.md for new features

## ⚠️ Important Notes

1. **Never commit**:
   - Private keys (*.key)
   - Certificates (*.crt, *.cer)
   - Signed binaries (*-signed.efi)
   - ROM files (*.ROM)

2. **Always test**:
   - In VM first
   - With test signing enabled
   - On multiple configurations

3. **Legal compliance**:
   - No reverse engineering of commercial tools
   - No malicious code
   - Educational/research purposes only

## 🙏 Thank You

Your contributions help make this project better for everyone in the security research community!

---

**Questions?** Open an issue with the "question" label.
