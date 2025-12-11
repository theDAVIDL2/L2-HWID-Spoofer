# Step 5: Installation Verification Script
# Checks if the spoofer is correctly installed on the system

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Installation Status Check" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  WARNING: Running without Administrator rights" -ForegroundColor Yellow
    Write-Host "  Some checks may fail" -ForegroundColor Yellow
    Write-Host ""
}

# Check 1: Project files
Write-Host "[1/6] Checking project files..." -ForegroundColor Yellow

$ProjectFiles = @{
    "Certificate" = (Join-Path $ProjectRoot "02-Certificates\my-key.crt")
    "Private Key" = (Join-Path $ProjectRoot "02-Certificates\my-key.key")
    "Signed Spoofer" = (Join-Path $ProjectRoot "01-EFI-Spoofer\spoofer-signed.efi")
    "Shim Bootloader" = (Join-Path $ProjectRoot "04-USB-Creator\bootloader\shimx64.efi")
}

foreach ($item in $ProjectFiles.GetEnumerator()) {
    if (Test-Path $item.Value) {
        Write-Host "  OK: $($item.Key)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $($item.Key)" -ForegroundColor Red
    }
}

# Check 2: ESP mount and files
Write-Host "`n[2/6] Checking ESP installation..." -ForegroundColor Yellow

if ($isAdmin) {
    $EspVolume = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1
    
    if ($EspVolume) {
        Write-Host "  ESP found: Disk $($EspVolume.DiskNumber), Partition $($EspVolume.PartitionNumber)" -ForegroundColor Green
        
        # Try to mount ESP
        $EspDriveLetter = "S"
        try {
            # Unmount if already mounted
            $existing = Get-Volume -DriveLetter $EspDriveLetter -ErrorAction SilentlyContinue
            if ($existing) {
                Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction SilentlyContinue
            }
            
            # Mount ESP
            Add-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
            $EspRoot = "${EspDriveLetter}:\"
            
            Write-Host "  Mounted ESP as ${EspDriveLetter}:\" -ForegroundColor Green
            
            # Check for spoofer files
            $EspFiles = @(
                "EFI\Spoofer\shimx64.efi",
                "EFI\Spoofer\spoofer-signed.efi",
                "EFI\Spoofer\grubx64.efi"
            )
            
            $EspInstalled = $true
            foreach ($file in $EspFiles) {
                $fullPath = Join-Path $EspRoot $file
                if (Test-Path $fullPath) {
                    $size = (Get-Item $fullPath).Length
                    $sizeKB = [math]::Round($size / 1KB, 2)
                    Write-Host "  OK: $file ($sizeKB KB)" -ForegroundColor Green
                } else {
                    Write-Host "  MISSING: $file" -ForegroundColor Red
                    $EspInstalled = $false
                }
            }
            
            # Unmount ESP
            Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction SilentlyContinue
            
            if ($EspInstalled) {
                Write-Host "  Status: INSTALLED" -ForegroundColor Green
            } else {
                Write-Host "  Status: NOT INSTALLED" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "  ERROR: Failed to mount ESP" -ForegroundColor Red
            Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ERROR: ESP not found" -ForegroundColor Red
    }
} else {
    Write-Host "  SKIPPED: Requires Administrator rights" -ForegroundColor Yellow
}

# Check 3: Boot entry
Write-Host "`n[3/6] Checking boot entry..." -ForegroundColor Yellow

$BootEntryName = "L2signed"

try {
    $bootEntries = bcdedit /enum firmware 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Cannot read boot configuration" -ForegroundColor Red
        Write-Host "  Requires Administrator rights" -ForegroundColor Yellow
    } elseif ($bootEntries -match $BootEntryName) {
        Write-Host "  OK: Boot entry '$BootEntryName' found" -ForegroundColor Green
        
        # Extract details
        $lines = $bootEntries -split "`n"
        $inL2Entry = $false
        $guid = ""
        
        foreach ($line in $lines) {
            if ($line -match "identifier\s+(\{[^}]+\})") {
                $guid = $matches[1]
                $inL2Entry = $false
            }
            if ($line -match "description\s+$BootEntryName") {
                $inL2Entry = $true
                Write-Host "    GUID: $guid" -ForegroundColor Gray
            }
            if ($inL2Entry -and $line -match "path\s+(.+)") {
                Write-Host "    Path: $($matches[1].Trim())" -ForegroundColor Gray
            }
            if ($inL2Entry -and $line -match "device\s+(.+)") {
                Write-Host "    Device: $($matches[1].Trim())" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  NOT FOUND: Boot entry '$BootEntryName' does not exist" -ForegroundColor Red
    }
} catch {
    Write-Host "  ERROR: Failed to check boot entries" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}

# Check 4: Secure Boot status
Write-Host "`n[4/6] Checking Secure Boot status..." -ForegroundColor Yellow

try {
    $secureBootStatus = Confirm-SecureBootUEFI
    if ($secureBootStatus) {
        Write-Host "  Secure Boot: ENABLED" -ForegroundColor Green
        Write-Host "  This is correct for spoofer to work" -ForegroundColor Gray
    } else {
        Write-Host "  Secure Boot: DISABLED" -ForegroundColor Yellow
        Write-Host "  WARNING: Spoofer requires Secure Boot enabled" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Cannot determine Secure Boot status" -ForegroundColor Yellow
    Write-Host "  System may not support Secure Boot" -ForegroundColor Gray
}

# Check 5: MOK enrollment status
Write-Host "`n[5/6] Checking MOK enrollment..." -ForegroundColor Yellow

Write-Host "  Cannot automatically verify MOK enrollment from Windows" -ForegroundColor Gray
Write-Host "  MOK enrollment is verified at boot time by shim" -ForegroundColor Gray
Write-Host ""
Write-Host "  To verify MOK enrollment:" -ForegroundColor White
Write-Host "    1. Restart computer" -ForegroundColor Gray
Write-Host "    2. Boot from USB or system '$BootEntryName' entry" -ForegroundColor Gray
Write-Host "    3. If MOK screen appears, enrollment is needed" -ForegroundColor Gray
Write-Host "    4. If Windows boots directly, enrollment is complete" -ForegroundColor Gray

# Check 6: System info
Write-Host "`n[6/6] System information..." -ForegroundColor Yellow

$computerInfo = Get-ComputerInfo -Property @('CsManufacturer', 'CsModel', 'BiosFirmwareType', 'BiosVersion')

Write-Host "  Manufacturer: $($computerInfo.CsManufacturer)" -ForegroundColor Gray
Write-Host "  Model: $($computerInfo.CsModel)" -ForegroundColor Gray
Write-Host "  Firmware Type: $($computerInfo.BiosFirmwareType)" -ForegroundColor Gray
Write-Host "  BIOS Version: $($computerInfo.BiosVersion)" -ForegroundColor Gray

if ($computerInfo.BiosFirmwareType -ne "Uefi") {
    Write-Host "  WARNING: System is not UEFI! Spoofer requires UEFI." -ForegroundColor Red
}

# Summary
Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "Installation Status Summary" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Determine overall status
$projectOK = (Test-Path (Join-Path $ProjectRoot "01-EFI-Spoofer\spoofer-signed.efi"))
$bootEntryExists = (bcdedit /enum firmware 2>&1 | Out-String) -match $BootEntryName

if ($projectOK -and $bootEntryExists) {
    Write-Host "Overall Status: INSTALLED" -ForegroundColor Green
    Write-Host ""
    Write-Host "The spoofer appears to be correctly installed." -ForegroundColor White
    Write-Host "Restart and select '$BootEntryName' to use it." -ForegroundColor White
} elseif ($projectOK -and -not $bootEntryExists) {
    Write-Host "Overall Status: PARTIALLY INSTALLED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Spoofer files exist but boot entry is missing." -ForegroundColor Yellow
    Write-Host "Run install-to-system.ps1 to complete installation." -ForegroundColor Yellow
} else {
    Write-Host "Overall Status: NOT INSTALLED" -ForegroundColor Red
    Write-Host ""
    Write-Host "The spoofer is not installed on this system." -ForegroundColor White
    Write-Host "Follow the workflow from Step 1 to install." -ForegroundColor White
}

Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


