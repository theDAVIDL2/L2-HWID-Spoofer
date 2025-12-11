# L2 HWID Master - Advanced BIOS & Hardware Spoofing Platform

<div align="center">

![Version](https://img.shields.io/badge/Version-2.0-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?style=for-the-badge&logo=windows)
![Architecture](https://img.shields.io/badge/Architecture-x64-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-Research%20%26%20Educational-orange?style=for-the-badge)

**🔥 Permanent BIOS-Level Spoofing with AFUWIN Method 🔥**

*The most effective permanent HWID spoofing solution - works on ALL motherboards including ASUS*

</div>

---

## ⚠️ CRITICAL WARNING - READ FIRST

> **🚨 DANGER: BIOS FLASHING CAN PERMANENTLY BRICK YOUR MOTHERBOARD 🚨**
>
> The AFUWIN method involves flashing modified BIOS firmware to your motherboard. If done incorrectly:
> - **Your motherboard may become permanently unusable**
> - **Your computer will not boot**
> - **Professional repair or motherboard replacement may be required**
> - **This cannot always be reversed**
>
> **ONLY proceed if you:**
> 1. Fully understand the risks
> 2. Have a backup computer available
> 3. Are comfortable with BIOS-level operations
> 4. Accept full responsibility for any damage

---

## 🎯 Overview

L2 HWID Master combines **two powerful spoofing technologies**:

### 1️⃣ AFUWIN Method (Primary - Production Ready)
The most reliable **permanent** HWID spoofing solution. This method:
- ✅ **Works on ALL motherboards** (including ASUS, MSI, Gigabyte, ASRock)
- ✅ **Permanent changes** - Survives Windows reinstall
- ✅ **Modifies real BIOS serials** - Not just registry tricks
- ✅ **Undetectable** - Changes actual hardware identifiers

### 2️⃣ Hypervisor Spoofer (Under Development)
Advanced Ring -1 hypervisor for runtime spoofing:
- 🔄 **Status: ~60% Complete** - Core framework done
- 📋 Intel VT-x / AMD-V support planned
- 📋 CPUID, RDTSC, and I/O interception
- 📋 Anti-VM detection evasion

---

## 🔥 AFUWIN Method - Step by Step

📖 **Open [`L2-HWID-Spoofer/AFUWIN-GUIDE.html`](L2-HWID-Spoofer/AFUWIN-GUIDE.html) for the complete interactive guide!**

The guide works offline and contains all steps with detailed instructions.

### Required Tools

| Tool | Purpose | Included |
|------|---------|----------|
| **AFUWIN 3.05.04** | BIOS dump and flash | ✅ Auto-download |
| **HxD Hex Editor** | Hex editing bios.rom | ✅ Auto-download |
| **DMIEdit** | SMBIOS editing GUI | ✅ Auto-download |
| **HWID Checker** | Verify changes | ✅ Auto-download |

### The Process

```
STEP 0: PREPARE
├── Download all tools (automated in L2 Master)
├── BIOS Settings:
│   ├── Disable Secure Boot + Clear keys
│   ├── Enable CSM
│   └── Disable Fast Boot

STEP 1: DUMP BIOS
├── Open Admin CMD
├── cd "AFUWIN folder"
└── AFUWINx64.exe bios.rom /O
    → Creates bios.rom file

STEP 2: SETUP EDITORS
├── Install HxD
├── Unzip DMIEdit
└── Open bios.rom in HxD

STEP 3: EDIT SERIALS (Most Important!)
├── In DMIEdit:
│   ├── [Type 001] System Serial Number → Change
│   ├── [Type 004] CPU Serial Number → Change
│   └── Click "All" lightning bolt to apply
│
├── UUID (requires HxD):
│   ├── Copy current UUID from DMIEdit
│   ├── In HxD: Ctrl+R → Hex-values
│   ├── Search: current UUID
│   ├── Replace: new UUID (auto-generate in DMIEdit)
│   └── Replace All → Save
│
└── Motherboard Serial (requires HxD):
    ├── Copy serial from DMIEdit [Type 002]
    ├── In HxD: Ctrl+R → Text-string
    ├── Replace with NEW serial (same length!)
    └── Save

STEP 4: FLASH NEW BIOS ⚠️ DANGEROUS ⚠️
├── AFUWINx64.exe bios.rom /GAN
│   (The /GAN flag forces flash)
└── Wait for completion - DO NOT INTERRUPT!

STEP 5: VERIFY
├── Restart computer
├── Run HWID Checker
└── Confirm serials changed
```

### ⚠️ ASUS Motherboards - Special Warning

ASUS boards have additional protection. The AFUWIN method **can work** on ASUS if:
- CSM is properly enabled
- Secure Boot is fully disabled with keys cleared
- You use the correct AFUWIN version (3.05.04)
- **However, risk of bricking is HIGHER on ASUS boards**

---

## 🚀 Quick Start - L2 HWID Master App

### Option 1: WPF Application (Recommended)

```powershell
cd L2-HWID-Master-App\src\L2.HwidMaster.UI
dotnet run
```

Features:
- 📊 Dashboard with current hardware fingerprint
- 📥 Automatic tool downloads (AFUWIN, HxD, DMIEdit)
- 📖 Step-by-step guided spoofing wizards
- 💾 Backup and restore functionality

### Option 2: PowerShell Scripts

```powershell
cd L2-HWID-Spoofer
.\L2-HWID-Master.ps1
```

Or double-click: `START-L2-MASTER.bat`

---

## 📁 Project Structure

```
L2 ISO project/
│
├── L2-HWID-Master-App/           # WPF Application (NEW)
│   └── src/L2.HwidMaster.UI/     # Dark-themed .NET 10 app
│
├── L2-HWID-Spoofer/              # PowerShell Tools
│   ├── L2-HWID-Master.ps1        # Main interactive launcher
│   ├── core/
│   │   ├── ToolDownloader.ps1    # Auto-download AFUWIN, HxD, etc.
│   │   └── BackupService.ps1     # Backup/restore
│   └── methods/                  # Individual spoofers
│
├── Hypervisor-Test-Spoofer/      # Ring -1 Spoofer (IN DEVELOPMENT)
│   ├── 01-Source/                # C source code
│   │   ├── hypervisor/           # VMX/SVM engine
│   │   └── spoofing/             # Spoof modules
│   └── STATUS: ~60% complete
│
├── Windows-ISO-Spoofer/          # Legacy EFI method
│   └── (Deprecated in favor of AFUWIN)
│
└── dev-utils/
    └── L2 SETUP/                 # Reference implementation
```

---

## 🛡️ What Gets Spoofed

### AFUWIN Method (Permanent)
| Identifier | Status | Notes |
|------------|--------|-------|
| System Serial Number | ✅ Permanent | DMIEdit [Type 001] |
| CPU Serial Number | ✅ Permanent | DMIEdit [Type 004] |
| System UUID | ✅ Permanent | HxD hex replace |
| Motherboard Serial | ✅ Permanent | HxD text replace |
| BIOS Serial | ✅ Permanent | Included in flash |

### Software Methods (L2-HWID-Spoofer)
| Identifier | Status | Notes |
|------------|--------|-------|
| MAC Address | ✅ Working | Registry + adapter config |
| Volume Serial | ✅ Working | VolumeID tool |
| Machine GUID | ✅ Working | Registry modification |
| Monitor EDID | ✅ Working | MonitorSpoofer tool |
| HwProfile GUID | ✅ Working | Registry modification |

### Hypervisor Method (Under Development)
| Identifier | Status | Notes |
|------------|--------|-------|
| CPUID | 🔄 60% | VMX interception |
| Disk Serial (I/O) | 🔄 60% | Port interception |
| RDTSC Timing | 🔄 60% | Compensation |

---

## 💻 System Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Windows 10/11 64-bit |
| **BIOS** | UEFI with CSM support |
| **.NET** | .NET 8+ (for WPF app) |
| **Admin** | Required for all operations |

### For Hypervisor (Future)
| Component | Requirement |
|-----------|-------------|
| **CPU** | Intel VT-x or AMD-V |
| **Visual Studio** | 2022 with WDK |
| **Test Signing** | Enabled |

---

## ⚠️ Safety Checklist

Before using AFUWIN method:

- [ ] I understand this can brick my motherboard
- [ ] I have a backup computer available
- [ ] I have saved all important data
- [ ] I will NOT interrupt the flash process
- [ ] I have verified my BIOS settings (CSM on, Secure Boot off)
- [ ] I accept full responsibility for any damage

---

## ⚖️ Legal Disclaimer

> **FOR EDUCATIONAL AND RESEARCH PURPOSES ONLY**

This project is intended for:
- ✅ Security researchers studying hardware identification
- ✅ Anti-cheat developers testing detection mechanisms
- ✅ Educational purposes for low-level system programming

**NOT intended for:**
- ❌ Bypassing anti-cheat in online games
- ❌ Evading bans or service restrictions
- ❌ Any illegal activities

**Users are fully responsible for:**
- Compliance with all applicable laws
- Any damage to hardware resulting from BIOS modifications
- Violations of Terms of Service

---

## 🗺️ Development Status

| Component | Completion | Status |
|-----------|------------|--------|
| **AFUWIN Tool Downloads** | 100% | ✅ Production |
| **L2-HWID-Master PowerShell** | 90% | ✅ Working |
| **L2 HWID Master WPF App** | 60% | 🔄 In Progress |
| **Hypervisor Spoofer** | 60% | 🔄 In Development |
| **EFI Spoofer (Legacy)** | 100% | ⚠️ Deprecated |

---

<div align="center">

**Built with 🔥 for hardware security research**

*Permanent BIOS-level spoofing that actually works*

</div>
