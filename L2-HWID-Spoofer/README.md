# L2 HWID Master

Comprehensive Hardware ID Spoofing Solution for Windows with **Interactive Step-by-Step Guides**.

## 🚀 Quick Start

**Option 1: Double-click the launcher**
```
START-L2-MASTER.bat    (Run as Administrator)
```

**Option 2: PowerShell**
```powershell
# Run as Administrator
cd L2-HWID-Spoofer
.\L2-HWID-Master.ps1
```

## ✨ Features

- 📖 **Step-by-Step Guided Spoofing** - Easy wizard for each method
- 📥 **Automatic Tool Downloads** - VolumeID, CRU auto-downloaded
- 💾 **Backup & Restore** - Never lose your original settings
- 🔄 **Quick Spoof All** - One-click all spoofing methods
- 📊 **Hardware Fingerprint Viewer** - See all your IDs

## 📁 Structure

```
L2-HWID-Spoofer/
├── START-L2-MASTER.bat      # 🚀 Double-click to start!
├── L2-HWID-Master.ps1       # Main interactive launcher
├── quick-spoof.ps1          # All-in-one quick script
├── core/                    # Core modules
│   ├── SpoofingCore.ps1     # Shared functions, logging
│   ├── BackupService.ps1    # Backup/restore system
│   └── ToolDownloader.ps1   # Auto-download tools
├── methods/                 # Individual spoofers
│   ├── MacSpoofer.ps1       # MAC address spoofing
│   ├── VolumeIdSpoofer.ps1  # Volume serial spoofing
│   └── MachineGuidSpoofer.ps1  # Windows GUIDs
├── tools/                   # Downloaded tools (auto)
│   ├── VolumeID/            # Sysinternals VolumeID
│   └── CRU/                 # Custom Resolution Utility
└── README.md
```

## 🔧 Available Methods

| Method | Description | Restart Required |
|--------|-------------|------------------|
| **MAC Address** | Randomize network adapter MACs | No |
| **Volume ID** | Change drive volume serials | Yes |
| **Machine GUIDs** | Spoof Windows machine identifiers | No |

## 📋 Individual Usage

```powershell
# MAC Address Spoofing
.\methods\MacSpoofer.ps1

# Volume ID Spoofing  
.\methods\VolumeIdSpoofer.ps1

# Machine GUID Spoofing
.\methods\MachineGuidSpoofer.ps1

# List current values without changing
.\methods\MacSpoofer.ps1 -List
.\methods\VolumeIdSpoofer.ps1 -List
.\methods\MachineGuidSpoofer.ps1 -List
```

## 💾 Backup System

All spoofing operations automatically create backups before making changes.

```powershell
# Backups are stored in:
# %LOCALAPPDATA%\L2Spoofer\Backups\

# Restore from backup
.\core\BackupService.ps1
```

## ⚠️ Requirements

- Windows 10/11
- Administrator privileges
- PowerShell 5.1+

## 🔗 Based On

Methods ported from [L2 Setup](dev-utils/L2%20SETUP/) - tested and production-ready code.

---

**L2 HWID Spoofer** - Part of the L2 ISO Project
