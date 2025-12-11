# L2 Quick Spoof - All-in-One Spoofing Script
# Runs all spoofing methods in sequence with automatic backup

#Requires -RunAsAdministrator

param(
    [switch]$SkipBackup,
    [switch]$SkipMac,
    [switch]$SkipVolumeId,
    [switch]$SkipMachineGuid
)

$ScriptRoot = $PSScriptRoot

. "$ScriptRoot\core\SpoofingCore.ps1"
. "$ScriptRoot\core\BackupService.ps1"

function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "║        ██╗     ██████╗     ███████╗██████╗  ██████╗  ██████╗ ███████╗║" -ForegroundColor Cyan
    Write-Host "║        ██║     ╚════██╗    ██╔════╝██╔══██╗██╔═══██╗██╔═══██╗██╔════╝║" -ForegroundColor Cyan
    Write-Host "║        ██║      █████╔╝    ███████╗██████╔╝██║   ██║██║   ██║█████╗  ║" -ForegroundColor Cyan
    Write-Host "║        ██║     ██╔═══╝     ╚════██║██╔═══╝ ██║   ██║██║   ██║██╔══╝  ║" -ForegroundColor Cyan
    Write-Host "║        ███████╗███████╗    ███████║██║     ╚██████╔╝╚██████╔╝██║     ║" -ForegroundColor Cyan
    Write-Host "║        ╚══════╝╚══════╝    ╚══════╝╚═╝      ╚═════╝  ╚═════╝ ╚═╝     ║" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "║          L2 HWID SPOOFER - QUICK SPOOF ALL                   ║" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-CurrentFingerprint {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  CURRENT HARDWARE FINGERPRINT" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    # Machine GUIDs
    Write-Host "  [Machine GUIDs]" -ForegroundColor White
    $machineGuid = Get-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid"
    Write-Host "    MachineGuid: $machineGuid" -ForegroundColor Gray
    
    # MAC Addresses
    Write-Host ""
    Write-Host "  [MAC Addresses]" -ForegroundColor White
    Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Write-Host "    $($_.Name): $($_.MacAddress)" -ForegroundColor Gray
    }
    
    # Volume Serials
    Write-Host ""
    Write-Host "  [Volume Serials]" -ForegroundColor White
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
        $serial = $_.VolumeSerialNumber
        if ($serial -and $serial.Length -eq 8) {
            $serial = "$($serial.Substring(0,4))-$($serial.Substring(4,4))"
        }
        Write-Host "    $($_.DeviceID) $serial" -ForegroundColor Gray
    }
    
    Write-Host ""
}

function Invoke-QuickSpoof {
    Show-Banner
    
    Write-SpooferLog "L2 Quick Spoof - Starting..." -Level Info
    
    # Step 1: Create Backup
    if (-not $SkipBackup) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "  STEP 1: Creating Full System Backup" -ForegroundColor Magenta
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        $backup = New-SystemIdBackup -Description "Pre-QuickSpoof Full Backup"
        Write-Host ""
    }
    
    # Show current fingerprint
    Show-CurrentFingerprint
    
    # Confirm
    Write-Host "This will spoof:" -ForegroundColor Yellow
    if (-not $SkipMachineGuid) { Write-Host "  ✓ Machine GUIDs" -ForegroundColor Green }
    if (-not $SkipMac) { Write-Host "  ✓ MAC Addresses" -ForegroundColor Green }
    if (-not $SkipVolumeId) { Write-Host "  ✓ Volume Serials" -ForegroundColor Green }
    Write-Host ""
    
    $confirm = Read-Host "Proceed with spoofing? (y/n)"
    if ($confirm -ne "y") {
        Write-SpooferLog "Operation cancelled by user" -Level Warning
        return
    }
    
    # Step 2: Machine GUIDs
    if (-not $SkipMachineGuid) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "  STEP 2: Spoofing Machine GUIDs" -ForegroundColor Magenta
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        
        . "$ScriptRoot\methods\MachineGuidSpoofer.ps1"
        Set-MachineGuids
    }
    
    # Step 3: MAC Addresses
    if (-not $SkipMac) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "  STEP 3: Spoofing MAC Addresses" -ForegroundColor Magenta
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        
        . "$ScriptRoot\methods\MacSpoofer.ps1"
        Get-NetworkAdapters | ForEach-Object {
            Set-MacAddress -AdapterName $_.Name
        }
    }
    
    # Step 4: Volume IDs (will require restart)
    if (-not $SkipVolumeId) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "  STEP 4: Spoofing Volume Serials" -ForegroundColor Magenta
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        
        . "$ScriptRoot\methods\VolumeIdSpoofer.ps1"
        Get-VolumeInfo | ForEach-Object {
            Set-VolumeSerial -DriveLetter $_.DriveLetter
        }
    }
    
    # Final summary
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                   SPOOFING COMPLETE!                          ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ✅ Machine GUIDs: Spoofed" -ForegroundColor Green
    Write-Host "  ✅ MAC Addresses: Spoofed" -ForegroundColor Green
    Write-Host "  ✅ Volume Serials: Spoofed (restart required)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  📁 Backup saved to: $($script:BackupDirectory)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ⚠️  RESTART YOUR COMPUTER to apply all changes!" -ForegroundColor Yellow
    Write-Host ""
    
    $restart = Read-Host "Restart now? (y/n)"
    if ($restart -eq "y") {
        Write-SpooferLog "Restarting computer..." -Level Warning
        Restart-Computer -Force
    }
}

# Run
Invoke-QuickSpoof
