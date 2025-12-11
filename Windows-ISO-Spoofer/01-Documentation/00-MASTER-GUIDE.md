# 🎓 Complete Master Guide - Windows 10 Spoofer ISO Builder

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding the Approach](#understanding-the-approach)
4. [Initial Setup](#initial-setup)
5. [Configuration](#configuration)
6. [Building the ISO](#building-the-iso)
7. [Testing](#testing)
8. [Deployment](#deployment)
9. [Verification](#verification)
10. [Troubleshooting](#troubleshooting)

---

## Introduction

### What You're Building

A custom Windows 10 installation ISO that:
1. **Boots normally** with Secure Boot enabled
2. **Automatically runs your EFI spoofer** before Windows loads
3. **Spoofs SMBIOS values** on every boot (persistent)
4. **Works seamlessly** - no manual intervention after initial MOK enrollment

### Why This Approach is Superior

```
Traditional EFI Spoofer:
❌ Requires Secure Boot disabled
❌ Lost on every reboot
❌ Manual execution needed

BIOS Flashing:
❌ 40-90% brick risk
❌ Breaks Secure Boot
❌ Irreversible if failed

THIS Method:
✅ Works with Secure Boot ON
✅ Automatic on every boot
✅ Zero hardware risk
✅ Fully reversible
✅ Professional and reliable
```

---

## Prerequisites

### Hardware Requirements

- **Your ASUS TUF Gaming A520M-PLUS II** (or any UEFI motherboard)
- **16+ GB free disk space** for ISO building
- **8+ GB USB drive** for bootable media (testing/deployment)
- **Internet connection** for downloading tools

### Software Requirements

```powershell
# Check PowerShell version (should be 5.1+)
$PSVersionTable.PSVersion

# Check if running as Administrator
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

### Files You Need

1. **Windows 10 ISO** (any edition)
   - Download from: https://www.microsoft.com/software-download/windows10
   - Or use your existing ISO
   - Size: ~4-5 GB

2. **Your EFI Spoofer** (that you already have)
   - Must be compiled as `.efi` executable
   - Should accept configuration file
   - Tested and working

### Knowledge Prerequisites

- ✅ Basic PowerShell usage
- ✅ Understanding of UEFI boot process (helpful)
- ✅ Familiarity with your EFI spoofer's configuration
- ⚠️ Willingness to read documentation carefully

---

## Understanding the Approach

### Boot Chain Architecture

```
Traditional Windows Boot:
┌──────────────────────────────────┐
│ UEFI Firmware                    │
└──────────────────────────────────┘
             ↓
┌──────────────────────────────────┐
│ bootx64.efi (Microsoft signed)   │
└──────────────────────────────────┘
             ↓
┌──────────────────────────────────┐
│ bootmgfw.efi (Windows Boot Mgr)  │
└──────────────────────────────────┘
             ↓
┌──────────────────────────────────┐
│ winload.efi → Windows Kernel     │
└──────────────────────────────────┘


Our Modified Boot Chain:
┌──────────────────────────────────┐
│ UEFI Firmware                    │
│ (Secure Boot ENABLED)            │
└──────────────────────────────────┘
             ↓ ✅ Verifies signature
┌──────────────────────────────────┐
│ shimx64.efi                      │
│ (Microsoft signed - Secure Boot OK) │
└──────────────────────────────────┘
             ↓ ✅ Checks MOK database
┌──────────────────────────────────┐
│ YOUR SPOOFER.efi                 │
│ (Signed with YOUR key)           │
│ - Hooks SMBIOS table reads       │
│ - Injects spoofed values         │
└──────────────────────────────────┘
             ↓ Chainloads
┌──────────────────────────────────┐
│ bootmgfw.efi (Windows Boot Mgr)  │
└──────────────────────────────────┘
             ↓
┌──────────────────────────────────┐
│ Windows Kernel                   │
│ (Sees SPOOFED SMBIOS values!)    │
└──────────────────────────────────┘
```

### Key Technologies

1. **Shim Bootloader**
   - Microsoft-signed
   - Trusted by Secure Boot
   - Has its own certificate database (MOK)
   - Used by Linux distros (Ubuntu, Fedora)

2. **MOK (Machine Owner Key)**
   - User-controlled certificate store
   - Enrollable without disabling Secure Boot
   - Verified by shim
   - One-time enrollment per machine

3. **EFI Applications**
   - Your spoofer is an EFI application
   - Runs in UEFI environment (before OS)
   - Full hardware access
   - Can modify SMBIOS tables in memory

---

## Initial Setup

### Step 1: Verify Environment

```powershell
# Run this in PowerShell (as Administrator)
cd "C:\Users\davie\OneDrive\Área de Trabalho\L2 SETUP\Windows-Spoofer-ISO-Builder"

# Check if running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ ERROR: Must run as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
```

### Step 2: Run Setup Script

```powershell
# This will:
# - Check prerequisites
# - Download required tools
# - Verify disk space
# - Create working directories

.\03-Build-Scripts\00-SETUP.ps1
```

Expected output:
```
🔧 Windows Spoofer ISO Builder - Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Administrator privileges: OK
✅ PowerShell version: 5.1.19041.4894
✅ Free disk space: 45 GB

📥 Downloading required tools...
  ✅ OSCDIMG (Windows ADK)
  ✅ 7-Zip
  ✅ sbsign (EFI Signing)
  ✅ GRUB utilities

✅ Setup complete! Ready to build.
```

### Step 3: Place Your Files

```powershell
# 1. Copy your Windows 10 ISO
Copy-Item "D:\ISOs\Windows10.iso" "02-Source-Files\Windows10.iso"

# 2. Copy your EFI spoofer
Copy-Item "D:\Tools\my-spoofer.efi" "04-EFI-Spoofer\spoofer.efi"

# 3. Verify files
Get-ChildItem "02-Source-Files\Windows10.iso"
Get-ChildItem "04-EFI-Spoofer\spoofer.efi"
```

---

## Configuration

### Step 1: Generate Your Signing Certificate

```powershell
cd "07-Keys-And-Certs"
.\generate-keys.ps1
```

This creates:
- `my-signing-key.key` - Your private key (KEEP SECRET!)
- `my-signing-cert.crt` - Your public certificate
- `my-signing-cert.cer` - Certificate for MOK enrollment

**⚠️ IMPORTANT**: Keep `my-signing-key.key` secure! Anyone with this key can sign bootloaders trusted by your MOK.

### Step 2: Configure Your Spoofer

Edit `04-EFI-Spoofer\config.ini`:

```ini
# SMBIOS Configuration for Your ASUS TUF Gaming A520M-PLUS II
[SMBIOS]
# System Information (Type 1)
SystemManufacturer=ASUSTeK COMPUTER INC.
SystemProductName=TUF GAMING A520M-PLUS II
SystemVersion=System Version
SystemSerialNumber=SPOOFED-SERIAL-001
SystemUUID=12345678-9ABC-DEF0-1234-567890ABCDEF
SystemSKUNumber=SKU
SystemFamily=To be filled by O.E.M.

# Baseboard Information (Type 2)
BaseboardManufacturer=ASUSTeK COMPUTER INC.
BaseboardProductName=TUF GAMING A520M-PLUS II
BaseboardVersion=Rev X.0x
BaseboardSerialNumber=SPOOFED-MB-SERIAL-001
BaseboardAssetTag=Default string

# Chassis Information (Type 3)
ChassisManufacturer=Default string
ChassisType=3
ChassisVersion=Default string
ChassisSerialNumber=SPOOFED-CHASSIS-001
ChassisAssetTag=Default string

# BIOS Information (Type 0)
BIOSVendor=American Megatrends Inc.
BIOSVersion=CUSTOM-VERSION-1.0
BIOSReleaseDate=01/01/2024

[Options]
# Should the spoofer create a log file?
EnableLogging=true

# Where to save the log (ESP partition)
LogPath=\EFI\Spoofer\spoofer.log

# Show a message during boot? (debug only)
ShowDebugMessages=false

# Delay before chainloading Windows (milliseconds)
BootDelay=0
```

### Step 3: Test Your Spoofer Configuration

Before building the ISO, verify your spoofer's config is valid:

```powershell
# Parse and validate configuration
.\04-EFI-Spoofer\validate-config.ps1
```

---

## Building the ISO

### Automated Build (Recommended)

```powershell
# Run the master build script
.\03-Build-Scripts\00-BUILD-ALL.ps1
```

This will:
1. Extract Windows 10 ISO
2. Integrate your EFI spoofer
3. Sign bootloader components
4. Modify boot configuration
5. Create final ISO
6. Verify integrity

Expected output:
```
🏗️ Windows Spoofer ISO Builder - Master Build
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] Extracting Windows 10 ISO...
  📁 Mounting: 02-Source-Files\Windows10.iso
  📁 Copying files to: 02-Source-Files\extracted\
  ✅ Extracted 4,234 files (4.8 GB)

[2/6] Integrating EFI Spoofer...
  📝 Copying shim bootloader
  📝 Copying your spoofer: spoofer.efi
  📝 Creating boot configuration
  ✅ Spoofer integrated

[3/6] Signing Bootloader Components...
  🔐 Signing spoofer.efi with your certificate
  🔐 Certificate: CN=ASUS Spoofer Key
  ✅ Spoofer signed successfully

[4/6] Modifying Boot Configuration...
  📝 Updating Boot Configuration Data (BCD)
  📝 Setting boot order
  📝 Configuring chainload to Windows
  ✅ Boot configuration updated

[5/6] Creating Final ISO...
  📦 Repacking modified files
  📦 Creating bootable ISO structure
  📦 Running OSCDIMG...
  ✅ ISO created: 05-Output\Windows10-Spoofed.iso (5.1 GB)

[6/6] Verifying Integrity...
  ✅ Boot sector: Valid
  ✅ File structure: Valid
  ✅ Signatures: Valid

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ BUILD COMPLETE!

📁 Output: 05-Output\Windows10-Spoofed.iso
📝 Build log: 05-Output\build-logs\build-2024-11-13-170523.log

Next steps:
1. Test in VM: .\08-Testing\test-vm.ps1
2. Burn to USB: Use Rufus or similar
3. Deploy to hardware
```

### Manual Build (Advanced)

If you want more control:

```powershell
# Step-by-step
.\03-Build-Scripts\01-extract-iso.ps1
.\03-Build-Scripts\02-integrate-spoofer.ps1
.\03-Build-Scripts\03-sign-bootloader.ps1
.\03-Build-Scripts\04-create-iso.ps1
```

---

## Testing

### Step 1: Test in Virtual Machine

**⚠️ CRITICAL**: Always test in a VM before deploying to real hardware!

```powershell
# Create a test VM and boot the ISO
.\08-Testing\test-vm.ps1 -IsoPath "05-Output\Windows10-Spoofed.iso"
```

This script will:
1. Create a Hyper-V VM (or guide you to use VirtualBox/VMware)
2. Configure UEFI boot
3. Attach your ISO
4. Boot the VM

### Step 2: MOK Enrollment in VM

On first boot, you'll see:

```
╔═══════════════════════════════════════╗
║  Perform MOK Management               ║
║                                       ║
║  1. Enroll MOK                        ║
║  2. Enroll key from disk              ║
║  3. List enrolled keys                ║
║  4. Continue boot                     ║
╚═══════════════════════════════════════╝
```

**Do this**:
1. Select **"1. Enroll MOK"** or **"2. Enroll key from disk"**
2. Navigate to `\EFI\Keys\my-signing-cert.cer`
3. Select "Yes" to enroll
4. It may ask for a password - just press Enter (no password)
5. Reboot

After reboot, Windows should install normally with spoofing active!

### Step 3: Verify Spoofing Works

Once Windows is installed in the VM:

```powershell
# Check SMBIOS values
Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer, Model
Get-WmiObject Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber
Get-WmiObject Win32_BIOS | Select-Object SerialNumber

# Should show your spoofed values!
```

Expected output:
```
Manufacturer : ASUSTeK COMPUTER INC.
Model        : TUF GAMING A520M-PLUS II

Manufacturer : ASUSTeK COMPUTER INC.
Product      : TUF GAMING A520M-PLUS II
SerialNumber : SPOOFED-MB-SERIAL-001

SerialNumber : SPOOFED-SERIAL-001
```

### Step 4: Verify Secure Boot Status

```powershell
# Check if Secure Boot is enabled
Confirm-SecureBootUEFI

# Should return: True
```

---

## Deployment

### Step 1: Burn ISO to USB

#### Using Rufus (Recommended)

1. Download Rufus: https://rufus.ie
2. Insert USB drive (8+ GB)
3. Run Rufus
4. Settings:
   - **Device**: Your USB drive
   - **Boot selection**: Select `Windows10-Spoofed.iso`
   - **Partition scheme**: GPT
   - **Target system**: UEFI (non-CSM)
   - **File system**: FAT32
5. Click **START**
6. Wait for completion

#### Using PowerShell

```powershell
# Alternative method
.\08-Testing\create-bootable-usb.ps1 -IsoPath "05-Output\Windows10-Spoofed.iso" -UsbDrive "E:"
```

### Step 2: Boot from USB on Your ASUS Motherboard

1. **Insert USB** into your ASUS TUF Gaming A520M-PLUS II
2. **Power on** and press **F8** (or Del for BIOS)
3. **Select boot device**: Choose your USB drive
4. **Important**: Ensure Secure Boot is **ENABLED** in BIOS

### Step 3: MOK Enrollment (One-Time)

Same as VM testing - you'll see the MOK Management screen:

```
╔═══════════════════════════════════════╗
║  Perform MOK Management               ║
║                                       ║
║  1. Enroll MOK                        ║
║  2. Enroll key from disk              ║
║  3. List enrolled keys                ║
║  4. Continue boot                     ║
╚═══════════════════════════════════════╝
```

**Enroll your certificate**:
1. Select "2. Enroll key from disk"
2. Navigate to `\EFI\Keys\my-signing-cert.cer` on the USB
3. Confirm enrollment
4. Reboot

### Step 4: Install Windows

After MOK enrollment and reboot:
1. Windows installer will start normally
2. Install as usual
3. **Your spoofer is now running on every boot!**

---

## Verification

### Check SMBIOS Values

```powershell
# After Windows installation, verify spoofing:

# System Info
systeminfo | findstr /B /C:"System Manufacturer" /C:"System Model" /C:"System Type"

# WMI Queries
Get-WmiObject Win32_ComputerSystem | Format-List Manufacturer, Model
Get-WmiObject Win32_BaseBoard | Format-List Manufacturer, Product, SerialNumber
Get-WmiObject Win32_BIOS | Format-List Manufacturer, SerialNumber, Version

# Expected: All values should match your config.ini
```

### Check Secure Boot Status

```powershell
# Verify Secure Boot is still enabled
Confirm-SecureBootUEFI
# Should return: True

# Check MOK enrollment
Get-SecureBootUEFI -Name PK
Get-SecureBootUEFI -Name KEK
Get-SecureBootUEFI -Name db
# Your certificate should be listed
```

### Check Boot Log

```powershell
# If you enabled logging in config.ini
# Mount EFI partition and check log

mountvol S: /S
Get-Content "S:\EFI\Spoofer\spoofer.log"
```

Expected log content:
```
[2024-11-13 17:30:45] Spoofer started
[2024-11-13 17:30:45] Configuration loaded from: \EFI\Spoofer\config.ini
[2024-11-13 17:30:45] SMBIOS Table found at: 0x7FE00000
[2024-11-13 17:30:45] Hooking SMBIOS reads...
[2024-11-13 17:30:45] System Manufacturer: ASUSTeK COMPUTER INC. → ASUSTeK COMPUTER INC.
[2024-11-13 17:30:45] System Product: TUF GAMING A520M-PLUS II → TUF GAMING A520M-PLUS II
[2024-11-13 17:30:45] System Serial: [ORIGINAL] → SPOOFED-SERIAL-001
[2024-11-13 17:30:45] System UUID: [ORIGINAL] → 12345678-9ABC-DEF0-1234-567890ABCDEF
[2024-11-13 17:30:45] Baseboard Serial: [ORIGINAL] → SPOOFED-MB-SERIAL-001
[2024-11-13 17:30:45] SMBIOS spoofing complete!
[2024-11-13 17:30:45] Chainloading: \EFI\Microsoft\Boot\bootmgfw.efi
```

---

## Troubleshooting

### Issue 1: MOK Enrollment Screen Doesn't Appear

**Symptoms**: ISO boots directly to Windows installer

**Cause**: Shim not configured properly

**Solution**:
```powershell
# Rebuild with verbose logging
.\03-Build-Scripts\02-integrate-spoofer.ps1 -Verbose

# Check that shimx64.efi is in place:
# 02-Source-Files\modified\efi\boot\bootx64.efi should be shimx64.efi
```

### Issue 2: "Signature Verification Failed" Error

**Symptoms**: Boot halts with security error

**Cause**: Spoofer not signed, or certificate not enrolled

**Solution**:
1. Disable Secure Boot temporarily in BIOS
2. Boot from USB
3. Manually enroll MOK from EFI Shell
4. Re-enable Secure Boot

### Issue 3: Spoofer Not Running

**Symptoms**: Windows shows original SMBIOS values

**Cause**: Boot chain not configured correctly

**Solution**:
```powershell
# Check boot configuration
.\08-Testing\verify-boot-chain.ps1 -IsoPath "05-Output\Windows10-Spoofed.iso"

# Rebuild with correct boot order
.\03-Build-Scripts\04-create-iso.ps1 -FixBootOrder
```

### Issue 4: Windows Activation Issues

**Symptoms**: Windows not activated after spoofing

**Cause**: SMBIOS values changed

**Solutions**:
1. **Use a valid product key**:
   ```powershell
   slmgr /ipk YOUR-PRODUCT-KEY
   slmgr /ato
   ```

2. **Link to Microsoft account** (digital license)

3. **Use original values** in config.ini to keep activation

### Issue 5: Blue Screen or Boot Loop

**Symptoms**: Windows crashes during boot

**Cause**: Spoofer modifying wrong memory regions

**Solution**:
1. Boot from USB again
2. Choose "Repair your computer"
3. Advanced options → Command Prompt
4. Delete spoofer:
   ```cmd
   mountvol S: /S
   del S:\EFI\Spoofer\spoofer.efi
   ```
5. Fix your spoofer code
6. Rebuild ISO

---

## Advanced Topics

### Custom Boot Menu

Add a menu to choose between spoofed/non-spoofed boot:

Edit `04-EFI-Spoofer\grub.cfg`:
```bash
set timeout=5

menuentry 'Windows 10 (SMBIOS Spoofed)' {
    chainloader /EFI/Spoofer/spoofer.efi
}

menuentry 'Windows 10 (Original SMBIOS)' {
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
```

### Multiple Spoofer Profiles

Create different configs for different scenarios:

```
04-EFI-Spoofer/
├── config-profile1.ini
├── config-profile2.ini
└── config-profile3.ini
```

Switch between them using GRUB menu.

### Updating the Spoofer

To update your spoofer without rebuilding entire ISO:

```powershell
# Mount EFI partition
mountvol S: /S

# Replace spoofer
Copy-Item "new-spoofer.efi" "S:\EFI\Spoofer\spoofer.efi" -Force

# Sign it
sbsign --key "07-Keys-And-Certs\my-signing-key.key" --cert "07-Keys-And-Certs\my-signing-cert.crt" --output "S:\EFI\Spoofer\spoofer.efi" "S:\EFI\Spoofer\spoofer.efi"

# Reboot
```

---

## Security Considerations

### Protecting Your Signing Key

```powershell
# Encrypt your private key
.\07-Keys-And-Certs\encrypt-key.ps1

# Store in secure location
# Consider using hardware security module (HSM)
```

### Detecting Spoofing

Your spoofer can be detected by:
- Comparing SMBIOS to hardware queries
- Checking for shim in boot chain
- Memory forensics
- Advanced anti-cheat systems

**Mitigation**: Use realistic values that match your hardware.

---

## Next Steps

1. **Read**: `01-Secure-Boot-MOK.md` for deep dive on MOK
2. **Read**: `02-EFI-Integration.md` for spoofer development
3. **Experiment**: Try different configurations
4. **Share**: Help others in the community

---

## Summary Checklist

- [ ] Prerequisites verified
- [ ] Tools downloaded (00-SETUP.ps1)
- [ ] Files placed (ISO + spoofer)
- [ ] Certificate generated
- [ ] Config.ini customized
- [ ] ISO built successfully
- [ ] Tested in VM
- [ ] MOK enrolled
- [ ] Spoofing verified in VM
- [ ] USB bootable media created
- [ ] Deployed to real hardware
- [ ] MOK enrolled on real hardware
- [ ] Windows installed
- [ ] Spoofing verified on real hardware
- [ ] Secure Boot status verified
- [ ] Documentation read

---

**🎉 Congratulations!**

You now have a professional Windows 10 ISO with integrated SMBIOS spoofing that works with Secure Boot enabled!

**Next**: Explore advanced customization in `01-Documentation/06-Advanced-Customization.md`

---

*Questions? Check `04-Troubleshooting.md` or review build logs.*

