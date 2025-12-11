# Step 5: System Installer Script
# Installs the signed spoofer to the system ESP

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "System Installation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SpooferDir = Join-Path $ProjectRoot "01-EFI-Spoofer"
$BootloaderDir = Join-Path $ProjectRoot "04-USB-Creator\bootloader"

$SignedSpoofer = Join-Path $SpooferDir "spoofer-signed.efi"
$ShimFile = Join-Path $BootloaderDir "shimx64.efi"

# Prerequisites check
Write-Host "[1/10] Checking prerequisites..." -ForegroundColor Yellow

$AllGood = $true

if (-not (Test-Path $SignedSpoofer)) {
    Write-Host "  ERROR: Signed spoofer not found!" -ForegroundColor Red
    Write-Host "  Please run sign-spoofer.ps1 first" -ForegroundColor Yellow
    $AllGood = $false
}

if (-not (Test-Path $ShimFile)) {
    Write-Host "  ERROR: Shim bootloader not found!" -ForegroundColor Red
    $AllGood = $false
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  ERROR: This script must run as Administrator!" -ForegroundColor Red
    $AllGood = $false
}

if (-not $AllGood) {
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  Prerequisites OK" -ForegroundColor Green

# Important warnings
Write-Host "`n[2/10] Pre-installation warnings..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  IMPORTANT RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "  1. Have you tested the USB boot successfully? (Recommended)" -ForegroundColor White
Write-Host "  2. Have you completed MOK enrollment? (Required)" -ForegroundColor White
Write-Host "  3. Did Windows boot correctly after USB test? (Recommended)" -ForegroundColor White
Write-Host ""

$response = Read-Host "  Have you completed USB testing? (yes/no)"
if ($response -ne "yes") {
    Write-Host ""
    Write-Host "  It is STRONGLY recommended to test USB boot first!" -ForegroundColor Yellow
    Write-Host "  This ensures MOK enrollment works and spoofer is compatible." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "  Continue anyway? (yes/no)"
    if ($continue -ne "yes") {
        Write-Host "  Installation cancelled. Test USB boot first." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

# Mount ESP
Write-Host "`n[3/10] Mounting EFI System Partition..." -ForegroundColor Yellow

$EspVolume = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1

if (-not $EspVolume) {
    Write-Host "  ERROR: Could not find EFI System Partition!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$EspDriveLetter = "S"
try {
    # Unmount if already mounted
    $existing = Get-Volume -DriveLetter $EspDriveLetter -ErrorAction SilentlyContinue
    if ($existing) {
        Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction SilentlyContinue
    }
    
    # Mount ESP
    Add-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
    Write-Host "  Mounted ESP as ${EspDriveLetter}:\" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to mount ESP" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$EspRoot = "${EspDriveLetter}:\"

# Backup existing files
Write-Host "`n[4/10] Creating backups..." -ForegroundColor Yellow

$BackupDate = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir = Join-Path $EspRoot "EFI\Backups\$BackupDate"

try {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "  Backup directory: $BackupDir" -ForegroundColor Gray
    
    # Backup Windows Boot Manager
    $WindowsBootMgr = Join-Path $EspRoot "EFI\Microsoft\Boot\bootmgfw.efi"
    if (Test-Path $WindowsBootMgr) {
        $BackupBootMgr = Join-Path $BackupDir "bootmgfw.efi"
        Copy-Item $WindowsBootMgr $BackupBootMgr -Force
        Write-Host "  Backed up: Windows Boot Manager" -ForegroundColor Green
    }
    
    # Backup existing boot entries
    $BcdOutput = bcdedit /enum all | Out-String
    $BcdBackup = Join-Path $BackupDir "bcdedit-backup.txt"
    Set-Content -Path $BcdBackup -Value $BcdOutput
    Write-Host "  Backed up: Boot configuration" -ForegroundColor Green
    
} catch {
    Write-Host "  WARNING: Backup failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Continuing anyway..." -ForegroundColor Gray
}

# Create spoofer directory
Write-Host "`n[5/10] Creating spoofer directory on ESP..." -ForegroundColor Yellow

$EspSpooferDir = Join-Path $EspRoot "EFI\Spoofer"

try {
    if (-not (Test-Path $EspSpooferDir)) {
        New-Item -ItemType Directory -Path $EspSpooferDir -Force | Out-Null
        Write-Host "  Created: EFI\Spoofer\" -ForegroundColor Green
    } else {
        Write-Host "  Directory exists: EFI\Spoofer\" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ERROR: Failed to create directory" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    
    # Unmount ESP
    Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Copy files to ESP
Write-Host "`n[6/10] Copying files to ESP..." -ForegroundColor Yellow

try {
    # Copy signed spoofer
    $EspSpooferEfi = Join-Path $EspSpooferDir "spoofer-signed.efi"
    Copy-Item $SignedSpoofer $EspSpooferEfi -Force
    Write-Host "  Copied: spoofer-signed.efi" -ForegroundColor Green
    
    # Copy shim
    $EspShim = Join-Path $EspSpooferDir "shimx64.efi"
    Copy-Item $ShimFile $EspShim -Force
    Write-Host "  Copied: shimx64.efi" -ForegroundColor Green
    
    # Create grubx64.efi (chainloader - shim looks for this)
    $EspGrub = Join-Path $EspSpooferDir "grubx64.efi"
    Copy-Item $SignedSpoofer $EspGrub -Force
    Write-Host "  Copied: grubx64.efi (chainloader)" -ForegroundColor Green
    
} catch {
    Write-Host "  ERROR: Failed to copy files" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    
    # Unmount ESP
    Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Create boot entry
Write-Host "`n[7/10] Creating boot entry..." -ForegroundColor Yellow

$BootEntryName = "L2signed"

# Check if entry already exists
$ExistingEntry = bcdedit /enum firmware | Select-String -Pattern $BootEntryName
if ($ExistingEntry) {
    Write-Host "  Boot entry '$BootEntryName' already exists" -ForegroundColor Yellow
    $response = Read-Host "  Delete and recreate? (yes/no)"
    if ($response -eq "yes") {
        # Extract GUID from existing entry
        $guidMatch = $ExistingEntry -match '\{([^}]+)\}'
        if ($guidMatch) {
            $existingGuid = "{$($matches[1])}"
            bcdedit /delete $existingGuid /f | Out-Null
            Write-Host "  Deleted existing entry" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Keeping existing entry" -ForegroundColor Gray
        Write-Host "  Skipping boot entry creation" -ForegroundColor Yellow
        
        # Unmount ESP
        Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction SilentlyContinue
        Write-Host "`n[8/10] ESP unmounted" -ForegroundColor Yellow
        
        Write-Host "`n=================================" -ForegroundColor Cyan
        Write-Host "Installation completed (using existing boot entry)" -ForegroundColor Yellow
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

try {
    # Create new boot entry
    $createOutput = bcdedit /create /d $BootEntryName /application bootmgr 2>&1
    
    # Extract GUID from output
    if ($createOutput -match '\{([^}]+)\}') {
        $newGuid = "{$($matches[1])}"
        Write-Host "  Created boot entry: $newGuid" -ForegroundColor Green
        
        # Set device
        bcdedit /set $newGuid device partition=$EspRoot | Out-Null
        
        # Set path to shim
        bcdedit /set $newGuid path "\EFI\Spoofer\shimx64.efi" | Out-Null
        
        # Set description
        bcdedit /set $newGuid description $BootEntryName | Out-Null
        
        Write-Host "  Configured boot entry" -ForegroundColor Green
        
        # Add to boot order
        $fwBootMgr = "{fwbootmgr}"
        bcdedit /displayorder $newGuid /addlast | Out-Null
        
        Write-Host "  Added to boot order" -ForegroundColor Green
        
    } else {
        throw "Failed to extract GUID from bcdedit output"
    }
    
} catch {
    Write-Host "  ERROR: Failed to create boot entry" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  You can manually create a boot entry in your BIOS/UEFI:" -ForegroundColor Yellow
    Write-Host "  - Boot file: \EFI\Spoofer\shimx64.efi" -ForegroundColor Yellow
    Write-Host "  - Name: $BootEntryName" -ForegroundColor Yellow
    Write-Host ""
}

# Verification
Write-Host "`n[8/10] Verifying installation..." -ForegroundColor Yellow

$FilesToCheck = @(
    "EFI\Spoofer\shimx64.efi",
    "EFI\Spoofer\spoofer-signed.efi",
    "EFI\Spoofer\grubx64.efi"
)

$AllGood = $true
foreach ($file in $FilesToCheck) {
    $fullPath = Join-Path $EspRoot $file
    if (Test-Path $fullPath) {
        $size = (Get-Item $fullPath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "  OK: $file ($sizeKB KB)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $file" -ForegroundColor Red
        $AllGood = $false
    }
}

# Check boot entry
$bootEntries = bcdedit /enum firmware | Out-String
if ($bootEntries -match $BootEntryName) {
    Write-Host "  OK: Boot entry '$BootEntryName' exists" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Boot entry not found in bcdedit" -ForegroundColor Yellow
}

# Unmount ESP
Write-Host "`n[9/10] Unmounting ESP..." -ForegroundColor Yellow
try {
    Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
    Write-Host "  ESP unmounted successfully" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Failed to unmount ESP" -ForegroundColor Yellow
    Write-Host "  You may need to restart to unmount it" -ForegroundColor Yellow
}

# Final summary
Write-Host "`n[10/10] Installation summary..." -ForegroundColor Yellow

Write-Host "`n=================================" -ForegroundColor Cyan
if ($AllGood) {
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files installed to ESP:\EFI\Spoofer\" -ForegroundColor White
    Write-Host "Boot entry created: $BootEntryName" -ForegroundColor White
    Write-Host "Backup created: EFI\Backups\$BackupDate\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "1. Restart your computer" -ForegroundColor White
    Write-Host "2. At boot menu, select '$BootEntryName'" -ForegroundColor White
    Write-Host "3. Spoofer will run automatically" -ForegroundColor White
    Write-Host "4. Windows will boot normally" -ForegroundColor White
    Write-Host "5. Verify HWIDs are spoofed" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Yellow
    Write-Host "- If this is first system boot (not USB), complete MOK enrollment" -ForegroundColor Yellow
    Write-Host "- If you already enrolled MOK via USB, it will work automatically" -ForegroundColor Yellow
    Write-Host "- If boot fails, select 'Windows Boot Manager' instead" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To uninstall, run: uninstall.ps1" -ForegroundColor Gray
} else {
    Write-Host "Installation completed with warnings!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please check the warnings above." -ForegroundColor Yellow
    Write-Host "You may need to manually configure boot entry in BIOS." -ForegroundColor Yellow
}
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


