# Monitor EDID Spoofing - Implementation Guide

## 🎯 Objective
Implement monitor EDID (Extended Display Identification Data) spoofing to match Vision's capabilities and complete our hardware fingerprint spoofing solution.

---

## 📋 What is EDID?

**EDID (Extended Display Identification Data)**
- Binary data structure stored in monitor's firmware
- Contains monitor identification information:
  - Manufacturer ID
  - Product Code
  - Serial Number
  - Manufacture Date
  - Supported resolutions and timings
  - Color characteristics
  - Display capabilities

**Why Anti-Cheat Checks It:**
- Unique hardware identifier
- Difficult to spoof without proper tools
- Part of complete hardware fingerprint
- Often overlooked by basic spoofers

**EDID Location:**
- Stored in monitor's EEPROM
- Read by GPU via DDC/CI protocol
- Cached in Windows registry
- Can be overridden with custom drivers

---

## 🔍 How Vision Does It

**Method: Custom Resolution Utility (CRU)**
```
1. User downloads CRU tool
2. CRU extracts current EDID from registry
3. User edits serial number and model in hex
4. CRU creates registry override
5. Graphics driver restart applies changes
6. Windows reads modified EDID instead of real one
```

**CRU Details:**
- Created by ToastyX
- Free tool for Windows
- Modifies registry keys: `HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY`
- Works with all GPU vendors (NVIDIA, AMD, Intel)
- Non-permanent (survives reboot but can be undone)

---

## 🛠️ Implementation Approach

### Option 1: CRU Integration (Easiest - 1-2 Days)

**Pros:**
- Use existing, tested tool
- Quick implementation
- Community-proven
- No need to understand EDID format deeply

**Cons:**
- External dependency
- Less control over process
- May be detected as known tool

**Implementation:**
```powershell
# Wrapper script approach
1. Download/bundle CRU with your spoofer
2. Create PowerShell wrapper to:
   - Extract current EDID
   - Modify serial/model programmatically
   - Apply changes via CRU
   - Restart graphics driver
3. Add to main dashboard
```

### Option 2: Custom EDID Driver (Medium - 1 Week)

**Pros:**
- Full control over EDID data
- Integrated solution
- Can randomize values automatically
- Professional appearance

**Cons:**
- More complex development
- Need to understand EDID structure
- Requires testing across GPUs

**Implementation:**
```c
// Custom display filter driver
1. Create kernel-mode driver
2. Hook IRP_MJ_DEVICE_CONTROL for display
3. Intercept IOCTL_VIDEO_QUERY_DISPLAY_EDID
4. Modify EDID binary data in response
5. Calculate and fix checksum
6. Return modified EDID to caller
```

### Option 3: Registry-Only Method (Fastest - Few Hours)

**Pros:**
- No external tools needed
- Pure registry modification
- Fast implementation
- Easy to automate

**Cons:**
- Requires graphics driver restart
- May not work on all systems
- Limited to registry-cached EDID

**Implementation:**
```powershell
# Direct registry manipulation
1. Locate EDID in registry
2. Parse EDID binary structure
3. Modify serial number bytes
4. Update checksum
5. Write back to registry
6. Restart graphics driver
```

---

## 🎓 EDID Structure (For Custom Implementation)

### EDID 1.3/1.4 Format (128 bytes)

```
Byte Range | Content                  | Spoofable?
-----------|--------------------------|------------
0-7        | Header (fixed)           | ❌ No
8-9        | Manufacturer ID          | ✅ Yes
10-11      | Product Code             | ✅ Yes
12-15      | Serial Number            | ✅ Yes (Primary Target)
16         | Week of Manufacture      | ✅ Yes
17         | Year of Manufacture      | ✅ Yes
18-19      | EDID Version/Revision    | ❌ No
20-24      | Basic Display Parameters | ⚠️ Careful
25-34      | Color Characteristics    | ⚠️ Careful
35-37      | Established Timings      | ❌ No
38-53      | Standard Timings         | ❌ No
54-125     | Detailed Timing Blocks   | ❌ No
126        | Extension Flag           | ❌ No
127        | Checksum                 | ✅ Must Recalculate
```

### Key Fields to Modify

**1. Serial Number (Bytes 12-15)**
```
Original: 0x12 0x34 0x56 0x78
Modified: 0xAB 0xCD 0xEF 0x01  (Random values)

Important: This is the PRIMARY target for spoofing
```

**2. Manufacturer ID (Bytes 8-9)**
```
Format: 3 letters compressed into 2 bytes
Example: "SAM" (Samsung) = 0x4C 0x2D

Can change to different manufacturer or randomize
```

**3. Product Code (Bytes 10-11)**
```
16-bit product/model identifier
Example: 0x0A 0xBC

Can randomize to appear as different model
```

**4. Manufacture Date (Bytes 16-17)**
```
Byte 16: Week of manufacture (1-53)
Byte 17: Year - 1990

Example: Week 20 of 2022 = 0x14 0x20

Can randomize within reasonable range
```

### Checksum Calculation (Byte 127)

```c
// EDID checksum = (256 - sum of bytes 0-126) mod 256
uint8_t calculate_edid_checksum(uint8_t* edid) {
    uint32_t sum = 0;
    for (int i = 0; i < 127; i++) {
        sum += edid[i];
    }
    return (256 - (sum % 256)) % 256;
}
```

**CRITICAL:** Always recalculate checksum after modifying EDID, or Windows will reject it!

---

## 💻 Recommended Implementation (Option 3 + CRU Fallback)

### Phase 1: Registry Method (Core)

```powershell
# File: Spoof-MonitorEDID.ps1

function Get-MonitorEDID {
    <#
    .SYNOPSIS
    Retrieves current monitor EDID from registry
    #>
    
    $displays = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters" -Name EDID -ErrorAction SilentlyContinue
    
    return $displays | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.PSPath
            EDID = $_.EDID
            Original = $_.EDID
        }
    }
}

function Parse-EDID {
    param([byte[]]$edid)
    
    return [PSCustomObject]@{
        Header          = $edid[0..7]
        ManufacturerID  = $edid[8..9]
        ProductCode     = $edid[10..11]
        SerialNumber    = $edid[12..15]
        WeekOfManufacture = $edid[16]
        YearOfManufacture = $edid[17] + 1990
        Version         = $edid[18]
        Revision        = $edid[19]
        Checksum        = $edid[127]
    }
}

function Set-EDIDSerialNumber {
    param(
        [byte[]]$edid,
        [uint32]$newSerial
    )
    
    # Convert serial to bytes (little-endian)
    $edid[12] = $newSerial -band 0xFF
    $edid[13] = ($newSerial -shr 8) -band 0xFF
    $edid[14] = ($newSerial -shr 16) -band 0xFF
    $edid[15] = ($newSerial -shr 24) -band 0xFF
    
    # Recalculate checksum
    $sum = 0
    for ($i = 0; $i -lt 127; $i++) {
        $sum += $edid[$i]
    }
    $edid[127] = (256 - ($sum % 256)) % 256
    
    return $edid
}

function Set-MonitorEDID {
    param(
        [Parameter(Mandatory)]
        [string]$DisplayPath,
        
        [Parameter(Mandatory)]
        [byte[]]$NewEDID
    )
    
    # Backup original EDID
    $backupPath = "$env:TEMP\EDID_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').bin"
    $original = (Get-ItemProperty $DisplayPath -Name EDID).EDID
    [System.IO.File]::WriteAllBytes($backupPath, $original)
    Write-Host "✓ Original EDID backed up to: $backupPath"
    
    # Set new EDID
    Set-ItemProperty -Path $DisplayPath -Name EDID -Value $NewEDID -Type Binary
    Write-Host "✓ EDID modified in registry"
}

function Restart-GraphicsDriver {
    <#
    .SYNOPSIS
    Restarts graphics driver to apply EDID changes
    #>
    
    Write-Host "Restarting graphics driver..."
    
    # Method 1: Using devcon (if available)
    $devcon = "$PSScriptRoot\tools\devcon.exe"
    if (Test-Path $devcon) {
        & $devcon restart "DISPLAY*"
        return
    }
    
    # Method 2: Disable/Enable display adapter
    $adapters = Get-PnpDevice -Class Display | Where-Object {$_.Status -eq 'OK'}
    foreach ($adapter in $adapters) {
        Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false
        Start-Sleep -Seconds 2
        Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false
    }
    
    Write-Host "✓ Graphics driver restarted"
}

function Spoof-MonitorEDID {
    <#
    .SYNOPSIS
    Main function to spoof monitor EDID
    #>
    
    param(
        [switch]$Random,
        [uint32]$SerialNumber
    )
    
    Write-Host "`n=== Monitor EDID Spoofer ===" -ForegroundColor Cyan
    
    # Get all monitors
    $monitors = Get-MonitorEDID
    
    if ($monitors.Count -eq 0) {
        Write-Host "✗ No monitors found in registry" -ForegroundColor Red
        return
    }
    
    Write-Host "Found $($monitors.Count) monitor(s)"
    
    foreach ($monitor in $monitors) {
        Write-Host "`nProcessing monitor: $($monitor.Path)" -ForegroundColor Yellow
        
        $edid = $monitor.EDID
        $parsed = Parse-EDID $edid
        
        # Display current info
        Write-Host "  Current Serial: 0x$([BitConverter]::ToString($parsed.SerialNumber) -replace '-','')"
        Write-Host "  Manufacturer: 0x$([BitConverter]::ToString($parsed.ManufacturerID) -replace '-','')"
        Write-Host "  Product: 0x$([BitConverter]::ToString($parsed.ProductCode) -replace '-','')"
        
        # Generate new serial
        if ($Random) {
            $newSerial = Get-Random -Minimum 0x10000000 -Maximum 0xFFFFFFFF
        } elseif ($SerialNumber) {
            $newSerial = $SerialNumber
        } else {
            Write-Host "  Skipping (no serial specified)"
            continue
        }
        
        # Modify EDID
        $newEDID = Set-EDIDSerialNumber $edid $newSerial
        
        Write-Host "  New Serial: 0x$($newSerial.ToString('X8'))" -ForegroundColor Green
        
        # Apply changes
        Set-MonitorEDID -DisplayPath $monitor.Path -NewEDID $newEDID
    }
    
    # Restart graphics driver
    Restart-GraphicsDriver
    
    Write-Host "`n✓ Monitor EDID spoofing complete!" -ForegroundColor Green
    Write-Host "  Backups saved to: $env:TEMP\EDID_Backup_*.bin"
}

# Export functions
Export-ModuleMember -Function Spoof-MonitorEDID, Get-MonitorEDID, Restart-GraphicsDriver
```

### Usage Examples

```powershell
# Spoof with random serial
.\Spoof-MonitorEDID.ps1 -Random

# Spoof with specific serial
.\Spoof-MonitorEDID.ps1 -SerialNumber 0x12345678

# Restore from backup
$backup = [System.IO.File]::ReadAllBytes("C:\Temp\EDID_Backup_20251115.bin")
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\..." -Name EDID -Value $backup
Restart-GraphicsDriver
```

---

## 🧪 Testing & Verification

### Test 1: Verify EDID Change

```powershell
# Read EDID from registry
$edid = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters" -Name EDID).EDID

# Parse serial number (bytes 12-15)
$serial = [BitConverter]::ToUInt32($edid, 12)
Write-Host "Current Monitor Serial: 0x$($serial.ToString('X8'))"
```

### Test 2: Windows Display Info

```powershell
# Check via WMI
Get-WmiObject WmiMonitorID -Namespace root\wmi | Select-Object ManufacturerName, ProductCodeID, SerialNumberID
```

### Test 3: Third-Party Tools

- **Monitor Asset Manager** - Shows EDID data
- **AIDA64** - Hardware detection tool
- **HWiNFO** - Detailed hardware info
- **Custom Resolution Utility (CRU)** - EDID editor/viewer

### Test 4: Anti-Cheat Simulation

```powershell
# Simulate hardware fingerprint check
function Get-HardwareFingerprint {
    $cpu = (Get-WmiObject Win32_Processor).ProcessorId
    $bios = (Get-WmiObject Win32_BIOS).SerialNumber
    $board = (Get-WmiObject Win32_BaseBoard).SerialNumber
    $disk = (Get-PhysicalDisk | Select-Object -First 1).SerialNumber
    $monitor = [BitConverter]::ToUInt32((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters" -Name EDID).EDID, 12)
    
    return @{
        CPU = $cpu
        BIOS = $bios
        Motherboard = $board
        Disk = $disk
        Monitor = "0x$($monitor.ToString('X8'))"
    }
}

# Before spoof
$before = Get-HardwareFingerprint
Write-Host "BEFORE:" -ForegroundColor Yellow
$before | Format-Table

# Run spoofer
Spoof-MonitorEDID -Random

# After spoof
$after = Get-HardwareFingerprint
Write-Host "`nAFTER:" -ForegroundColor Green
$after | Format-Table

# Verify monitor serial changed
if ($before.Monitor -ne $after.Monitor) {
    Write-Host "✓ Monitor EDID successfully spoofed!" -ForegroundColor Green
} else {
    Write-Host "✗ Monitor EDID unchanged" -ForegroundColor Red
}
```

---

## 🔒 Safety & Backup

### Automatic Backup System

```powershell
# Add to Spoof-MonitorEDID function
$backupDir = "$env:ProgramData\HWIDSpoofer\EDID_Backups"
if (!(Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
foreach ($monitor in $monitors) {
    $monitorHash = ($monitor.Path | Get-FileHash -Algorithm MD5).Hash.Substring(0,8)
    $backupFile = "$backupDir\EDID_${monitorHash}_${timestamp}.bin"
    [System.IO.File]::WriteAllBytes($backupFile, $monitor.Original)
}
```

### Emergency Restore

```powershell
# File: Restore-MonitorEDID.ps1
function Restore-MonitorEDID {
    param([string]$BackupFile)
    
    if (!(Test-Path $BackupFile)) {
        Write-Host "✗ Backup file not found: $BackupFile" -ForegroundColor Red
        return
    }
    
    $backupEDID = [System.IO.File]::ReadAllBytes($BackupFile)
    $monitors = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters" -Name EDID
    
    foreach ($monitor in $monitors) {
        Set-ItemProperty -Path $monitor.PSPath -Name EDID -Value $backupEDID -Type Binary
        Write-Host "✓ Restored EDID from backup"
    }
    
    Restart-GraphicsDriver
}
```

---

## 📊 Integration with Main Dashboard

### Add to DASHBOARD.ps1

```powershell
# Add menu option
Write-Host "7. Spoof Monitor EDID" -ForegroundColor Yellow

# Add case in switch
case "7" {
    Write-Host "`n=== Monitor EDID Spoofing ===" -ForegroundColor Cyan
    Write-Host "1. Spoof with random serial"
    Write-Host "2. Spoof with custom serial"
    Write-Host "3. Restore from backup"
    Write-Host "4. View current EDID"
    
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" {
            .\Spoof-MonitorEDID.ps1 -Random
        }
        "2" {
            $serial = Read-Host "Enter serial number (hex, e.g., 0x12345678)"
            .\Spoof-MonitorEDID.ps1 -SerialNumber ([Convert]::ToUInt32($serial, 16))
        }
        "3" {
            $backups = Get-ChildItem "$env:ProgramData\HWIDSpoofer\EDID_Backups" -Filter "*.bin"
            $backups | ForEach-Object { Write-Host "$($backups.IndexOf($_)). $($_.Name)" }
            $idx = Read-Host "Select backup"
            Restore-MonitorEDID -BackupFile $backups[$idx].FullName
        }
        "4" {
            $monitors = Get-MonitorEDID
            foreach ($monitor in $monitors) {
                $parsed = Parse-EDID $monitor.EDID
                Write-Host "`nMonitor: $($monitor.Path)" -ForegroundColor Yellow
                Write-Host "  Serial: 0x$([BitConverter]::ToUInt32($parsed.SerialNumber, 0).ToString('X8'))"
                Write-Host "  Manufacturer: 0x$([BitConverter]::ToString($parsed.ManufacturerID) -replace '-','')"
                Write-Host "  Year: $($parsed.YearOfManufacture)"
            }
        }
    }
}
```

---

## 🎯 Testing Checklist

- [ ] Test on NVIDIA GPU
- [ ] Test on AMD GPU
- [ ] Test on Intel integrated graphics
- [ ] Test with single monitor
- [ ] Test with multiple monitors
- [ ] Test on Windows 10
- [ ] Test on Windows 11
- [ ] Verify backup/restore functionality
- [ ] Test graphics driver restart
- [ ] Verify checksum calculation
- [ ] Test with hardware fingerprint tool
- [ ] Test persistence across reboot
- [ ] Test emergency restore

---

## 📝 Documentation Additions

### User Guide Section

```markdown
## Monitor EDID Spoofing

### What it does
Changes your monitor's serial number and identification to prevent hardware fingerprinting.

### When to use
- After spoofing BIOS/motherboard serials
- When using multiple monitors (each needs spoofing)
- Before running anti-cheat software

### How to use
1. Run Dashboard → Option 7 (Monitor EDID)
2. Choose "Spoof with random serial"
3. Wait for graphics driver restart
4. Verify with hardware checker tool

### Restore Original
1. Run Dashboard → Option 7 → Restore from backup
2. Select most recent backup
3. Graphics driver will restart automatically
```

---

## 🚀 Next Steps

1. **Implement basic PowerShell version** (1-2 days)
2. **Test on multiple GPU vendors** (1 day)
3. **Add to main dashboard** (few hours)
4. **Create user documentation** (1 day)
5. **Consider C++ driver version** for advanced users (future)

---

## 📚 Resources

- [EDID Standard (VESA)](https://vesa.org/vesa-standards/)
- [Custom Resolution Utility (CRU)](https://www.monitortests.com/forum/Thread-Custom-Resolution-Utility-CRU)
- [Windows Display Driver Model](https://docs.microsoft.com/en-us/windows-hardware/drivers/display/)
- [EDID Parser Tools](https://github.com/akatrevorjay/edid-generator)

---

**Estimated Total Implementation Time:** 2-3 days for full registry-based implementation

**Result:** Matching Vision's monitor spoofing capabilities with integrated backup/restore system! ✅

