# Emergency Restore Script
# Fixes broken boot configuration and removes spoofer

param(
    [switch]$AutoRun = $false
)

Write-Host "=================================" -ForegroundColor Red
Write-Host "EMERGENCY RESTORE" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Red
Write-Host ""

if (-not $AutoRun) {
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  1. Remove all spoofer files from ESP" -ForegroundColor White
    Write-Host "  2. Remove spoofer boot entries" -ForegroundColor White
    Write-Host "  3. Restore backups (if available)" -ForegroundColor White
    Write-Host "  4. Fix boot configuration" -ForegroundColor White
    Write-Host "  5. Ensure Windows can boot normally" -ForegroundColor White
    Write-Host ""
    Write-Host "Use this if:" -ForegroundColor Cyan
    Write-Host "  - Your system won't boot" -ForegroundColor Gray
    Write-Host "  - Boot is stuck at spoofer" -ForegroundColor Gray
    Write-Host "  - You need to quickly remove everything" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  ERROR: This script must run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "Starting emergency restore..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Mount ESP
Write-Host "[1/6] Mounting ESP..." -ForegroundColor Yellow

$EspVolume = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1

if (-not $EspVolume) {
    Write-Host "  ERROR: Could not find ESP!" -ForegroundColor Red
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
    
    Add-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
    Write-Host "  Mounted ESP" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to mount ESP" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$EspRoot = "${EspDriveLetter}:\"

# Step 2: Remove spoofer files
Write-Host "`n[2/6] Removing spoofer files..." -ForegroundColor Yellow

$EspSpooferDir = Join-Path $EspRoot "EFI\Spoofer"

if (Test-Path $EspSpooferDir) {
    try {
        $files = Get-ChildItem -Path $EspSpooferDir -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "  Deleted: $($file.Name)" -ForegroundColor Gray
        }
        
        Remove-Item $EspSpooferDir -Recurse -Force -ErrorAction Stop
        Write-Host "  Removed spoofer directory" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Could not fully remove spoofer directory" -ForegroundColor Yellow
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No spoofer directory found" -ForegroundColor Gray
}

# Step 3: Remove boot entries
Write-Host "`n[3/6] Removing boot entries..." -ForegroundColor Yellow

$EntriesRemoved = 0

try {
    $bootEntries = bcdedit /enum firmware | Out-String
    $lines = $bootEntries -split "`n"
    $currentGuid = $null
    
    foreach ($line in $lines) {
        if ($line -match "identifier\s+(\{[^}]+\})") {
            $currentGuid = $matches[1]
        }
        if ($line -match "description\s+(L2signed|L2|Spoofer)" -and $currentGuid) {
            try {
                bcdedit /delete $currentGuid /f 2>&1 | Out-Null
                Write-Host "  Removed: $currentGuid" -ForegroundColor Green
                $EntriesRemoved++
            } catch {
                Write-Host "  WARNING: Could not remove $currentGuid" -ForegroundColor Yellow
            }
            $currentGuid = $null
        }
    }
    
    if ($EntriesRemoved -eq 0) {
        Write-Host "  No spoofer boot entries found" -ForegroundColor Gray
    } else {
        Write-Host "  Removed $EntriesRemoved boot entry/entries" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Failed to check boot entries" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Check for backups and offer restoration
Write-Host "`n[4/6] Checking for backups..." -ForegroundColor Yellow

$BackupsDir = Join-Path $EspRoot "EFI\Backups"

if (Test-Path $BackupsDir) {
    $backupDirs = Get-ChildItem -Path $BackupsDir -Directory | Sort-Object Name -Descending
    
    if ($backupDirs.Count -gt 0) {
        Write-Host "  Found $($backupDirs.Count) backup(s)" -ForegroundColor Green
        $latestBackup = $backupDirs[0]
        Write-Host "  Latest backup: $($latestBackup.Name)" -ForegroundColor Gray
        
        if (-not $AutoRun) {
            $restore = Read-Host "  Restore this backup? (yes/no)"
            if ($restore -eq "yes") {
                $bootmgfwBackup = Join-Path $latestBackup.FullName "bootmgfw.efi"
                if (Test-Path $bootmgfwBackup) {
                    $bootmgfwDest = Join-Path $EspRoot "EFI\Microsoft\Boot\bootmgfw.efi"
                    Copy-Item $bootmgfwBackup $bootmgfwDest -Force
                    Write-Host "  Restored: bootmgfw.efi" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "  No backups found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No backup directory found" -ForegroundColor Gray
}

# Step 5: Verify Windows boot manager
Write-Host "`n[5/6] Verifying Windows boot manager..." -ForegroundColor Yellow

$WindowsBootMgr = Join-Path $EspRoot "EFI\Microsoft\Boot\bootmgfw.efi"

if (Test-Path $WindowsBootMgr) {
    $size = (Get-Item $WindowsBootMgr).Length
    Write-Host "  Windows Boot Manager exists ($size bytes)" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Windows Boot Manager not found!" -ForegroundColor Red
    Write-Host "  Your system may need repair." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Try running: bootrec /fixboot" -ForegroundColor Yellow
    Write-Host "  Or use Windows installation media to repair boot" -ForegroundColor Yellow
}

# Check Windows boot entry
try {
    $bootEntries = bcdedit /enum firmware | Out-String
    if ($bootEntries -match "Windows Boot Manager") {
        Write-Host "  Windows Boot Manager entry exists" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Windows Boot Manager entry not found in bcdedit" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING: Could not verify boot entries" -ForegroundColor Yellow
}

# Step 6: Unmount ESP
Write-Host "`n[6/6] Unmounting ESP..." -ForegroundColor Yellow

try {
    Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
    Write-Host "  ESP unmounted" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Failed to unmount ESP" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=================================" -ForegroundColor Green
Write-Host "Emergency Restore Complete" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "What was done:" -ForegroundColor White
Write-Host "  - Removed spoofer files from ESP" -ForegroundColor Gray
Write-Host "  - Removed spoofer boot entries" -ForegroundColor Gray
if ($EntriesRemoved -gt 0) {
    Write-Host "  - Deleted $EntriesRemoved boot entry/entries" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Your system should now boot normally to Windows." -ForegroundColor Cyan
Write-Host ""
Write-Host "If boot still fails:" -ForegroundColor Yellow
Write-Host "  1. Enter BIOS/UEFI setup" -ForegroundColor White
Write-Host "  2. Select 'Windows Boot Manager' as boot device" -ForegroundColor White
Write-Host "  3. Check boot order" -ForegroundColor White
Write-Host "  4. Disable Secure Boot if needed (temporarily)" -ForegroundColor White
Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

if (-not $AutoRun) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

