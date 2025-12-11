# Security Policy

## 🛡️ Reporting Security Issues

If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Email**: Do NOT create a public issue for security vulnerabilities
2. **Private Disclosure**: Contact the maintainers directly
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Fix Development**: Depends on severity
- **Public Disclosure**: After fix is released

## 🔒 Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ Yes    |

## ⚠️ Known Security Considerations

### Kernel-Level Code Risks

This project contains kernel-level code (hypervisor and EFI) that:

1. **Can cause system instability** if bugs exist
2. **Requires administrative privileges** to install
3. **Modifies boot configuration** in the EFI partition
4. **Creates UEFI boot entries** that persist across reboots

### Mitigations Implemented

- ✅ USB-first testing philosophy
- ✅ Automatic backup of boot configuration
- ✅ Chainload design (doesn't replace Windows bootloader)
- ✅ Emergency recovery scripts
- ✅ Verification at every step

### User Responsibilities

1. **Test in VM first** before physical hardware
2. **Keep backups** of important data
3. **Use test signing mode** for hypervisor
4. **Verify signatures** before trusting binaries

## 📋 Security Best Practices

### For Users

```
✅ DO:
- Test in virtual machine first
- Keep Windows recovery media ready
- Backup certificates securely
- Use USB boot for testing

❌ DON'T:
- Run untrusted builds
- Disable Secure Boot permanently
- Share private keys
- Use on production systems
```

### For Developers

```
✅ DO:
- Sign all EFI binaries
- Validate all inputs
- Handle errors gracefully
- Test on multiple configurations

❌ DON'T:
- Commit private keys
- Include hardcoded credentials
- Skip verification steps
- Bypass security checks
```

## 🔐 Private Key Security

The project generates private keys for signing:

- **Location**: `02-Certificates/my-key.key`
- **Action**: Added to `.gitignore`
- **Backup**: User responsibility

**NEVER commit private keys to the repository!**

## 📝 Audit History

| Date | Action | Details |
|------|--------|---------|
| 2025-11 | Initial Release | Core security review |

---

**Remember**: This software is for educational and research purposes only. Use responsibly.
