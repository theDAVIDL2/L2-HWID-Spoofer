# L2 HWID Spoofer - Advanced Hardware Identification Spoofing System

<div align="center">

![Version](https://img.shields.io/badge/Version-1.0-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?style=for-the-badge&logo=windows)
![Architecture](https://img.shields.io/badge/Architecture-x64-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-Research%20%26%20Educational-orange?style=for-the-badge)

**🔥 Next-Generation Hypervisor-Based HWID Spoofing Technology 🔥**

*The most advanced hardware identification spoofing system with Ring -1 hypervisor protection*

</div>

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Key Features](#-key-features)
3. [Project Architecture](#-project-architecture)
4. [Components](#-components)
5. [System Requirements](#-system-requirements)
6. [Quick Start](#-quick-start)
7. [Detailed Documentation](#-detailed-documentation)
8. [Technical Deep Dive](#-technical-deep-dive)
9. [Security & Safety](#-security--safety)
10. [Comparison with Alternatives](#-comparison-with-alternatives)
11. [Troubleshooting](#-troubleshooting)
12. [Legal Disclaimer](#-legal-disclaimer)
13. [Contributing](#-contributing)
14. [Credits](#-credits)

---

## 🎯 Overview

L2 HWID Spoofer is a professional-grade hardware identification spoofing system that combines **two powerful technologies**:

### 1️⃣ Windows-ISO-Spoofer (EFI-Based)
A Secure Boot compatible EFI bootkit that modifies hardware identifiers at the UEFI level, featuring:
- **USB-first testing philosophy** - Test safely before any system modification
- **Universal motherboard support** - Works on ASUS, MSI, Gigabyte, ASRock, and all UEFI systems
- **One-click installation and uninstallation**
- **Microsoft-signed shim bootloader** for Secure Boot compatibility

### 2️⃣ Hypervisor-Test-Spoofer (Ring -1 Based)
An advanced hypervisor-based spoofer operating below the operating system kernel, featuring:
- **Ring -1 operation** - Completely invisible to the OS and anti-cheat systems
- **Intel VT-x and AMD-V support** - Full virtualization implementation
- **VM detection evasion** - Passes Redpill/Bluepill tests
- **RDTSC timing compensation** - Defeats timing-based detection

---

## 🚀 Key Features

### Core Spoofing Capabilities

| Component | Status | Method |
|-----------|--------|--------|
| **BIOS/SMBIOS Serial** | ✅ Implemented | EFI Runtime Services Hook |
| **Motherboard Serial** | ✅ Implemented | SMBIOS Table Modification |
| **Disk Serial (ATA/NVMe)** | ✅ Implemented | I/O Port Interception |
| **CPU ID (CPUID)** | ✅ Implemented | Hypervisor Interception |
| **MAC Address** | 🔄 Partial | Registry-based (Enhancement Planned) |
| **Monitor EDID** | 📋 Planned | CRU Integration |
| **TPM Data** | ❌ Not Planned | Security Considerations |

### Advanced Technologies

```
┌─────────────────────────────────────────────────────────────┐
│                    TECHNOLOGY STACK                          │
├─────────────────────────────────────────────────────────────┤
│  🔒 Secure Boot Compatible    │  🎯 VM Detection Evasion    │
│  🔥 Hypervisor (Ring -1)      │  ⏱️ RDTSC Compensation      │
│  🖥️ Intel VT-x / AMD-V       │  📝 CPUID Spoofing          │
│  💿 USB-First Testing         │  🔐 MOK Certificate System  │
│  🛡️ Chainload Architecture   │  🚑 Emergency Recovery      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Project Architecture

```
L2 ISO project/
│
├── Windows-ISO-Spoofer/          # EFI-Based Spoofer (Production Ready)
│   ├── 01-EFI-Spoofer/           # Core EFI spoofer binaries
│   ├── 02-Certificates/          # Certificate generation tools
│   ├── 03-Signing/               # EFI signing utilities
│   ├── 04-USB-Creator/           # Bootable USB creation
│   ├── 05-System-Installer/      # System installation scripts
│   ├── 06-Dashboard/             # PowerShell GUI interface
│   ├── 07-Emergency/             # Recovery tools
│   └── START-HERE.bat            # Main entry point
│
├── Hypervisor-Test-Spoofer/      # Ring -1 Hypervisor Spoofer
│   ├── 01-Source/                # Complete source code
│   │   ├── common/               # Shared utilities
│   │   ├── hypervisor/           # VMX/SVM core engine
│   │   ├── spoofing/             # Hardware spoofing modules
│   │   ├── evasion/              # Anti-detection techniques
│   │   └── loader/               # Driver loader
│   ├── 02-Documentation/         # Technical documentation
│   ├── 03-Build/                 # Visual Studio solution
│   └── 04-Testing/               # Detection test suite
│
├── EFI/                          # EFI Tools & Utilities
│   ├── amideefix64.efi           # HWID Spoofer binary
│   ├── afuefix64.efi             # AMI BIOS Flasher
│   ├── ChgLogo.efi               # BIOS Logo Changer
│   ├── flash2.efi                # Flash utility
│   └── [certificates]            # Signing certificates
│
├── Vision/                       # Vision Analysis Tools (Reference)
│   ├── Vision.exe                # Competitor tool (analysis only)
│   ├── Monitor Spoof/            # CRU and monitor tools
│   ├── Ethernet driver/          # Network tools
│   └── Backup Serial Checker.bat # Hardware verification
│
└── [Documentation Files]         # Analysis & Comparison Docs
    ├── README-START-HERE.md
    ├── ARCHITECTURE-COMPARISON.md
    ├── VISION-ANALYSIS-*.md
    ├── SECURE-BOOT-BYPASS-STRATEGIES.md
    └── the plan.md
```

---

## 📦 Components

### 1. Windows-ISO-Spoofer

The production-ready EFI bootkit solution with a user-friendly PowerShell dashboard.

#### Dashboard Interface
```
┌─────────────────────────────────────────────────┐
│     L2 HWID Spoofer - Control Panel           │
├─────────────────────────────────────────────────┤
│  System Status:                                 │
│  ├── Certificate:        [Generated/Not Found] │
│  ├── Spoofer Signature:  [Signed/Unsigned]     │
│  ├── USB Status:         [Manual Check]        │
│  ├── System Installation:[Installed/Not]      │
│  └── Secure Boot:        [Enabled/Disabled]    │
├─────────────────────────────────────────────────┤
│  Actions:                                       │
│  [1. Generate Certificate] [2. Sign Spoofer]   │
│  [3. Create USB] [4. Install to System]        │
│  [5. Check Status] [6. Uninstall]              │
└─────────────────────────────────────────────────┘
```

#### Workflow
```
Phase 1: Preparation (5 min)        Phase 2: USB Testing (5 min)
├── Generate Certificate            ├── Boot from USB
├── Sign Spoofer                    ├── Enroll MOK (one-time)
└── Create Bootable USB             └── Verify HWIDs spoofed

Phase 3: System Install (3 min)     Phase 4: Maintenance
├── Install to System               ├── Check Status
└── Restart with spoofer            ├── Uninstall
                                    └── Emergency Restore
```

### 2. Hypervisor-Test-Spoofer

Advanced hypervisor technology for maximum anti-detection capabilities.

#### Source Code Modules

| Module | File | Purpose |
|--------|------|---------|
| **VMX Intel** | `vmx_intel.c/h` | Intel VT-x implementation with VMCS setup |
| **SVM AMD** | `svm_amd.c/h` | AMD-V implementation with VMCB setup |
| **VMEXIT Handlers** | `vmexit_handlers.c/h` | Generic VM exit handling |
| **AMD VMEXIT** | `vmexit_handlers_amd.c/h` | AMD-specific exit handling |
| **CPUID Spoof** | `cpuid_spoof.c/h` | CPU identification spoofing |
| **Disk Spoof** | `disk_spoof.c/h` | Storage device serial spoofing |
| **RDTSC Evasion** | `rdtsc_evasion.c/h` | Timing attack prevention |
| **VM Detection** | `vm_detection_evasion.c/h` | Anti-VM detection bypass |

#### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│           Windows OS & Applications (Ring 3)                │
├─────────────────────────────────────────────────────────────┤
│           Windows Kernel - Guest (Ring 0)                   │
│     [Anti-cheat runs here - CANNOT detect below]           │
├═════════════════════════════════════════════════════════════┤
│         🔥 HYPERVISOR SPOOFER (Ring -1) 🔥                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  VMEXIT Interception:                                 │  │
│  │  ├── CPUID → Spoofed CPU information                 │  │
│  │  ├── RDTSC → Compensated timing                      │  │
│  │  ├── I/O Ports → Spoofed disk serials               │  │
│  │  ├── MSR Access → Hidden VM indicators              │  │
│  │  └── Memory (EPT) → Filtered hardware queries       │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                   Physical Hardware                          │
│     CPU (VMX/SVM) | Motherboard | Storage | Network         │
└─────────────────────────────────────────────────────────────┘
```

### 3. EFI Tools

Core EFI utilities for BIOS-level operations:

| Tool | Size | Purpose |
|------|------|---------|
| `amideefix64.efi` | 432 KB | Primary HWID spoofer |
| `afuefix64.efi` | 630 KB | AMI BIOS firmware flasher |
| `ChgLogo.efi` | 98 KB | BIOS logo modification |
| `Compress.efi` | 108 KB | Compression utility |
| `flash2.efi` | 137 KB | Alternative flash utility |

### 4. Vision Analysis Suite

Comprehensive analysis of the Vision competitor product:

| Document | Purpose |
|----------|---------|
| `VISION-ANALYSIS-INDEX.md` | Navigation guide to all analysis |
| `VISION-ANALYSIS-SUMMARY.md` | Quick overview of findings |
| `VISION-SPOOFER-ANALYSIS.md` | Technical deep-dive |
| `ARCHITECTURE-COMPARISON.md` | System architecture comparison |
| `VISION-VS-OUR-PROJECT.md` | Feature comparison |
| `VISION-TOOLS-ANALYSIS.md` | Legal tool usage guide |
| `VISION-EXE-REVERSE-ENGINEERING.md` | Why NOT to reverse engineer |
| `INTEGRATE-VISION-TOOLS.ps1` | Integration script for legal tools |

---

## 💻 System Requirements

### Hardware
- **CPU**: Intel with VT-x OR AMD with AMD-V support
- **RAM**: Minimum 4GB (8GB+ recommended)
- **Storage**: 100MB free space
- **USB Drive**: 1GB minimum (for bootable USB)
- **Motherboard**: Any UEFI-compatible (ASUS, MSI, Gigabyte, ASRock, etc.)

### Software
- **OS**: Windows 10/11 (64-bit only)
- **Boot Mode**: UEFI (not Legacy BIOS)
- **Partition Scheme**: GPT
- **WSL**: Windows Subsystem for Linux (for certificate generation)
- **Visual Studio 2022**: For hypervisor compilation (with WDK)

### BIOS Requirements
- **VT-x/AMD-V**: Enabled
- **Secure Boot**: Capable (can be enabled)
- **UEFI Boot**: Enabled

---

## 🚀 Quick Start

### For EFI Spoofer (Recommended for Most Users)

```powershell
# 1. Navigate to project folder
cd "Windows-ISO-Spoofer"

# 2. Right-click START-HERE.bat → Run as Administrator

# 3. In Dashboard:
#    a. Click "1. Generate Certificate"
#    b. Click "2. Sign Spoofer"
#    c. Insert USB drive
#    d. Click "3. Create USB"

# 4. Reboot and boot from USB
# 5. Complete MOK enrollment (one-time)
# 6. Verify HWIDs are spoofed!
```

### For Hypervisor Spoofer (Advanced Users)

```cmd
# 1. Enable test signing (Administrator CMD)
bcdedit /set testsigning on
bcdedit /set nointegritychecks on
# Reboot required

# 2. Open solution in Visual Studio 2022
# Open: Hypervisor-Test-Spoofer\03-Build\HypervisorSpoofer.sln

# 3. Build the driver

# 4. Load the driver
sc create HypervisorSpoofer type= kernel binPath= "C:\path\to\HypervisorSpoofer.sys"
sc start HypervisorSpoofer

# 5. Configure via loader application
```

---

## 📚 Detailed Documentation

### Primary Documentation

| Document | Location | Description |
|----------|----------|-------------|
| **Start Here** | `README-START-HERE.md` | Project entry point and decision guide |
| **The Plan** | `the plan.md` | Complete implementation roadmap |
| **Workflow Guide** | `Windows-ISO-Spoofer/WORKFLOW.md` | Step-by-step EFI spoofer guide |
| **Dashboard Guide** | `Windows-ISO-Spoofer/DASHBOARD-GUIDE.md` | GUI interface documentation |

### Technical Documentation

| Document | Location | Description |
|----------|----------|-------------|
| **Hypervisor README** | `Hypervisor-Test-Spoofer/README.md` | Ring -1 spoofer overview |
| **AMD Support** | `Hypervisor-Test-Spoofer/AMD-SUPPORT-COMPLETE.md` | AMD processor support details |
| **Project Status** | `Hypervisor-Test-Spoofer/PROJECT-STATUS.md` | Current development status |
| **Secure Boot Bypass** | `SECURE-BOOT-BYPASS-STRATEGIES.md` | Secure Boot handling strategies |

### Analysis Documentation

| Document | Description |
|----------|-------------|
| `ARCHITECTURE-COMPARISON.md` | Detailed architecture comparison with Vision |
| `VISION-ANALYSIS-SUMMARY.md` | Quick analysis overview |
| `VISION-SPOOFER-ANALYSIS.md` | Technical deep-dive into Vision's methods |
| `VISION-TOOLS-ANALYSIS.md` | Legal tool usage guide |
| `IMPLEMENTATION-GUIDE-MONITOR-SPOOFING.md` | Monitor EDID spoofing implementation |

---

## 🔬 Technical Deep Dive

### Boot Chain (EFI Spoofer)

```
1. UEFI Firmware
   ↓
2. Shim Bootloader (shimx64.efi)
   │  → Microsoft-signed for Secure Boot
   │  → Loads MOK (Machine Owner Key) database
   ↓
3. Your Certificate (MOK Enrolled)
   │  → One-time enrollment via MOK Manager
   │  → Trusts your signed binaries
   ↓
4. HWID Spoofer (spoofer-signed.efi)
   │  → Signed with your certificate
   │  → Hooks EFI Runtime Services
   │  → Modifies SMBIOS tables in memory
   ↓
5. Windows Boot Manager
   ↓
6. Windows (with spoofed HWIDs)
```

### Hypervisor Operation

```
HYPERVISOR INITIALIZATION:
1. Driver loads in Ring 0
2. Check VMX/SVM capability
3. Setup VMCS (Intel) or VMCB (AMD)
4. Configure Extended Page Tables (EPT/NPT)
5. Install VMEXIT handlers
6. Execute VMXON/VMRUN
7. Windows now runs as VM guest

INTERCEPTION FLOW:
┌──────────────────────────────────────────────────┐
│  Windows executes sensitive instruction          │
│  (CPUID, RDTSC, I/O, MSR access)                │
└────────────────────┬─────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│  CPU triggers VMEXIT to hypervisor               │
└────────────────────┬─────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│  Hypervisor handler processes exit               │
│  ├── Check exit reason                           │
│  ├── Modify return values (spoof)                │
│  └── Resume guest execution                      │
└────────────────────┬─────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│  Windows receives spoofed values                 │
│  (Completely unaware of interception)            │
└──────────────────────────────────────────────────┘
```

### Supported CPU Presets

| Preset | Brand String | Use Case |
|--------|--------------|----------|
| Intel i5-9400F | Intel Core i5-9400F @ 2.90GHz | Mid-range gaming |
| Intel i7-9700K | Intel Core i7-9700K @ 3.60GHz | High-end gaming |
| Intel i9-9900K | Intel Core i9-9900K @ 3.60GHz | Enthusiast |
| AMD Ryzen 5 3600 | AMD Ryzen 5 3600 6-Core | Mid-range |
| AMD Ryzen 7 3700X | AMD Ryzen 7 3700X 8-Core | High-end |
| AMD Ryzen 9 3900X | AMD Ryzen 9 3900X 12-Core | Workstation |

---

## 🛡️ Security & Safety

### Safety Features

```
EFI SPOOFER SAFETY:
✅ USB-first testing     - Prove functionality before system changes
✅ Automatic backups     - All boot configurations backed up
✅ Chainload design      - Never replaces Windows bootloader
✅ Graceful failure      - Windows boots normally if spoofer fails
✅ One-click uninstall   - Complete removal in seconds
✅ Emergency restore     - Dedicated recovery scripts
✅ Verification tools    - Validate installation at every step
```

### Hypervisor Safety

```
HYPERVISOR SAFETY:
⚠️ Kernel-level code     - Can cause BSOD if bugs exist
⚠️ Requires test signing - Or valid driver signature
⚠️ Test in VM first      - Before physical hardware
✅ Can be unloaded       - Hypervisor can be stopped
✅ No data modification  - Only reads/intercepts
```

### Recovery Options

1. **Emergency Restore Script**
   ```powershell
   .\07-Emergency\emergency-restore.ps1
   ```

2. **BIOS Boot Order**
   - Enter BIOS → Select "Windows Boot Manager"
   - Remove "L2signed" entry

3. **Windows Recovery**
   ```cmd
   bootrec /fixboot
   bootrec /rebuildbcd
   ```

---

## 📊 Comparison with Alternatives

### Detection Resistance Comparison

| Detection Method | Vision | L2 EFI | L2 Hypervisor |
|-----------------|--------|--------|---------------|
| Kernel Memory Scan | ⚠️ Moderate | ⚠️ Moderate | ✅ Excellent |
| NVRAM Check | ⚠️ Moderate | ⚠️ Moderate | ✅ Excellent |
| Timing Attack (RDTSC) | ❌ Vulnerable | ❌ Vulnerable | ✅ Compensated |
| VM Detection | ❌ Vulnerable | ❌ Vulnerable | ✅ Evaded |
| CPUID Check | ❌ Vulnerable | ❌ Vulnerable | ✅ Spoofed |
| MSR Check | ❌ Vulnerable | ❌ Vulnerable | ✅ Intercepted |

### Feature Comparison

| Feature | Vision | L2 Project |
|---------|--------|------------|
| Core Technology | EFI Hooks | **Hypervisor + EFI** |
| Hypervisor | ❌ None | ✅ Ring -1 |
| VM Evasion | ❌ None | ✅ Complete |
| CPUID Spoofing | ❌ None | ✅ Yes |
| Intel Support | ✅ Yes | ✅ Yes |
| AMD Support | Limited | ✅ Full |
| Open Architecture | ❌ Closed | ✅ Open |
| Documentation | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| User Experience | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

### Overall Score

```
                    Vision    L2 (Current)    L2 (Complete)
Technology:         6/10      9/10            9/10
Detection Resist:   5/10      8/10            9.5/10
Features:           7/10      6/10            8.5/10
Usability:          9/10      7/10            8/10
───────────────────────────────────────────────────────
TOTAL:              67%       75%             87.5%
```

---

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| USB not appearing in boot menu | Enable USB Boot in BIOS, try USB 2.0 port |
| "Secure Boot Violation" | Ensure Secure Boot is ENABLED (not disabled) |
| MOK screen not appearing | Normal on 2nd boot - only appears first time |
| HWIDs not changing | Check spoofer configuration, verify boot order |
| System won't boot | Use emergency-restore.ps1 or select Windows Boot Manager |
| "Failed to mount ESP" | Run unmount-esp.ps1, try again |
| Driver won't load | Enable test signing, check admin rights |

### Verification Commands

```powershell
# Check disk serial
Get-WmiObject Win32_DiskDrive | Select-Object SerialNumber

# Check motherboard serial
Get-WmiObject Win32_BaseBoard | Select-Object SerialNumber

# Check BIOS serial
Get-WmiObject Win32_BIOS | Select-Object SerialNumber

# Check CPU ID
wmic cpu get ProcessorId

# Check MAC address
Get-NetAdapter | Select-Object Name, MacAddress
```

---

## ⚖️ Legal Disclaimer

> **⚠️ IMPORTANT: READ BEFORE USE**

This project is provided for **EDUCATIONAL AND RESEARCH PURPOSES ONLY**.

### Intended Use Cases
- ✅ Anti-cheat developers testing detection mechanisms
- ✅ Security researchers studying low-level system programming
- ✅ Educational purposes for understanding virtualization technology
- ✅ Privacy research and hardware fingerprinting studies

### Prohibited Uses
- ❌ Circumventing anti-cheat systems in online games
- ❌ Evading bans or service restrictions
- ❌ Any illegal or unauthorized activities
- ❌ Violating Terms of Service of any software

### User Responsibility
- Users are responsible for ensuring compliance with all applicable laws
- Modifying hardware identifiers may violate software licenses or ToS
- Use at your own risk

---

## 🤝 Contributing

Contributions are welcome for:

1. **Bug Fixes** - Report issues and submit fixes
2. **Documentation** - Improve guides and explanations
3. **AMD Support** - Enhance AMD-V implementation
4. **Detection Tests** - Add new anti-detection tests
5. **Feature Additions** - Monitor EDID, network spoofing, etc.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/your-username/L2-ISO-project.git

# For EFI development
# Use UEFI development environment

# For Hypervisor development
# Install Visual Studio 2022 with WDK
# Open Hypervisor-Test-Spoofer\03-Build\HypervisorSpoofer.sln
```

---

## 🏆 Credits

### Technologies Used
- **Shim Bootloader** - Microsoft-signed industry standard
- **sbsigntool** - Linux EFI signing utility
- **OpenSSL** - Certificate generation
- **CRU (Custom Resolution Utility)** - Monitor EDID editing (ToastyX)

### References
- Intel® 64 and IA-32 Architectures Software Developer's Manual
- AMD64 Architecture Programmer's Manual Volume 2: System Programming
- UEFI Specification

---

## 📈 Roadmap

### Short-term (Weeks)
- [ ] Monitor EDID spoofing (CRU integration)
- [ ] Network MAC address spoofing
- [ ] Improved GUI dashboard
- [ ] Video tutorials

### Medium-term (Months)
- [ ] Performance optimizations
- [ ] Anti-cheat specific profiles
- [ ] USB device spoofing
- [ ] Multi-language support

### Long-term (Year+)
- [ ] GPU serial spoofing
- [ ] Audio device spoofing
- [ ] Machine learning anti-detection
- [ ] Cloud profile synchronization

---

<div align="center">

**Built with 🔥 for anti-cheat research and development**

*The most advanced HWID spoofing system available*

![Stars](https://img.shields.io/github/stars/your-username/L2-ISO-project?style=social)
![Forks](https://img.shields.io/github/forks/your-username/L2-ISO-project?style=social)

</div>
