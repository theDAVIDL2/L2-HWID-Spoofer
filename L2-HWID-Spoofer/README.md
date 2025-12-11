# L2 HWID Spoofer

Comprehensive Hardware ID Spoofing Solution for Windows.

## 🚀 Quick Start

```powershell
# Run as Administrator
cd L2-HWID-Spoofer
.\quick-spoof.ps1
```

## 📁 Structure

```
L2-HWID-Spoofer/
├── core/                    # Core modules
│   ├── SpoofingCore.ps1     # Shared functions, logging
│   └── BackupService.ps1    # Backup/restore system
├── methods/                 # Individual spoofers
│   ├── MacSpoofer.ps1       # MAC address spoofing
│   ├── VolumeIdSpoofer.ps1  # Volume serial spoofing
│   └── MachineGuidSpoofer.ps1  # Windows GUIDs
├── quick-spoof.ps1          # All-in-one script
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
