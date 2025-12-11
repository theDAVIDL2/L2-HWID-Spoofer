# Step 5: Uninstaller Script
# Removes the spoofer from the system and cleans up

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Spoofer Uninstallation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  ERROR: This script must run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "WARNING: This will completely remove the spoofer from your system!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Uninstall cancelled." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Mount ESP
Write-Host "`n[1/5] Mounting EFI System Partition..." -ForegroundColor Yellow

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

# Remove spoofer directory
Write-Host "`n[2/5] Removing spoofer files from ESP..." -ForegroundColor Yellow

$EspSpooferDir = Join-Path $EspRoot "EFI\Spoofer"

if (Test-Path $EspSpooferDir) {
    try {
        # List files before deletion
        $files = Get-ChildItem -Path $EspSpooferDir -Recurse -File
        foreach ($file in $files) {
            Write-Host "  Deleting: $($file.Name)" -ForegroundColor Gray
        }
        
        Remove-Item $EspSpooferDir -Recurse -Force -ErrorAction Stop
        Write-Host "  Removed: EFI\Spoofer\" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to remove directory" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  No spoofer directory found (already removed?)" -ForegroundColor Gray
}

# Remove boot entry
Write-Host "`n[3/5] Removing boot entry..." -ForegroundColor Yellow

$BootEntryName = "L2signed"

try {
    $bootEntries = bcdedit /enum firmware | Out-String
    
    # Find L2signed entry
    if ($bootEntries -match $BootEntryName) {
        # Extract all GUIDs associated with L2signed
        $lines = $bootEntries -split "`n"
        $foundEntry = $false
        $currentGuid = $null
        
        foreach ($line in $lines) {
            if ($line -match "identifier\s+(\{[^}]+\})") {
                $currentGuid = $matches[1]
            }
            if ($line -match "description\s+$BootEntryName" -and $currentGuid) {
                # Found the entry, delete it
                bcdedit /delete $currentGuid /f | Out-Null
                Write-Host "  Removed boot entry: $currentGuid" -ForegroundColor Green
                $foundEntry = $true
            }
        }
        
        if (-not $foundEntry) {
            Write-Host "  Boot entry found but could not extract GUID" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  No boot entry found (already removed?)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  WARNING: Failed to remove boot entry" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  You may need to remove it manually from BIOS" -ForegroundColor Yellow
}

# Unmount ESP
Write-Host "`n[4/5] Unmounting ESP..." -ForegroundColor Yellow
try {
    Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
    Write-Host "  ESP unmounted successfully" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Failed to unmount ESP" -ForegroundColor Yellow
    Write-Host "  You may need to restart to unmount it" -ForegroundColor Yellow
}

# Verification
Write-Host "`n[5/5] Verifying uninstallation..." -ForegroundColor Yellow

$Success = $true

# Check boot entry
$bootCheck = bcdedit /enum firmware | Out-String
if ($bootCheck -match $BootEntryName) {
    Write-Host "  WARNING: Boot entry still exists" -ForegroundColor Yellow
    $Success = $false
} else {
    Write-Host "  OK: Boot entry removed" -ForegroundColor Green
}

Write-Host "`n=================================" -ForegroundColor Cyan
if ($Success) {
    Write-Host "Uninstallation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The spoofer has been removed from your system." -ForegroundColor White
    Write-Host ""
    Write-Host "What was removed:" -ForegroundColor White
    Write-Host "  - EFI\Spoofer\ directory and all files" -ForegroundColor Gray
    Write-Host "  - Boot entry '$BootEntryName'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "What was kept:" -ForegroundColor White
    Write-Host "  - Backups in EFI\Backups\" -ForegroundColor Gray
    Write-Host "  - Your certificate and signed files in project folder" -ForegroundColor Gray
    Write-Host "  - USB drive (if created)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Your system will now boot normally." -ForegroundColor Cyan
    Write-Host "No HWIDs will be spoofed anymore." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To reinstall, run: install-to-system.ps1" -ForegroundColor Gray
} else {
    Write-Host "Uninstallation completed with warnings!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please check the warnings above." -ForegroundColor Yellow
    Write-Host "You may need to manually remove the boot entry from BIOS." -ForegroundColor Yellow
}
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


