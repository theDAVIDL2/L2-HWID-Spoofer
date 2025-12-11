# Unmount ESP Drive Script
# Simple utility to safely unmount the ESP partition

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "ESP Unmount Tool" -ForegroundColor Cyan
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

Write-Host "Checking for mounted ESP..." -ForegroundColor Yellow
Write-Host ""

# Find ESP
$EspVolume = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1

if (-not $EspVolume) {
    Write-Host "  No ESP partition found on this system." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "ESP found:" -ForegroundColor Green
Write-Host "  Disk: $($EspVolume.DiskNumber)" -ForegroundColor Gray
Write-Host "  Partition: $($EspVolume.PartitionNumber)" -ForegroundColor Gray
Write-Host "  Size: $([math]::Round($EspVolume.Size / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""

# Check if mounted
$MountedDrives = @("S", "T", "U", "V", "W", "X", "Y", "Z")
$EspMounted = $false
$EspDriveLetter = $null

foreach ($letter in $MountedDrives) {
    try {
        $volume = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
        if ($volume) {
            # Check if this is the ESP
            $partition = Get-Partition -DriveLetter $letter -ErrorAction SilentlyContinue
            if ($partition -and $partition.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}') {
                $EspMounted = $true
                $EspDriveLetter = $letter
                break
            }
        }
    } catch {
        # Drive letter not in use, continue
    }
}

if ($EspMounted) {
    Write-Host "ESP is currently mounted as ${EspDriveLetter}:\" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Unmounting..." -ForegroundColor Yellow
    
    try {
        Remove-PartitionAccessPath -DiskNumber $EspVolume.DiskNumber -PartitionNumber $EspVolume.PartitionNumber -AccessPath "${EspDriveLetter}:\" -ErrorAction Stop
        Write-Host "  ESP unmounted successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Drive letter ${EspDriveLetter}: is now free." -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to unmount ESP" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  The drive may be in use. Try:" -ForegroundColor Yellow
        Write-Host "  1. Close all Explorer windows" -ForegroundColor Gray
        Write-Host "  2. Close any programs accessing ${EspDriveLetter}:\" -ForegroundColor Gray
        Write-Host "  3. Run this script again" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  If that doesn't work, restart your computer." -ForegroundColor Yellow
    }
} else {
    Write-Host "ESP is not currently mounted." -ForegroundColor Green
    Write-Host "Nothing to do." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


