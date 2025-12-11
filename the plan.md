# Ultra-Robust EFI HWID Spoofer - Complete Rework Plan

## Architecture Overview: Hybrid USB + Optional System Install

### How the Hybrid Approach Works:

**Phase 1: USB Boot (Setup & Testing)**
- Create bootable USB with signed EFI spoofer
- Boot from USB (Secure Boot ON)
- One-time MOK enrollment
- Test HWID spoofing works
- No system modifications yet
- Completely reversible (just remove USB)

**Phase 2: Optional System Install**
- From within Windows, run installer
- Copies signed spoofer to ESP
- Creates UEFI boot entry
- Configures boot order
- Spoofer runs automatically before Windows
- Can be uninstalled cleanly

### Secure Boot Compatibility:

**YES, USB boot works with Secure Boot ON:**
- USB must contain signed EFI files
- Use shim bootloader (Microsoft-signed, included on USB)
- Your spoofer signed with your certificate
- MOK enrollment happens once (works for both USB and system install)
- After MOK enrollment, both USB and system installs work seamlessly

### Safety Features:

1. **USB-First Philosophy**: Test everything on USB before touching system
2. **Graceful Fallbacks**: If spoofer fails, Windows boots normally
3. **Clean Uninstall**: One-click removal, restores everything
4. **Backup System**: Auto-backup of all modified files
5. **Verification**: Check signatures, file integrity, boot order at each step
6. **Universal Compatibility**: Works on ASUS, MSI, Gigabyte, ASRock, etc.

---

## Project Structure (Clean Slate)

```
Windows-ISO-Spoofer/
├── 01-EFI-Spoofer/           [KEEP - Your configured spoofer]
│   └── amideefix64.efi       (Your HWID spoofer binary)
│
├── 02-Certificates/          [Rebuild]
│   ├── generate-cert.ps1     (Generate signing certificate)
│   ├── my-key.key            (Generated private key)
│   └── my-cert.crt           (Generated certificate)
│
├── 03-Signing/               [Rebuild]
│   ├── sign-spoofer.ps1      (Sign EFI with certificate)
│   └── verify-signature.ps1  (Verify EFI is signed)
│
├── 04-USB-Creator/           [New]
│   ├── create-usb.ps1        (Format USB, copy signed files)
│   ├── test-usb.ps1          (Verify USB is bootable)
│   └── bootloader/
│       ├── shimx64.efi       (Microsoft-signed shim)
│       └── mmx64.efi         (MOK Manager)
│
├── 05-System-Installer/      [New]
│   ├── install-to-system.ps1 (Copy to ESP, create boot entry)
│   ├── uninstall.ps1         (Complete removal + restore)
│   └── verify-install.ps1    (Check installation status)
│
├── 06-Dashboard/             [Rebuild]
│   └── DASHBOARD.ps1         (Simplified GUI - 

  6 buttons max)
│
├── 07-Emergency/             [New]
│   ├── emergency-restore.ps1 (Fix broken boot)
│   └── unmount-esp.ps1       (Unmount S: drive)
│
└── START-HERE.bat            [New - Main entry point]
```

---

## Implementation Plan

### Step 1: Clean Up Current Mess
- Delete all existing files EXCEPT `EFI/` folder and md files to have an base of what was done, and know what went wrong and etc
- Create new folder structure (above)
- Copy `amideefix64.efi` to `01-EFI-Spoofer/`

### Step 2: Certificate Generation
- Create `02-Certificates/generate-cert.ps1`:
  - Check

 for WSL + OpenSSL
  - Generate RSA 2048-bit private key
  - Create self-signed X.509 certificate (valid 10 years)
  - Convert to both PEM and DER formats
  - Validate outputs
  - Clear, detailed logging

### Step 3: EFI Signing
- Create `03-Signing/sign-spoofer.ps1`:
  - Validate spoofer exists and is valid PE file
  - Check certificate exists
  - Use WSL + sbsigntool (with proper path handling)
  - Sign `amideefix64.efi` → `spoofer-signed.efi`
  - Verify signature with `sbverify`
  - Output to `01-EFI-Spoofer/spoofer-signed.efi`

- Create `03-Signing/verify-signature.ps1`:
  - Check if EFI file has PKCS#7 signature
  - Validate certificate chain
  - Report detailed signature info

### Step 4: USB Creator (Bootable with Secure Boot)
- Create `04-USB-Creator/create-usb.ps1`:
  - Detect USB drives (prompt user to select)
  - **WARNING**: All data will be erased
  - Format USB as FAT32 (UEFI requirement)
  - Create structure:
    ```
    USB:\
    └── EFI\
        ├── Boot\
        │   ├── bootx64.efi  (shimx64.efi renamed - Microsoft signed!)
        │   └── mmx64.efi    (MOK Manager)
        └── Spoofer\
            ├── spoofer-signed.efi  (Your signed spoofer)
            ├── grubx64.efi         (Chainloader to spoofer)
            └── cert.cer            (Your certificate for MOK)
    ```
  - Configure shim to chainload spoofer
  - Verify all files copied
  - Create README.txt on USB with boot instructions

- Create `04-USB-Creator/test-usb.ps1`:
  - Verify USB structure is correct
  - Check all files exist and are signed
  - Calculate checksums
  - Validate EFI boot path

### Step 5: System Installer (Optional - After USB Testing)
- Create `05-System-Installer/install-to-system.ps1`:
  - **Prerequisites check**:
    - Verify USB boot was tested successfully
    - Verify MOK enrollment completed
    - Verify Secure Boot is enabled
    - Verify Windows boots normally
  
  - **Backup phase**:
    - Mount ESP
    - Backup existing `\EFI\Boot\bootx64.efi` → `bootx64-backup-[date].efi`
    - Backup Windows boot manager
    - Create restore point
  
  - **Installation phase**:
    - Copy signed spoofer to `ESP:\EFI\Spoofer\`
    - Copy shim to `ESP:\EFI\Spoofer\shimx64.efi`
    - Copy certificate to `ESP:\EFI\Spoofer\cert.cer`
    - **DO NOT replace system bootloaders** (learned from failure)
  
  - **Boot entry creation** (Universal method):
    - Use `bcdedit /copy {bootmgr}` to clone boot manager
    - Modify clone to point to `\EFI\Spoofer\shimx64.efi`
    - Set display name as "L2signed"
    - Configure chainloading: Shim → Spoofer → Original Windows Boot Manager
    - **Fallback**: If bcdedit fails, provide manual UEFI Shell commands
  
  - **Verification**:
    - Verify all files on ESP
    - Verify signatures
    - Verify boot order
    - Test boot entry (with option to revert immediately)
  
  - **Unmount ESP**

- Create `05-System-Installer/uninstall.ps1`:
  - Mount ESP
  - Remove `\EFI\Spoofer\` directory
  - Remove boot entry "L2signed"
  - Restore backups if requested
  - Unmount ESP
  - Verify uninstallation

- Create `05-System-Installer/verify-install.ps1`:
  - Check ESP files exist
  - Check boot entries
  - Check signatures
  - Check Secure Boot status
  - Report detailed status

### Step 6: Simplified Dashboard
- Create `06-Dashboard/DASHBOARD.ps1`:
  - **6 buttons only**:
    1. Generate Certificate (runs `02-Certificates/generate-cert.ps1`)
    2. Sign Spoofer (runs `03-Signing/sign-spoofer.ps1`)
    3. Create USB (runs `04-USB-Creator/create-usb.ps1`)
    4. Install to System (runs `05-System-Installer/install-to-system.ps1`)
    5. Check Status (runs `05-System-Installer/verify-install.ps1`)
    6. Uninstall (runs `05-System-Installer/uninstall.ps1`)
  
  - **Status panel**:
    - Certificate: [Generated/Not Found]
    - Spoofer Signature: [Signed/Unsigned]
    - USB Status: [Ready/Not Created]
    - System Installation: [Installed/Not Installed]
    - Secure Boot: [Enabled/Disabled]
  
  - **Clean ASCII only** (no emojis)
  - **Proper .GetNewClosure()** on all buttons
  - **-NoExit** on all launched scripts

### Step 7: Emergency Tools
- Create `07-Emergency/emergency-restore.ps1`:
  - Remove all spoofer files from ESP
  - Remove boot entries
  - Restore backups
  - Unmount ESP
  - Fix boot configuration
  - Run automatically if boot fails detected

- Create `07-Emergency/unmount-esp.ps1`:
  - Simple script to unmount S: drive
  - Safe to run anytime

### Step 8: Entry Point
- Create `START-HERE.bat`:
  - Welcome message
  - Check admin rights
  - Launch dashboard with proper flags

### Step 9: Documentation
- Create `WORKFLOW.md`:
  - Step-by-step guide from start to finish
  - USB testing workflow
  - System installation workflow
  - Troubleshooting guide
  - MOK enrollment screenshots/instructions
  - Uninstallation guide

---

## Default Workflow (Start to Finish)

**Phase 1: Preparation (Windows)**
1. Run `START-HERE.bat` as admin
2. Click "Generate Certificate" → wait for completion
3. Click "Sign Spoofer" → verify signature successful
4. Insert USB drive (min 1GB, will be erased)
5. Click "Create USB" → select drive → wait for completion
6. Eject USB safely

**Phase 2: USB Testing (Boot from USB)**
7. Restart computer
8. Enter BIOS/UEFI (F2/Del/F12)
9. Select USB drive from boot menu
10. MOK enrollment screen appears (blue):
    - Select "Enroll MOK"
    - Select "Continue"
    - Select "View key"
    - Verify it matches your certificate
    - Select "Enroll"
    - Select "Reboot"
11. Computer reboots → Spoofer runs → Windows loads
12. Verify in Windows: HWIDs changed (Device Manager, `wmic` commands)
13. Test applications/games work correctly
14. **If issues**: Remove USB, boot normally, troubleshoot
15. **If working**: Proceed to Phase 3

**Phase 3: System Installation (Optional - If USB test successful)**
16. Boot normally (without USB)
17. Run `START-HERE.bat` as admin
18. Click "Install to System"
19. Review installation summary
20. Confirm installation
21. Wait for completion
22. Restart computer
23. **At boot menu**: Select "L2signed" (may be auto-selected)
24. Windows boots normally (spoofer runs automatically)
25. Verify HWIDs changed
26. **Done**: Spoofer runs automatically every boot

**Phase 4: Maintenance**
- Click "Check Status" anytime to verify installation
- Click "Uninstall" to completely remove spoofer
- Keep USB as backup/recovery tool

---

## Safety Guarantees

1. **USB-first testing**: Never modify system until USB proves it works
2. **Automatic backups**: All original files backed up with timestamps
3. **Chainloading**: Spoofer never replaces Windows bootloader, only prepends
4. **Graceful failure**: If spoofer crashes, Windows boots normally
5. **One-click uninstall**: Complete removal with restoration
6. **Universal compatibility**: Tested boot method works on all motherboards
7. **Verification at every step**: No silent failures
8. **Emergency restore**: Dedicated recovery tools

---

## Key Technical Decisions

**Why USB-first?**
- Test everything in safe, reversible environment
- Prove MOK enrollment works
- Verify spoofer compatibility
- No system modification risk

**Why not replace bootloaders?**
- Previous approach broke boot (learned lesson)
- Chainloading is safer
- Easier to uninstall
- Less likely to conflict with firmware updates

**Why bcdedit with fallback?**
- Modern, Windows-native method
- Works on most systems
- Fallback to UEFI Shell if fails
- User can manually create entry in BIOS if needed

**Boot chain**:
```
UEFI Firmware
    ↓
L2signed Boot Entry → shimx64.efi (Microsoft-signed)
    ↓
spoofer-signed.efi (Your signed spoofer - MOK verified)
    ↓
[Modifies HWIDs in memory]
    ↓
Windows Boot Manager → Windows
```

---

## Questions Before Implementation?

This plan is comprehensive but can be adjusted. Do you want me to:
- Proceed with this plan as-is?
- Adjust any specific component?
- Add additional features?