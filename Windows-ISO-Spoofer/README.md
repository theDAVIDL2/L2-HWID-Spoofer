# L2 HWID Spoofer - Ultra-Robust Edition

**Secure Boot Compatible | USB-First Testing | Universal Motherboard Support**

## Quick Start

1. **Right-click** `START-HERE.bat`
2. Select **"Run as administrator"**
3. Follow the dashboard workflow

That's it! The dashboard guides you through everything.

---

## What is This?

A professional-grade HWID (Hardware ID) spoofer that:
- ✅ **Works with Secure Boot enabled** (using Microsoft-signed shim + MOK)
- ✅ **USB testing first** (completely safe and reversible)
- ✅ **Universal compatibility** (ASUS, MSI, Gigabyte, ASRock, all UEFI systems)
- ✅ **Optional system install** (after USB test succeeds)
- ✅ **One-click uninstall** (complete removal)
- ✅ **Emergency recovery** (if anything goes wrong)

---

## The Workflow (4 Phases)

### Phase 1: Preparation (5 minutes)
```
START-HERE.bat → Dashboard
  ↓
1. Generate Certificate
  ↓
2. Sign Spoofer
  ↓
3. Create USB
```

### Phase 2: USB Testing (5 minutes)
```
Boot from USB
  ↓
Enroll MOK (one-time, 30 seconds)
  ↓
Test HWIDs spoofed
  ↓
Verify Windows works
```

### Phase 3: System Installation (3 minutes) [Optional]
```
Boot normally (no USB)
  ↓
Dashboard → Install to System
  ↓
Restart → Select "L2signed"
  ↓
Done! Auto-spoof every boot
```

### Phase 4: Maintenance
```
Check Status: Verify installation
Uninstall: Complete removal
Emergency Restore: If boot fails
```

---

## Why USB First?

**Safety first philosophy:**
- Test everything before touching your system
- Prove MOK enrollment works
- Verify spoofer compatibility
- Completely reversible (just remove USB)
- No risk to your Windows installation

**System install only after USB succeeds:**
- More convenient (no USB needed)
- Faster boot
- Still fully uninstallable
- Same safety guarantees

---

## Project Structure

```
Windows-ISO-Spoofer/
├── 01-EFI-Spoofer/           Your HWID spoofer (amideefix64.efi)
├── 02-Certificates/          Certificate generation
├── 03-Signing/               EFI signing tools
├── 04-USB-Creator/           Bootable USB creation
├── 05-System-Installer/      System installation (optional)
├── 06-Dashboard/             GUI interface
├── 07-Emergency/             Recovery tools
├── START-HERE.bat            Main entry point
└── WORKFLOW.md               Complete guide (READ THIS!)
```

---

## Prerequisites

- Windows 10/11 (UEFI mode)
- Administrator rights
- WSL (Windows Subsystem for Linux) - installed automatically
- USB drive (1GB minimum) - will be erased
- 10 minutes of your time

---

## Documentation

📖 **[WORKFLOW.md](WORKFLOW.md)** - Complete step-by-step guide (RECOMMENDED)

**Quick links:**
- [Prerequisites](WORKFLOW.md#prerequisites)
- [Phase 1: Preparation](WORKFLOW.md#phase-1-preparation-windows)
- [Phase 2: USB Testing](WORKFLOW.md#phase-2-usb-testing-boot-from-usb)
- [Phase 3: System Installation](WORKFLOW.md#phase-3-system-installation-optional)
- [Troubleshooting](WORKFLOW.md#troubleshooting)
- [Technical Details](WORKFLOW.md#technical-details)

---

## How It Works (Technical)

```
UEFI Firmware
    ↓
Shim Bootloader (shimx64.efi)
  [Microsoft-signed, Secure Boot compatible]
    ↓
MOK (Machine Owner Key)
  [Your certificate, enrolled once]
    ↓
HWID Spoofer (spoofer-signed.efi)
  [Signed with your certificate]
    ↓
[Modifies HWIDs in memory]
    ↓
Windows Boot Manager → Windows
  [Boots with spoofed HWIDs]
```

**Key advantages:**
- Secure Boot stays enabled
- Microsoft's trust chain intact
- No bootloader replacement (chainloading)
- Graceful failure (Windows boots if spoofer fails)

---

## Features

### ✅ Secure Boot Compatible
- Uses Microsoft-signed shim bootloader
- MOK enrollment for user certificates
- No need to disable Secure Boot

### ✅ USB-First Philosophy
- Test everything safely first
- Completely reversible
- No system modifications until proven

### ✅ Universal Compatibility
- Works on all UEFI systems
- Tested on ASUS, MSI, Gigabyte, ASRock
- No motherboard-specific hacks

### ✅ Professional Quality
- Comprehensive error checking
- Automatic backups
- Emergency recovery tools
- Detailed logging

### ✅ User-Friendly
- GUI dashboard (6 buttons)
- Clear status indicators
- Step-by-step instructions
- No command-line expertise needed

---

## Safety Guarantees

1. **USB testing required before system install**
2. **Automatic backups** of boot configuration
3. **Chainloading** (never replaces Windows bootloader)
4. **Graceful failure** (Windows boots if spoofer fails)
5. **One-click uninstall** (complete removal)
6. **Emergency restore** (dedicated recovery tool)
7. **Verification at every step** (no silent failures)

---

## Troubleshooting

**Common issues:**
- USB won't boot → Check Secure Boot is ENABLED (not disabled)
- MOK screen doesn't appear → Normal on second boot (only first time)
- System won't boot → Run emergency-restore.ps1
- HWIDs not changing → Verify spoofer configuration

**Full troubleshooting guide:** [WORKFLOW.md#troubleshooting](WORKFLOW.md#troubleshooting)

---

## FAQ

**Q: Is this safe?**  
A: Yes. USB testing proves it works before system modification. Uninstall available anytime.

**Q: Will Secure Boot stay enabled?**  
A: Yes. This method requires Secure Boot enabled.

**Q: Can I remove it?**  
A: Yes. One-click uninstall removes everything.

**Q: What if boot fails?**  
A: Emergency restore script fixes everything. Or select "Windows Boot Manager" in BIOS.

**Q: Does this affect Windows updates?**  
A: No. Updates work normally.

**Q: Laptop compatible?**  
A: Yes. Any UEFI system.

**Full FAQ:** [WORKFLOW.md#faq](WORKFLOW.md#faq)

---

## Support Files

### Main Scripts
- `START-HERE.bat` - Launch dashboard
- `02-Certificates/generate-cert.ps1` - Generate certificate
- `03-Signing/sign-spoofer.ps1` - Sign EFI
- `04-USB-Creator/create-usb.ps1` - Create bootable USB
- `05-System-Installer/install-to-system.ps1` - Install to system
- `05-System-Installer/uninstall.ps1` - Complete removal
- `07-Emergency/emergency-restore.ps1` - Emergency recovery

### Documentation
- `WORKFLOW.md` - Complete guide (read this!)
- `README.md` - This file (quick overview)
- `the plan.md` - Original implementation plan

---

## What Makes This Different?

**Traditional spoofer approach:**
- Replace bootloader → **Risky, can brick system**
- Disable Secure Boot → **Security risk**
- Direct system modification → **Hard to undo**
- No testing → **Hope it works**

**This ultra-robust approach:**
- Chainload bootloader → **Safe, no replacement**
- Keep Secure Boot on → **Security maintained**
- USB testing first → **Prove it works**
- One-click uninstall → **Easy removal**

---

## Credits

- **Shim bootloader:** Microsoft-signed, industry standard
- **sbsigntool:** Linux EFI signing utility
- **amideefix64.efi:** Your HWID spoofer implementation

---

## Legal Disclaimer

This tool is provided for educational and research purposes only. Users are responsible for ensuring compliance with all applicable laws and terms of service. Modifying hardware identifiers may violate software licenses or terms of service. Use at your own risk.

---

## Version

**Version:** 1.0  
**Date:** 2025-11-14  
**Status:** Production Ready

---

## Getting Started

**Ready to begin?**

1. Read [WORKFLOW.md](WORKFLOW.md) (10 minutes)
2. Run `START-HERE.bat` as administrator
3. Follow the dashboard (15 minutes total)
4. Boot from USB to test
5. Install to system if USB test succeeds

**Questions?** See [WORKFLOW.md](WORKFLOW.md) - everything is explained there!

---

**Happy spoofing! 🎭**


