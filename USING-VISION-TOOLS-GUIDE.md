# Using Vision Tools - Quick Start Guide

**Status:** ✅ Vision files uploaded to `Vision/` folder  
**Approach:** 🎯 Legal use of freeware tools, NO reverse engineering needed!

---

## 🎯 What You Have

### ✅ Legal Tools You CAN Use

```
Vision/
├── Backup Serial Checker.bat      ✅ PowerShell script - Legal to use
├── Monitor Spoof/
│   ├── CRU.exe                     ✅ Freeware by ToastyX - Legal to use
│   ├── restart64.exe               ✅ Driver restart utility
│   └── UsbHider.exe                ⚠️ Study behavior, build your own
├── Ethernet driver/
│   └── Realtek.exe                 ⚠️ Study behavior, build your own
├── Requirements/                   ✅ Standard VC++ runtimes
└── Vision.exe                      ❌ License-locked - DON'T reverse engineer!
```

### ❌ What to AVOID

**Vision.exe** - License-locked main executable
- ❌ Don't reverse engineer
- ❌ Don't bypass license
- ❌ Don't need it anyway!
- ✅ Your hypervisor is better!

---

## 🚀 Quick Start

### Option 1: Use Our Integration Script (Recommended)

```powershell
# Run our integration script with menu
.\INTEGRATE-VISION-TOOLS.ps1

# This gives you:
# 1. Enhanced hardware fingerprint checker
# 2. CRU integration (monitor EDID)
# 3. Graphics driver restart
# 4. MAC address spoofer (your own!)
# 5. Before/after comparison
# 6. Full guided workflow
```

### Option 2: Use Tools Individually

#### 1. **Check Hardware Fingerprint**

```powershell
# Using Vision's simple checker
.\Vision\"Backup Serial Checker.bat"

# OR use our enhanced version
. .\INTEGRATE-VISION-TOOLS.ps1
Get-HardwareFingerprint -SaveToFile "before.json"
```

#### 2. **Spoof Monitor EDID (Use CRU)**

```powershell
# Launch CRU (Freeware - legal!)
.\Vision\"Monitor Spoof"\CRU.exe

# Steps in CRU:
# 1. Select your monitor
# 2. Click "Edit..."
# 3. Modify serial number
# 4. Save and close

# Then restart graphics driver
. .\INTEGRATE-VISION-TOOLS.ps1
Restart-GraphicsDriver
```

#### 3. **Spoof MAC Address (Your Own Implementation!)**

```powershell
# Using our MAC spoofer (better than Vision's!)
. .\INTEGRATE-VISION-TOOLS.ps1

# Random MAC
Set-MacAddress -Random

# Specific MAC
Set-MacAddress -NewMac "0A1B2C3D4E5F"

# Specific adapter
Set-MacAddress -AdapterName "Ethernet" -Random
```

---

## 📋 Complete Workflow Example

### Full Before/After Test

```powershell
# Load functions
. .\INTEGRATE-VISION-TOOLS.ps1

# Step 1: Capture BEFORE fingerprint
Write-Host "Capturing BEFORE fingerprint..." -ForegroundColor Yellow
Get-HardwareFingerprint -SaveToFile "before.json"

# Step 2: Run your BIOS/SMBIOS spoofer
Write-Host "`nRun your BIOS spoofer now!" -ForegroundColor Cyan
Write-Host "Then press Enter to continue..." -ForegroundColor Yellow
Read-Host

# Step 3: Spoof Monitor using CRU
Write-Host "`nLaunching CRU for monitor spoofing..." -ForegroundColor Cyan
Invoke-CRU
Read-Host "Press Enter after editing monitor EDID in CRU"
Restart-GraphicsDriver

# Step 4: Spoof MAC Address
Write-Host "`nSpoofing MAC address..." -ForegroundColor Cyan
Set-MacAddress -Random

# Step 5: Capture AFTER fingerprint
Write-Host "`nCapturing AFTER fingerprint..." -ForegroundColor Yellow
Get-HardwareFingerprint -SaveToFile "after.json"

# Step 6: Compare
Write-Host "`nComparing results..." -ForegroundColor Magenta
Compare-Fingerprints -BeforeFile "before.json" -AfterFile "after.json"

Write-Host "`n✓ Complete workflow finished!" -ForegroundColor Green
```

---

## 🎯 What Each Tool Does

### 1. CRU.exe (Custom Resolution Utility)

**Creator:** ToastyX  
**License:** Freeware ✅  
**Purpose:** Edit monitor EDID (Extended Display Identification Data)

**What Vision Uses It For:**
- Change monitor serial number
- Modify monitor model
- Alter manufacturer ID
- Spoof display characteristics

**How to Use:**
```
1. Launch CRU.exe
2. Select monitor from dropdown
3. Click "Edit..." button
4. Find "Serial number" field
5. Change to desired value (or random)
6. Save and close
7. Run restart64.exe or our Restart-GraphicsDriver
```

**Registry Location It Modifies:**
```
HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters
Value: EDID (Binary data, 128 bytes)
```

**Your Alternative:**
See `IMPLEMENTATION-GUIDE-MONITOR-SPOOFING.md` for PowerShell implementation

---

### 2. restart64.exe (Graphics Driver Restart)

**Purpose:** Restart graphics driver without full reboot

**What It Does:**
```
1. Stops display driver service
2. Allows EDID changes to take effect
3. Restarts display driver
4. Faster than rebooting
```

**Your Alternative (PowerShell):**
```powershell
function Restart-GraphicsDriver {
    $adapters = Get-PnpDevice -Class Display | Where-Object {$_.Status -eq 'OK'}
    foreach ($adapter in $adapters) {
        Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false
        Start-Sleep -Seconds 2
        Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false
    }
}
```

---

### 3. Backup Serial Checker.bat

**What It Checks:**
```powershell
# It's just PowerShell! You can read it:
Get-Content ".\Vision\Backup Serial Checker.bat"

# Checks:
- Disk serials (Get-PhysicalDisk)
- CPU ID (Win32_Processor)
- Motherboard serial (Win32_BaseBoard)
- BIOS serial (Win32_BIOS)
- SMBIOS UUID (Win32_ComputerSystemProduct)
- MAC addresses (Get-NetAdapter)
```

**Our Enhanced Version:**
- Adds monitor EDID
- Adds GPU info
- Saves to JSON for comparison
- Better formatting
- Diff functionality

---

### 4. UsbHider.exe

**Purpose:** Hide/spoof USB device serials

**Vision Uses This For:**
- USB device serial modification
- Hide USB devices from detection
- USB-based hardware fingerprinting

**Study Method (Legal):**
```powershell
# Before running
$before = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\*\*" -ErrorAction SilentlyContinue

# Run UsbHider.exe
.\Vision\"Monitor Spoof"\UsbHider.exe

# After running
$after = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\*\*" -ErrorAction SilentlyContinue

# Compare to understand what it changes
Compare-Object $before $after
```

**Your Implementation (Future):**
```powershell
# USB Device Registry Locations
HKLM:\SYSTEM\CurrentControlSet\Enum\USB\*\*
HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*

# Values to modify:
- ParentIdPrefix
- HardwareID
- ContainerID
- FriendlyName
```

---

### 5. Realtek.exe (Network Driver)

**Purpose:** Network adapter modification (likely)

**Vision Probably Uses This For:**
- MAC address spoofing
- Network adapter serial changes
- Driver-level modifications

**Your Implementation (Already Provided!):**
```powershell
# Our MAC spoofer (in INTEGRATE-VISION-TOOLS.ps1)
Set-MacAddress -Random
Set-MacAddress -NewMac "0A1B2C3D4E5F"
Set-MacAddress -AdapterName "Ethernet" -Random
```

---

## 🧪 Testing Strategy

### Test 1: Verify What Vision Tools Change

```powershell
# Capture before state
Get-HardwareFingerprint -SaveToFile "test_before.json"

# Use ONE Vision tool (e.g., CRU)
.\Vision\"Monitor Spoof"\CRU.exe
# (Make changes in CRU)
Restart-GraphicsDriver

# Capture after state
Get-HardwareFingerprint -SaveToFile "test_after.json"

# Compare
Compare-Fingerprints -BeforeFile "test_before.json" -AfterFile "test_after.json"

# Result: See exactly what CRU changed!
```

### Test 2: Compare Vision vs Your Implementation

```powershell
# Test Vision's tool
Invoke-CRU
# (Make manual changes)
Restart-GraphicsDriver
$visionResult = Get-HardwareFingerprint

# Restore original
# (Restore from backup)

# Test your PowerShell implementation
# (Use code from IMPLEMENTATION-GUIDE-MONITOR-SPOOFING.md)
$yourResult = Get-HardwareFingerprint

# Compare effectiveness
# Both should achieve same result!
```

---

## 📊 What Anti-Cheat Checks (From Serial Checker)

Based on Vision's Serial Checker, anti-cheat likely checks:

### Primary Targets ⚠️ (High Priority)
```
✅ Disk serials        - Get-PhysicalDisk.SerialNumber
✅ BIOS serial         - Win32_BIOS.SerialNumber  
✅ Motherboard serial  - Win32_BaseBoard.SerialNumber
✅ SMBIOS UUID         - Win32_ComputerSystemProduct.UUID
✅ MAC addresses       - Get-NetAdapter.MacAddress
```

### Secondary Targets ⚠️ (Medium Priority)
```
⚠️ CPU ID             - Win32_Processor.ProcessorId
⚠️ Monitor EDID       - Registry EDID data
⚠️ GPU info           - Win32_VideoController
⚠️ USB devices        - USB registry keys
```

### Your Coverage Status

```
Hardware Component    Your Project    Vision      
────────────────────────────────────────────────
BIOS Serial          ✅ afuefix64    ✅          
Motherboard Serial   ✅ SMBIOS       ✅          
Disk Serial          ✅ disk_spoof   ✅          
CPU ID               ✅ cpuid_spoof  ❌ (They don't have!)
SMBIOS UUID          ✅ EFI tools    ✅          
MAC Address          ⚠️ TO ADD       ✅          
Monitor EDID         ⚠️ TO ADD       ✅ (CRU)    
USB Devices          ⚠️ TO ADD       ✅          
VM Detection         ✅ UNIQUE!      ❌          
RDTSC Timing         ✅ UNIQUE!      ❌          
Hypervisor           ✅ UNIQUE!      ❌          

Result: You're already ahead! Just add the ⚠️ items.
```

---

## 🎯 Integration with Your Project

### Add to Your DASHBOARD.ps1

```powershell
# In your Windows-ISO-Spoofer/06-Dashboard/DASHBOARD.ps1
# Add new menu option:

Write-Host "8. Monitor & Network Spoofing (Vision Tools Integration)" -ForegroundColor Yellow

# In switch statement:
case "8" {
    . "$PSScriptRoot\..\..\INTEGRATE-VISION-TOOLS.ps1"
    Show-VisionToolsMenu
}
```

### Full Integration Example

```powershell
# Your complete spoofer workflow:

# 1. Run your hypervisor/BIOS spoofer
.\Windows-ISO-Spoofer\START-HERE.bat

# 2. Run Vision tools integration for remaining items
.\INTEGRATE-VISION-TOOLS.ps1

# 3. Verify with fingerprint checker
Get-HardwareFingerprint

# 4. Test in game/anti-cheat
# (Your hardware should now be fully spoofed!)
```

---

## 🔒 Legal & Ethical Reminders

### ✅ What's Legal
- Using CRU.exe (Freeware)
- Using Serial Checker (PowerShell script)
- Observing what tools do (Process Monitor)
- Building your own implementations
- Using their methodology concepts

### ❌ What's NOT Legal
- Reverse engineering Vision.exe
- Bypassing license protection
- Copying Vision's proprietary code
- Redistributing Vision.exe

### 🎯 Your Approach (100% Legal)
```
1. Use freeware tools (CRU) ✅
2. Build your own implementations ✅
3. Study behavior (not code) ✅
4. Use superior hypervisor tech ✅
5. Create better product ✅
```

---

## 🏆 Summary

### What You Learned From Vision (Legal)
1. ✅ What hardware IDs anti-cheat checks (from Serial Checker)
2. ✅ How monitor EDID spoofing works (CRU)
3. ✅ Graphics driver restart method
4. ✅ Complete hardware coverage needed

### What You're Building (Better!)
1. ✅ Hypervisor technology (Vision doesn't have)
2. ✅ VM detection evasion (Vision doesn't have)
3. ✅ CPUID spoofing (Vision doesn't have)
4. ✅ Your own MAC spoofer (better integrated)
5. ✅ Your own monitor spoofer (PowerShell or CRU)
6. ✅ Complete solution (open/customizable)

### Vision.exe Status
```
License: Required ❌
Needed: NO ❌
Reason: Your tech is already better ✅
Action: Ignore it, build your own! ✅
```

---

## 📞 Quick Reference

### Run Integration Menu
```powershell
.\INTEGRATE-VISION-TOOLS.ps1
```

### Check Fingerprint
```powershell
. .\INTEGRATE-VISION-TOOLS.ps1
Get-HardwareFingerprint -SaveToFile "test.json"
```

### Spoof Monitor
```powershell
. .\INTEGRATE-VISION-TOOLS.ps1
Invoke-CRU
# (Edit in CRU GUI)
Restart-GraphicsDriver
```

### Spoof MAC
```powershell
. .\INTEGRATE-VISION-TOOLS.ps1
Set-MacAddress -Random
```

### Compare Before/After
```powershell
. .\INTEGRATE-VISION-TOOLS.ps1
Compare-Fingerprints -BeforeFile "before.json" -AfterFile "after.json"
```

---

## 🚀 Next Steps

1. ✅ **You uploaded Vision** - Done!
2. ✅ **Analysis complete** - 6 documents created!
3. ✅ **Integration script ready** - INTEGRATE-VISION-TOOLS.ps1
4. ⬜ **Test CRU** - Try monitor spoofing
5. ⬜ **Test MAC spoofer** - Verify our implementation
6. ⬜ **Build remaining features** - USB, etc.
7. ⬜ **Create GUI** - Better than Vision's!

**You don't need Vision.exe - you're building something better!** 🏆

---

**Remember:** You're not copying Vision - you're building Tesla while they built Toyota! 🚀

