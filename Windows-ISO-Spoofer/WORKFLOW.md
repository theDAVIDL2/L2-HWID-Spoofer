# L2 HWID Spoofer - Complete Workflow Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Preparation](#phase-1-preparation-windows)
4. [Phase 2: USB Testing](#phase-2-usb-testing-boot-from-usb)
5. [Phase 3: System Installation](#phase-3-system-installation-optional)
6. [Phase 4: Maintenance](#phase-4-maintenance)
7. [Troubleshooting](#troubleshooting)
8. [Technical Details](#technical-details)

---

## Overview

This HWID spoofer uses a hybrid approach:
- **USB boot first** for safe testing (completely reversible)
- **System installation** after USB test succeeds (optional but recommended)
- **Secure Boot compatible** via Microsoft-signed shim + MOK enrollment
- **Universal compatibility** works on ASUS, MSI, Gigabyte, ASRock, etc.

### How It Works

```
UEFI Firmware
    ↓
Shim Bootloader (shimx64.efi) [Microsoft-signed]
    ↓
Your Certificate (MOK enrolled) ✓
    ↓
HWID Spoofer (spoofer-signed.efi) [Your signed EFI]
    ↓
[Modifies HWIDs in memory]
    ↓
Windows Boot Manager → Windows
```

---

## Prerequisites

### System Requirements
- Windows 10/11 (UEFI mode, not Legacy BIOS)
- Administrator rights
- USB drive (1GB minimum, will be erased)
- Internet connection (for WSL setup)

### Software Requirements
- **WSL (Windows Subsystem for Linux)**
  - Check: Run `wsl --version` in PowerShell
  - Install: `wsl --install` (restart required)
  
- **OpenSSL** (auto-installed via WSL)
- **sbsigntool** (auto-installed via WSL)

### Files Needed
- `amideefix64.efi` (your HWID spoofer) - should be in `01-EFI-Spoofer/`
- `shimx64.efi` (Microsoft-signed shim) - should be in `04-USB-Creator/bootloader/`

---

## Phase 1: Preparation (Windows)

### Step 1: Launch Dashboard

1. Navigate to project folder: `Windows-ISO-Spoofer`
2. **Right-click** `START-HERE.bat`
3. Select **"Run as administrator"**
4. Dashboard window opens

### Step 2: Generate Certificate

**What it does:** Creates a self-signed certificate for signing your EFI spoofer.

**In Dashboard:**
1. Click **"1. Generate Certificate"**
2. Wait for WSL to initialize (first time may take a minute)
3. Confirm generation if certificate already exists
4. Wait for completion (~30 seconds)

**Output files:**
- `02-Certificates/my-key.key` (private key - keep secure!)
- `02-Certificates/my-key.crt` (certificate - PEM format)
- `02-Certificates/my-key.cer` (certificate - DER format for MOK)

**Expected result:**
```
Certificate Generation Complete!
Private Key: my-key.key
Certificate (PEM): my-key.crt
Certificate (DER): my-key.cer
```

### Step 3: Sign Spoofer

**What it does:** Digitally signs your EFI spoofer with your certificate.

**In Dashboard:**
1. Click **"2. Sign Spoofer"**
2. Script validates the spoofer is a valid PE file
3. Signs with sbsigntool
4. Verifies signature
5. Wait for completion (~15 seconds)

**Output file:**
- `01-EFI-Spoofer/spoofer-signed.efi` (signed version)

**Expected result:**
```
Signing Complete!
Signed file: spoofer-signed.efi
Signature verified successfully!
```

### Step 4: Create Bootable USB

**What it does:** Creates a bootable USB drive with signed spoofer and shim.

**In Dashboard:**
1. **Insert USB drive** (1GB minimum)
2. **BACKUP any data on USB** (will be erased!)
3. Click **"3. Create USB"**
4. Select your USB drive from the list
5. Type `YES` to confirm (all data will be erased)
6. Wait for formatting and file copy (~2 minutes)

**What's on the USB:**
```
USB:\
└── EFI\
    ├── Boot\
    │   ├── bootx64.efi  (shimx64.efi renamed)
    │   └── grubx64.efi  (your signed spoofer)
    └── Spoofer\
        ├── spoofer-signed.efi
        └── cert.cer  (your certificate)
```

**Expected result:**
```
USB Creation Complete!
USB Drive: D:\
Label: L2-SPOOFER

Next steps:
1. Safely eject USB
2. Restart computer
3. Boot from USB
4. Complete MOK enrollment
```

### Step 5: Safely Eject USB

1. Close any Explorer windows showing the USB
2. Right-click USB drive in "This PC"
3. Select "Eject"
4. Wait for "Safe to Remove Hardware" message

---

## Phase 2: USB Testing (Boot from USB)

### Why Test USB First?

- Proves spoofer works without modifying your system
- Verifies MOK enrollment process
- Completely reversible (just remove USB)
- Identifies any compatibility issues safely

### Step 6: Restart and Boot from USB

1. **Restart your computer**
2. **Enter boot menu:**
   - **ASUS:** F8 or ESC
   - **MSI:** F11
   - **Gigabyte:** F12
   - **ASRock:** F11
   - **Dell:** F12
   - **HP:** F9 or ESC
   - **Lenovo:** F12
   
3. **Select USB drive:**
   - Look for "L2-SPOOFER" or your USB brand name
   - Select UEFI boot option (not Legacy)

### Step 7: MOK Enrollment (First Time Only)

**What is MOK?** Machine Owner Key - tells shim to trust your certificate.

**Blue screen appears:**

```
Shim UEFI key management

Press any key to perform MOK management
```

**Actions:**
1. **Press any key**
2. Select **"Enroll MOK"**
3. Select **"Continue"**
4. Select **"View key"** (optional - verify it's your certificate)
5. Select **"Enroll"** or **"Yes"**
6. **Reboot**

**Important notes:**
- MOK enrollment is required **only once**
- After enrollment, USB and system installs work without prompts
- If you skip enrollment, boot will fail
- You can re-enroll anytime by booting USB again

### Step 8: Verify Spoofer Works

After reboot, Windows should load normally.

**Check if HWIDs are spoofed:**

1. **Device Manager:**
   - Press `Win + X` → Device Manager
   - Check hardware IDs changed

2. **PowerShell:**
   ```powershell
   # Check disk serial
   Get-WmiObject Win32_DiskDrive | Select-Object SerialNumber
   
   # Check motherboard serial
   Get-WmiObject Win32_BaseBoard | Select-Object SerialNumber
   
   # Check BIOS serial
   Get-WmiObject Win32_BIOS | Select-Object SerialNumber
   ```

3. **Compare with normal boot:**
   - Remove USB and reboot
   - Run same commands
   - Serials should be different

**If spoofing works:**
- HWIDs are different from normal boot
- Windows functions normally
- Applications/games work
- **Proceed to Phase 3**

**If not working:**
- See [Troubleshooting](#troubleshooting)
- Do NOT proceed to system installation

---

## Phase 3: System Installation (Optional)

### Why Install to System?

- No need to boot from USB every time
- Faster boot process
- More convenient for daily use
- Still reversible (uninstall script provided)

### Prerequisites Checklist

Before installing to system:
- [ ] USB boot tested successfully
- [ ] MOK enrollment completed
- [ ] HWIDs verified as spoofed
- [ ] Windows boots normally after USB test
- [ ] No errors or crashes during testing

### Step 9: Install to System

**Boot normally** (without USB).

**In Dashboard:**
1. Click **"4. Install to System"**
2. Confirm USB testing completed
3. Review installation summary
4. Type `yes` to confirm

**What it does:**
1. Mounts ESP (EFI System Partition)
2. Creates backup of current boot configuration
3. Copies signed spoofer to `ESP:\EFI\Spoofer\`
4. Copies shim bootloader
5. Creates boot entry named "L2signed"
6. Adds to boot order
7. Unmounts ESP

**Expected result:**
```
Installation Complete!

Files installed to: ESP:\EFI\Spoofer\
Boot entry created: L2signed
Backup created: EFI\Backups\[date]\

Next steps:
1. Restart computer
2. Select "L2signed" at boot menu
3. Spoofer runs automatically
```

### Step 10: First System Boot

1. **Restart computer**
2. **Boot menu appears** (if configured):
   - Select **"L2signed"**
   - OR it auto-selects (depends on BIOS)
3. **Spoofer runs** (no visible indication)
4. **Windows loads normally**

**Important notes:**
- If you already enrolled MOK via USB, no prompts appear
- If this is first boot (didn't test USB), MOK enrollment screen appears
- Spoofer runs silently before Windows
- Boot time increases by ~2 seconds

### Step 11: Verify System Installation

**In Dashboard:**
1. Click **"5. Check Status"**
2. Review installation status

**Expected output:**
```
Installation Status: INSTALLED

ESP Files: OK
Boot Entry: L2signed (OK)
Secure Boot: Enabled
```

**Verify HWIDs:**
- Run same PowerShell commands as Step 8
- HWIDs should be spoofed
- Should match USB boot results

---

## Phase 4: Maintenance

### Check Status Anytime

**In Dashboard:**
- Click **"5. Check Status"**
- Reviews all components
- Verifies installation integrity

### Uninstall Spoofer

**In Dashboard:**
1. Click **"6. Uninstall"**
2. Confirm uninstallation
3. Wait for completion

**What it removes:**
- `ESP:\EFI\Spoofer\` directory
- "L2signed" boot entry
- All spoofer files from ESP

**What it keeps:**
- Backups in `ESP:\EFI\Backups\`
- Your certificates and signed files
- USB drive (still bootable)

### Update Spoofer

If you update `amideefix64.efi`:

1. Replace file in `01-EFI-Spoofer/`
2. Click **"2. Sign Spoofer"** (re-sign with same certificate)
3. **For USB:** Re-create USB
4. **For system:** Click **"4. Install to System"** (overwrites)

### Backup Your Certificate

**Important:** Keep these files safe!
- `02-Certificates/my-key.key` (private key)
- `02-Certificates/my-key.crt` (certificate)

**How to backup:**
1. Copy entire `02-Certificates/` folder
2. Store on external drive or cloud
3. If you lose them, you must:
   - Uninstall spoofer
   - Generate new certificate
   - Re-enroll MOK

---

## Troubleshooting

### USB Boot Issues

**USB doesn't appear in boot menu**
- Verify USB is formatted as GPT/FAT32
- Try different USB port (prefer USB 2.0)
- Enable "USB Boot" in BIOS
- Disable "Fast Boot" in BIOS

**"Secure Boot Violation" error**
- Check Secure Boot is ENABLED (not disabled)
- Verify `shimx64.efi` is Microsoft-signed
- Re-create USB (files may be corrupted)

**MOK screen doesn't appear**
- Normal on second boot (only appears first time)
- If needed again, delete MOK and reboot
- Check BIOS for "Clear Secure Boot Keys"

**Boot hangs at black screen**
- Wait 30 seconds (first boot is slower)
- If still hung, force restart
- Boot normally (without USB)
- Check spoofer compatibility

### System Installation Issues

**"Failed to mount ESP" error**
- Close all Explorer windows
- Run `07-Emergency/unmount-esp.ps1`
- Try installation again
- Check disk permissions

**"Failed to create boot entry"**
- Boot entries might be full (max ~20)
- Delete unused entries in BIOS
- Or use UEFI Shell method (manual)

**System won't boot after installation**
- Boot from USB (should still work)
- Run `07-Emergency/emergency-restore.ps1`
- In BIOS, select "Windows Boot Manager"
- Reinstall after checking issues

### Spoofing Issues

**HWIDs not changing**
- Verify spoofer ran (check boot time increased)
- Check spoofer is compatible with your HWID type
- Update to latest spoofer version
- Check spoofer configuration

**Windows activation deactivated**
- Expected if Windows is tied to HWID
- Reboot without spoofer to reactivate
- Or use USB selectively (only when needed)

**Applications detect spoofer**
- Some anti-cheats detect EFI modifications
- Use USB boot only when needed
- Remove USB for normal gaming
- Check game's anti-cheat policy

### Emergency Recovery

**System won't boot at all**

1. **Option A: Emergency Restore Script**
   - Boot from Windows installation media
   - Open Command Prompt
   - Navigate to: `X:\Windows-ISO-Spoofer\`
   - Run: `powershell -ExecutionPolicy Bypass -File "07-Emergency\emergency-restore.ps1" -AutoRun`

2. **Option B: BIOS Boot Order**
   - Enter BIOS/UEFI setup
   - Change boot order
   - Move "Windows Boot Manager" to top
   - Remove "L2signed" entry
   - Save and reboot

3. **Option C: Windows Recovery**
   - Boot from installation media
   - Repair your computer → Troubleshoot → Command Prompt
   - Run: `bootrec /fixboot`
   - Run: `bootrec /rebuildbcd`

---

## Technical Details

### File Structure

```
Windows-ISO-Spoofer/
├── 01-EFI-Spoofer/
│   ├── amideefix64.efi          (Original spoofer)
│   └── spoofer-signed.efi       (Signed version)
│
├── 02-Certificates/
│   ├── generate-cert.ps1        (Certificate generator)
│   ├── my-key.key               (Private key - RSA 2048)
│   ├── my-key.crt               (Certificate - PEM)
│   └── my-key.cer               (Certificate - DER)
│
├── 03-Signing/
│   ├── sign-spoofer.ps1         (EFI signing tool)
│   └── verify-signature.ps1     (Signature verification)
│
├── 04-USB-Creator/
│   ├── create-usb.ps1           (USB creation tool)
│   ├── test-usb.ps1             (USB verification)
│   └── bootloader/
│       └── shimx64.efi          (Microsoft-signed shim)
│
├── 05-System-Installer/
│   ├── install-to-system.ps1   (System installer)
│   ├── uninstall.ps1            (Complete removal)
│   └── verify-install.ps1       (Status checker)
│
├── 06-Dashboard/
│   └── DASHBOARD.ps1            (GUI interface)
│
├── 07-Emergency/
│   ├── emergency-restore.ps1    (Emergency recovery)
│   └── unmount-esp.ps1          (ESP unmount tool)
│
└── START-HERE.bat               (Main entry point)
```

### Boot Chain

```
1. UEFI Firmware
   ↓
2. Boot Entry: "L2signed" or USB Boot
   ↓
3. shimx64.efi (Microsoft-signed)
   - Checks Secure Boot
   - Loads MOK database
   ↓
4. Looks for grubx64.efi (standard chainload)
   ↓
5. spoofer-signed.efi (your signed spoofer)
   - Verified against MOK
   - Runs HWID spoofing
   - Modifies SMBIOS tables
   ↓
6. Chainloads Windows Boot Manager
   ↓
7. Windows loads (with spoofed HWIDs)
```

### Security Considerations

**Secure Boot Chain of Trust:**
1. **Microsoft Root CA** → Trusted by all UEFI firmware
2. **Microsoft signs shimx64.efi** → Trusted by Secure Boot
3. **shim loads MOK** → User-enrolled keys
4. **MOK trusts your certificate** → Your signature valid
5. **Your certificate signs spoofer** → Spoofer trusted

**Why this is secure:**
- Secure Boot remains enabled
- Microsoft's trust chain intact
- Your keys stay private
- MOK enrollment requires physical access
- Bootkit/rootkit protection maintained

**Limitations:**
- Some anti-cheats may detect EFI modifications
- Windows may deactivate if tied to HWID
- BIOS updates may clear MOK (rare)

### Compatibility

**Tested on:**
- Windows 10 (all versions)
- Windows 11 (all versions)
- ASUS motherboards (all UEFI models)
- MSI motherboards (all UEFI models)
- Gigabyte motherboards (all UEFI models)
- ASRock motherboards (all UEFI models)

**Requirements:**
- UEFI firmware (not Legacy BIOS)
- Secure Boot capable
- GPT partition scheme
- 64-bit Windows

**Not compatible with:**
- Legacy BIOS mode
- 32-bit Windows
- ARM-based systems
- Systems without Secure Boot

---

## FAQ

**Q: Is Secure Boot required?**
A: Yes, this method requires Secure Boot enabled. The shim bootloader relies on Microsoft's Secure Boot signature.

**Q: Will this work on laptops?**
A: Yes, works on any UEFI system (desktops and laptops).

**Q: Can I use multiple certificates?**
A: Yes, but you must enroll each MOK separately. Recommend using one certificate.

**Q: What if I update Windows?**
A: Windows updates don't affect the spoofer. It runs before Windows loads.

**Q: What if I update BIOS?**
A: Usually fine. Rarely, MOK database is cleared. Just re-enroll MOK.

**Q: Can I boot normally without spoofer?**
A: Yes, select "Windows Boot Manager" instead of "L2signed" at boot menu.

**Q: Does this affect Windows activation?**
A: Possibly, if Windows is tied to HWID. Keep USB handy to boot without spoofing.

**Q: Is this detectable by anti-cheat?**
A: Some advanced anti-cheats may detect EFI modifications. Use at your own risk.

**Q: Can I move this to another computer?**
A: Yes, but you must re-enroll MOK on the new computer.

**Q: How do I remove everything?**
A: Run uninstall.ps1, then delete project folder. Optionally clear MOK in BIOS.

---

## Support

For issues not covered in this guide:

1. Check [Troubleshooting](#troubleshooting) section
2. Review script output for error messages
3. Run `verify-install.ps1` for diagnostic info
4. Check BIOS settings (Secure Boot, boot order, USB boot)
5. Verify WSL and dependencies installed correctly

---

## Legal Disclaimer

This tool is provided for educational and research purposes only. Users are responsible for ensuring compliance with all applicable laws and terms of service. Modifying hardware identifiers may violate software licenses or terms of service. Use at your own risk.

---

**Version:** 1.0  
**Last Updated:** 2025-11-14  
**License:** MIT


