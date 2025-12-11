# L2 HWID Master - Interactive Guided Spoofing Launcher
# Main entry point with step-by-step guides for all spoofing methods
# Better than L2 Setup - more visual, better explanations

#Requires -RunAsAdministrator

$ScriptRoot = $PSScriptRoot

# Import all modules
. "$ScriptRoot\core\SpoofingCore.ps1"
. "$ScriptRoot\core\BackupService.ps1"
. "$ScriptRoot\core\ToolDownloader.ps1"

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                               ║" -ForegroundColor Cyan
    Write-Host "  ║   ██╗     ██████╗    ██╗  ██╗██╗    ██╗██╗██████╗             ║" -ForegroundColor Cyan
    Write-Host "  ║   ██║     ╚════██╗   ██║  ██║██║    ██║██║██╔══██╗            ║" -ForegroundColor Cyan
    Write-Host "  ║   ██║      █████╔╝   ███████║██║ █╗ ██║██║██║  ██║            ║" -ForegroundColor Cyan
    Write-Host "  ║   ██║     ██╔═══╝    ██╔══██║██║███╗██║██║██║  ██║            ║" -ForegroundColor Cyan
    Write-Host "  ║   ███████╗███████╗   ██║  ██║╚███╔███╔╝██║██████╔╝            ║" -ForegroundColor Cyan
    Write-Host "  ║   ╚══════╝╚══════╝   ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝╚═════╝             ║" -ForegroundColor Cyan
    Write-Host "  ║                                                               ║" -ForegroundColor Cyan
    Write-Host "  ║            M A S T E R   S P O O F E R                        ║" -ForegroundColor Cyan
    Write-Host "  ║                                                               ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "  ┌───────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                      MAIN MENU                                │" -ForegroundColor White
    Write-Host "  ├───────────────────────────────────────────────────────────────┤" -ForegroundColor White
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [1] 🔄 Quick Spoof All        (MAC, Volume, GUIDs)         │" -ForegroundColor Yellow
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [2] 📖 Guided Spoofing       (Step-by-step guides)         │" -ForegroundColor Green
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [3] 🔧 Individual Methods    (Choose specific method)      │" -ForegroundColor Cyan
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [4] 📥 Manage Tools          (Download/check tools)        │" -ForegroundColor Magenta
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [5] 💾 Backup & Restore      (Manage system backups)       │" -ForegroundColor Blue
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [6] 📊 View Current IDs      (Show hardware fingerprint)   │" -ForegroundColor White
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  │    [Q] ❌ Exit                                                 │" -ForegroundColor Red
    Write-Host "  │                                                               │" -ForegroundColor White
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
}

function Show-GuidedMenu {
    Show-Banner
    Write-Host "  ┌───────────────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "  │                GUIDED SPOOFING METHODS                        │" -ForegroundColor Green
    Write-Host "  ├───────────────────────────────────────────────────────────────┤" -ForegroundColor Green
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  │  Each guide will walk you through the process step-by-step   │" -ForegroundColor White
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  │    [1] 🌐 MAC Address Spoofing                                │" -ForegroundColor Cyan
    Write-Host "  │        Change your network adapter's MAC address              │" -ForegroundColor Gray
    Write-Host "  │        Difficulty: Easy | Time: 2 min | No restart needed     │" -ForegroundColor DarkGray
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  │    [2] 💿 Volume ID Spoofing                                  │" -ForegroundColor Cyan
    Write-Host "  │        Change your drive serial numbers                       │" -ForegroundColor Gray
    Write-Host "  │        Difficulty: Easy | Time: 2 min | Restart required      │" -ForegroundColor DarkGray
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  │    [3] 🔑 Machine GUID Spoofing                               │" -ForegroundColor Cyan
    Write-Host "  │        Change Windows machine identifiers                     │" -ForegroundColor Gray
    Write-Host "  │        Difficulty: Easy | Time: 1 min | No restart needed     │" -ForegroundColor DarkGray
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  │    [4] 🖥️  Monitor EDID Spoofing (CRU)                         │" -ForegroundColor Yellow
    Write-Host "  │        Change your monitor serial/model                       │" -ForegroundColor Gray
    Write-Host "  │        Difficulty: Medium | Time: 5 min | Driver restart      │" -ForegroundColor DarkGray
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  │    [B] ← Back to Main Menu                                    │" -ForegroundColor White
    Write-Host "  │                                                               │" -ForegroundColor Green
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
}

function Start-GuidedMacSpoof {
    Show-Banner
    
    # Step 1: Introduction
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║      GUIDED: MAC ADDRESS SPOOFING              Step 1/5       ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  📖 WHAT IS A MAC ADDRESS?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  A MAC (Media Access Control) address is a unique identifier" -ForegroundColor White
    Write-Host "  assigned to your network adapter by the manufacturer." -ForegroundColor White
    Write-Host ""
    Write-Host "  🎮 WHY SPOOF IT?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  • Anti-cheat systems log MAC addresses to identify hardware" -ForegroundColor Gray
    Write-Host "  • Changing it helps create a new hardware identity" -ForegroundColor Gray
    Write-Host "  • Works for both Ethernet and WiFi adapters" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ⚡ This is the EASIEST spoofing method - no restart required!" -ForegroundColor Green
    Write-Host ""
    
    $continue = Read-Host "  Press ENTER to continue (or 'q' to quit)"
    if ($continue -eq 'q') { return }
    
    # Step 2: Create Backup
    Show-Banner
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║      GUIDED: MAC ADDRESS SPOOFING              Step 2/5       ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  💾 CREATING BACKUP" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Before making any changes, we'll save your current settings." -ForegroundColor White
    Write-Host "  This allows you to restore everything if needed." -ForegroundColor White
    Write-Host ""
    
    Write-SpooferLog "Creating backup..." -Level Info
    New-SystemIdBackup -Description "Pre-MAC-Spoofing Backup" | Out-Null
    Write-Host ""
    Write-Host "  ✅ Backup created successfully!" -ForegroundColor Green
    Write-Host ""
    
    Start-Sleep -Seconds 1
    
    # Step 3: Select Adapter
    Show-Banner
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║      GUIDED: MAC ADDRESS SPOOFING              Step 3/5       ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  🌐 SELECT YOUR NETWORK ADAPTER" -ForegroundColor Yellow
    Write-Host ""
    
    $adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }
    
    if ($adapters.Count -eq 0) {
        Write-Host "  ❌ No active network adapters found!" -ForegroundColor Red
        Read-Host "  Press ENTER to return"
        return
    }
    
    $i = 1
    foreach ($adapter in $adapters) {
        Write-Host "  [$i] $($adapter.Name)" -ForegroundColor White
        Write-Host "      Current MAC: $($adapter.MacAddress)" -ForegroundColor Gray
        Write-Host "      Type: $($adapter.InterfaceDescription)" -ForegroundColor DarkGray
        Write-Host ""
        $i++
    }
    
    Write-Host "  [A] Spoof ALL adapters" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "  Enter your choice"
    
    $selectedAdapters = @()
    if ($choice -eq "A" -or $choice -eq "a") {
        $selectedAdapters = $adapters
    }
    else {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $adapters.Count) {
            $selectedAdapters = @($adapters[$index])
        }
    }
    
    if ($selectedAdapters.Count -eq 0) {
        Write-Host "  ❌ Invalid selection" -ForegroundColor Red
        Read-Host "  Press ENTER to return"
        return
    }
    
    # Step 4: Generate and Apply
    Show-Banner
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║      GUIDED: MAC ADDRESS SPOOFING              Step 4/5       ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  🔄 APPLYING CHANGES" -ForegroundColor Yellow
    Write-Host ""
    
    . "$ScriptRoot\methods\MacSpoofer.ps1"
    
    foreach ($adapter in $selectedAdapters) {
        $newMac = Get-RandomMac
        Write-Host "  Changing $($adapter.Name)..." -ForegroundColor White
        Write-Host "  Old MAC: $($adapter.MacAddress)" -ForegroundColor Gray
        Write-Host "  New MAC: $newMac" -ForegroundColor Green
        Write-Host ""
        
        Set-MacAddress -AdapterName $adapter.Name -MacAddress $newMac
        Write-Host ""
    }
    
    # Step 5: Verify
    Show-Banner
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║      GUIDED: MAC ADDRESS SPOOFING              Step 5/5       ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ✅ VERIFICATION" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Let's verify your new MAC addresses:" -ForegroundColor White
    Write-Host ""
    
    $newAdapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $newAdapters) {
        Write-Host "  ✅ $($adapter.Name)" -ForegroundColor Green
        Write-Host "     MAC: $($adapter.MacAddress)" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "  ════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  🎉 MAC ADDRESS SPOOFING COMPLETE!" -ForegroundColor Green
    Write-Host "  ════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Your network adapters now have new MAC addresses." -ForegroundColor White
    Write-Host "  No restart is required - changes are already active!" -ForegroundColor Gray
    Write-Host ""
    
    Read-Host "  Press ENTER to return to menu"
}

function Show-CurrentFingerprint {
    Show-Banner
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║              CURRENT HARDWARE FINGERPRINT                     ║" -ForegroundColor Yellow
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    # Machine GUIDs
    Write-Host "  [MACHINE GUIDS]" -ForegroundColor Cyan
    $machineGuid = Get-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid"
    Write-Host "  • MachineGuid: $machineGuid" -ForegroundColor White
    
    $machineId = Get-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\SQMClient" -Name "MachineId"
    Write-Host "  • MachineId: $machineId" -ForegroundColor White
    Write-Host ""
    
    # MAC Addresses
    Write-Host "  [MAC ADDRESSES]" -ForegroundColor Cyan
    Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.MacAddress)" -ForegroundColor White
    }
    Write-Host ""
    
    # Volume Serials
    Write-Host "  [VOLUME SERIALS]" -ForegroundColor Cyan
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
        $serial = $_.VolumeSerialNumber
        if ($serial -and $serial.Length -eq 8) {
            $serial = "$($serial.Substring(0,4))-$($serial.Substring(4,4))"
        }
        Write-Host "  • $($_.DeviceID) $serial" -ForegroundColor White
    }
    Write-Host ""
    
    # Disk Serials
    Write-Host "  [DISK SERIALS]" -ForegroundColor Cyan
    Get-WmiObject Win32_DiskDrive | ForEach-Object {
        Write-Host "  • $($_.Model): $($_.SerialNumber)" -ForegroundColor White
    }
    Write-Host ""
    
    Read-Host "  Press ENTER to return"
}

function Show-ToolsMenu {
    Show-Banner
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║                    MANAGE TOOLS                               ║" -ForegroundColor Magenta
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    Show-ToolsStatus
    
    Write-Host "  ┌───────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │    [1] Download All Required Tools                            │" -ForegroundColor Yellow
    Write-Host "  │    [2] Download VolumeID                                      │" -ForegroundColor White
    Write-Host "  │    [3] Download CRU (Monitor Spoofer)                         │" -ForegroundColor White
    Write-Host "  │    [4] Open Tools Folder                                      │" -ForegroundColor White
    Write-Host "  │    [B] Back to Main Menu                                      │" -ForegroundColor White
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "  Enter your choice"
    
    switch ($choice) {
        "1" { Install-AllTools; Read-Host "  Press ENTER to continue" }
        "2" { Install-SpoofingTool -ToolName "VolumeID"; Read-Host "  Press ENTER to continue" }
        "3" { Install-SpoofingTool -ToolName "CRU"; Read-Host "  Press ENTER to continue" }
        "4" { Open-ToolsDirectory }
        "B" { return }
        "b" { return }
    }
}

function Main {
    while ($true) {
        Show-Banner
        Show-MainMenu
        
        $choice = Read-Host "  Enter your choice"
        
        switch ($choice.ToUpper()) {
            "1" {
                # Quick Spoof All
                . "$ScriptRoot\quick-spoof.ps1"
            }
            "2" {
                # Guided Menu
                while ($true) {
                    Show-GuidedMenu
                    $guidedChoice = Read-Host "  Enter your choice"
                    
                    switch ($guidedChoice) {
                        "1" { Start-GuidedMacSpoof }
                        "2" { 
                            Write-Host "  Starting Volume ID Guide..." -ForegroundColor Cyan
                            . "$ScriptRoot\methods\VolumeIdSpoofer.ps1"
                        }
                        "3" { 
                            Write-Host "  Starting Machine GUID Guide..." -ForegroundColor Cyan
                            . "$ScriptRoot\methods\MachineGuidSpoofer.ps1"
                        }
                        "4" { 
                            Write-Host "  Monitor EDID guide coming soon..." -ForegroundColor Yellow
                            Read-Host "  Press ENTER to continue"
                        }
                        "B" { break }
                        "b" { break }
                    }
                    
                    if ($guidedChoice -eq "B" -or $guidedChoice -eq "b") { break }
                }
            }
            "3" {
                # Individual Methods
                Show-Banner
                Write-Host "  [1] MAC Address Spoofer" -ForegroundColor White
                Write-Host "  [2] Volume ID Spoofer" -ForegroundColor White
                Write-Host "  [3] Machine GUID Spoofer" -ForegroundColor White
                Write-Host ""
                $methodChoice = Read-Host "  Enter your choice"
                
                switch ($methodChoice) {
                    "1" { . "$ScriptRoot\methods\MacSpoofer.ps1" }
                    "2" { . "$ScriptRoot\methods\VolumeIdSpoofer.ps1" }
                    "3" { . "$ScriptRoot\methods\MachineGuidSpoofer.ps1" }
                }
            }
            "4" {
                # Tools Menu
                Show-ToolsMenu
            }
            "5" {
                # Backup & Restore
                Show-Banner
                Write-Host "  [1] Create New Backup" -ForegroundColor White
                Write-Host "  [2] List Backups" -ForegroundColor White
                Write-Host "  [3] Restore Backup" -ForegroundColor White
                Write-Host ""
                $backupChoice = Read-Host "  Enter your choice"
                
                switch ($backupChoice) {
                    "1" { 
                        New-SystemIdBackup -Description "Manual Backup"
                        Read-Host "  Press ENTER to continue"
                    }
                    "2" { 
                        $backups = Get-SystemIdBackups
                        foreach ($b in $backups) {
                            Write-Host "  $($b.BackupDate) - $($b.Description)" -ForegroundColor White
                        }
                        Read-Host "  Press ENTER to continue"
                    }
                    "3" {
                        $backups = Get-SystemIdBackups
                        if ($backups.Count -gt 0) {
                            Restore-SystemIdBackup -BackupId $backups[0].BackupId
                        }
                        Read-Host "  Press ENTER to continue"
                    }
                }
            }
            "6" {
                # View Current IDs
                Show-CurrentFingerprint
            }
            "Q" { 
                Write-Host ""
                Write-Host "  Thank you for using L2 HWID Master!" -ForegroundColor Green
                Write-Host ""
                exit 0
            }
        }
    }
}

# Run main
Main
