# Hypervisor-Based HWID Spoofer (Research/Testing Tool)

## ⚠️ WARNING: RESEARCH TOOL FOR ANTI-CHEAT DEVELOPMENT

This is a **hypervisor-based hardware identification (HWID) spoofer** designed specifically for **anti-cheat testing and development**. This tool operates at Ring -1 (hypervisor level), below the operating system kernel.

### Purpose

This tool is intended for:
- **Anti-cheat developers** testing detection mechanisms
- **Security researchers** studying hypervisor-based attacks
- **Reverse engineers** learning low-level system programming
- **Educational purposes** understanding virtualization technology

### ⛔ NOT FOR USE IN:
- Circumventing anti-cheat systems in online games
- Evading bans or restrictions
- Any illegal or unauthorized activities
- Production environments

---

## Overview

This hypervisor spoofer implements a **thin hypervisor** (Type 2) that runs underneath Windows, intercepting hardware identification queries and returning spoofed values.

### Features

✅ **Hypervisor-Level Operation** - Runs at Ring -1, below OS kernel  
✅ **Intel VT-x Support** - Full VMX implementation  
✅ **AMD-V Support** - SVM implementation (planned)  
✅ **CPUID Spoofing** - Modify processor identification  
✅ **Disk Serial Spoofing** - ATA/NVMe serial interception  
✅ **MAC Address Spoofing** - Network adapter ID modification  
✅ **Motherboard Spoofing** - SMBIOS table modification  
✅ **Anti-Detection** - VM evasion techniques  
✅ **Timing Compensation** - RDTSC overhead mitigation  
✅ **Configurable Presets** - Intel i5/i7/i9, AMD Ryzen profiles  

---

## Architecture

```
┌─────────────────────────────────────┐
│     Windows OS & Applications      │ ← Ring 3 (User Mode)
├─────────────────────────────────────┤
│      Windows Kernel (Guest)        │ ← Ring 0 (Kernel Mode)
├─────────────────────────────────────┤
│    Hypervisor Spoofer (VMM)        │ ← Ring -1 (Hypervisor)
│  ┌───────────────────────────────┐ │
│  │  - CPUID Interception         │ │
│  │  - MSR Interception           │ │
│  │  - I/O Port Interception      │ │
│  │  - VM Detection Evasion       │ │
│  │  - Timing Compensation        │ │
│  └───────────────────────────────┘ │
├─────────────────────────────────────┤
│         Physical Hardware          │
└─────────────────────────────────────┘
```

---

## Project Structure

```
Hypervisor-Test-Spoofer/
├── 01-Source/
│   ├── common/          # Utilities, config, logging
│   ├── hypervisor/      # VMX/SVM core engine
│   ├── spoofing/        # HWID spoofing modules
│   ├── evasion/         # Anti-detection techniques
│   └── loader/          # Driver & user-mode loader
├── 02-Documentation/
│   ├── 00-Overview.md
│   ├── 01-Prerequisites.md
│   ├── 02-Virtualization-Basics.md
│   ├── 03-Intel-VTx-Deep-Dive.md
│   ├── 04-AMD-V-Deep-Dive.md
│   ├── 05-VMCS-Setup.md
│   ├── 06-VM-Exit-Handling.md
│   ├── 07-Spoofing-Implementation.md
│   ├── 08-Anti-Detection.md
│   ├── 09-Building-And-Testing.md
│   └── 10-Debugging-Guide.md
├── 03-Build/            # Visual Studio solution
├── 04-Testing/          # Detection test suite
└── README.md
```

---

## Requirements

### Hardware
- Intel CPU with VT-x support (or AMD CPU with AMD-V for future support)
- At least 4GB RAM
- VT-x/AMD-V enabled in BIOS

### Software
- Windows 10/11 (64-bit only)
- Visual Studio 2022 with C++ Desktop Development
- Windows Driver Kit (WDK)
- Admin privileges

---

## Quick Start

### 1. Enable Test Signing

Run as Administrator:
```cmd
bcdedit /set testsigning on
bcdedit /set nointegritychecks on
```

Reboot required.

### 2. Build the Driver

Open `03-Build/HypervisorSpoofer.sln` in Visual Studio 2022 and build the solution.

### 3. Load the Driver

```cmd
sc create HypervisorSpoofer type= kernel binPath= "C:\path\to\HypervisorSpoofer.sys"
sc start HypervisorSpoofer
```

### 4. Configure & Test

Use the loader application to configure spoofing settings and test detection evasion.

---

## Configuration Presets

The spoofer includes several hardware presets:

### Intel Presets
- **Intel i5-9400F** - Mid-range gaming CPU
- **Intel i7-9700K** - High-end gaming CPU
- **Intel i9-9900K** - Enthusiast-level CPU

### AMD Presets
- **AMD Ryzen 5 3600** - Mid-range CPU
- **AMD Ryzen 7 3700X** - High-end CPU
- **AMD Ryzen 9 3900X** - Workstation/enthusiast CPU

### Custom
- Full manual configuration
- Random generation

---

## Detection Test Suite

Located in `04-Testing/detection-tests/`:

- **test_cpuid.c** - CPUID-based VM detection
- **test_timing.c** - Timing attack detection
- **test_redpill.c** - SIDT/SGDT descriptor table analysis
- **test_msr.c** - MSR-based detection
- **test_pmu.c** - Performance counter analysis

### Running Tests

Compile and run the detection tests **before and after** loading the hypervisor to verify evasion effectiveness.

```cmd
cl test_cpuid.c
test_cpuid.exe
```

---

## Safety & Warnings

### ⚠️ This is Kernel-Level Code

- Can cause **Blue Screen of Death (BSOD)** if bugs exist
- Can **corrupt system state** if improperly configured
- Requires **test signing mode** or valid driver signature
- **Test in VM first** before using on physical hardware

### Debugging

Use WinDbg for kernel debugging:
```
bcdedit /debug on
bcdedit /dbgsettings serial debugport:1 baudrate:115200
```

See `02-Documentation/10-Debugging-Guide.md` for detailed instructions.

---

## Documentation

Comprehensive documentation is provided in `02-Documentation/`:

1. **Overview** - What is a hypervisor and how does it work?
2. **Prerequisites** - Required tools and knowledge
3. **Virtualization Basics** - CPU ring levels, VMX/SVM concepts
4. **Intel VT-x Deep Dive** - VMCS structure, VM entry/exit
5. **AMD-V Deep Dive** - VMCB structure, NPT
6. **VMCS Setup** - Detailed configuration walkthrough
7. **VM Exit Handling** - Interception and spoofing implementation
8. **Spoofing Implementation** - CPUID, disk, MAC, SMBIOS spoofing
9. **Anti-Detection** - VM evasion techniques and timing compensation
10. **Building & Testing** - Compilation, signing, installation, testing
11. **Debugging Guide** - WinDbg setup, troubleshooting, common issues

---

## Technical Details

### Supported Spoofing

| Component | Method | Status |
|-----------|--------|--------|
| CPU ID | CPUID interception | ✅ Implemented |
| CPU Brand | CPUID leaves 0x80000002-4 | ✅ Implemented |
| Disk Serial | ATA I/O port interception | ✅ Implemented |
| MAC Address | NIC I/O interception | ✅ Implemented |
| Motherboard | SMBIOS hooking | ⏳ Planned |
| BIOS Info | SMBIOS Type 0 | ⏳ Planned |
| Windows ID | Registry interception | ⏳ Planned |
| TPM Data | TPM command interception | ❌ Not Planned |
| GPU Serial | PCI config space | ❌ Not Planned |

### Anti-Detection Techniques

| Technique | Description | Status |
|-----------|-------------|--------|
| CPUID Masking | Hide hypervisor present bit | ✅ Implemented |
| Vendor Hiding | Clear CPUID leaf 0x40000000 | ✅ Implemented |
| RDTSC Compensation | Adjust TSC for VM exit overhead | ✅ Implemented |
| SIDT Emulation | Return fake IDT base | ⏳ Planned |
| Memory Artifact Hiding | Obfuscate VMCS structures | ⏳ Planned |

---

## License

This is research/educational software. Use responsibly and legally.

---

## Contributing

This is a reference implementation for anti-cheat developers. Contributions welcome for:
- Bug fixes
- Additional detection tests
- Documentation improvements
- AMD-V support implementation

---

## Credits

Developed for anti-cheat research and testing purposes.

References:
- Intel® 64 and IA-32 Architectures Software Developer's Manual
- AMD64 Architecture Programmer's Manual Volume 2: System Programming
- Various academic papers on hypervisor-based rootkits

---

## Contact

For security research inquiries and anti-cheat development collaboration only.

---

**Remember: This tool is for defensive security research only. Use it ethically and legally.**

