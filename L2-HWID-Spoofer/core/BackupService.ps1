# L2 Backup Service Module
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SystemIdSpooferService.cs
# Handles backup and restore of system identifiers

#Requires -RunAsAdministrator

. "$PSScriptRoot\SpoofingCore.ps1"

function New-SystemIdBackup {
    <#
    .SYNOPSIS
    Creates a full backup of all system identifiers
    .DESCRIPTION
    Based on SystemIdSpooferService.CreateFullBackup()
    Backs up: Registry entries, MAC addresses, Volume serials, Network settings
    #>
    param(
        [string]$Description = "Full System Identity Backup"
    )
    
    Write-SpooferLog "Creating full system identity backup..." -Level Info
    
    $backupId = [guid]::NewGuid().ToString()
    $backup = @{
        BackupId = $backupId
        BackupDate = (Get-Date).ToString("o")
        Description = $Description
        RegistryBackups = @()
        MacAddresses = @{}
        VolumeSerials = @{}
        NetworkSettings = @{}
    }
    
    # Backup registry entries
    $registryPaths = @{
        "HKLM:\SOFTWARE\Microsoft\Cryptography" = @("MachineGuid")
        "HKLM:\SOFTWARE\Microsoft\SQMClient" = @("MachineId")
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" = @("ProductId")
        "HKLM:\SYSTEM\CurrentControlSet\Control\IDConfigDB\Hardware Profiles\0001" = @("HwProfileGuid")
    }
    
    foreach ($path in $registryPaths.Keys) {
        foreach ($valueName in $registryPaths[$path]) {
            try {
                $value = Get-RegistryValue -Path $path -Name $valueName
                if ($value) {
                    $backup.RegistryBackups += @{
                        Path = $path
                        ValueName = $valueName
                        OriginalValue = $value
                    }
                    Write-SpooferLog "Backed up: $path\$valueName" -Level Info
                }
            }
            catch {
                Write-SpooferLog "Could not backup $path\$valueName" -Level Warning
            }
        }
    }
    
    # Backup MAC addresses
    Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $backup.MacAddresses[$_.Name] = $_.MacAddress
        Write-SpooferLog "Backed up MAC: $($_.Name) = $($_.MacAddress)" -Level Info
    }
    
    # Backup volume serials
    Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq "Fixed" } | ForEach-Object {
        $drive = "$($_.DriveLetter):"
        $serial = (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $drive }).VolumeSerialNumber
        if ($serial) {
            $backup.VolumeSerials[$drive] = $serial
            Write-SpooferLog "Backed up Volume: $drive = $serial" -Level Info
        }
    }
    
    # Save backup to file
    $backupPath = Join-Path $script:BackupDirectory "SystemIdBackup_$backupId.json"
    $backup | ConvertTo-Json -Depth 10 | Set-Content -Path $backupPath -Encoding UTF8
    
    Write-SpooferLog "Backup created: $backupPath" -Level Success
    return $backup
}

function Get-SystemIdBackups {
    <#
    .SYNOPSIS
    Lists all available backups
    #>
    $backups = @()
    
    Get-ChildItem -Path $script:BackupDirectory -Filter "SystemIdBackup_*.json" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending |
    ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $backups += @{
                BackupId = $content.BackupId
                BackupDate = $content.BackupDate
                Description = $content.Description
                FilePath = $_.FullName
            }
        }
        catch {
            Write-SpooferLog "Could not read backup: $($_.Name)" -Level Warning
        }
    }
    
    return $backups
}

function Restore-SystemIdBackup {
    <#
    .SYNOPSIS
    Restores system identifiers from a backup
    .DESCRIPTION
    Based on SystemIdSpooferService.RestoreBackup()
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BackupId
    )
    
    $backupPath = Join-Path $script:BackupDirectory "SystemIdBackup_$BackupId.json"
    
    if (-not (Test-Path $backupPath)) {
        Write-SpooferLog "Backup not found: $BackupId" -Level Error
        return $false
    }
    
    Write-SpooferLog "Restoring backup: $BackupId" -Level Info
    
    $backup = Get-Content $backupPath -Raw | ConvertFrom-Json
    
    # Restore registry entries
    foreach ($entry in $backup.RegistryBackups) {
        try {
            Set-RegistryValue -Path $entry.Path -Name $entry.ValueName -Value $entry.OriginalValue
            Write-SpooferLog "Restored: $($entry.Path)\$($entry.ValueName)" -Level Success
        }
        catch {
            Write-SpooferLog "Could not restore $($entry.Path)\$($entry.ValueName)" -Level Warning
        }
    }
    
    Write-SpooferLog "Backup restored successfully" -Level Success
    Write-SpooferLog "Note: MAC address and volume serial restore may require additional steps" -Level Warning
    
    return $true
}

function Remove-SystemIdBackup {
    <#
    .SYNOPSIS
    Deletes a backup file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BackupId
    )
    
    $backupPath = Join-Path $script:BackupDirectory "SystemIdBackup_$BackupId.json"
    
    if (Test-Path $backupPath) {
        Remove-Item $backupPath -Force
        Write-SpooferLog "Backup deleted: $BackupId" -Level Success
        return $true
    }
    
    Write-SpooferLog "Backup not found: $BackupId" -Level Warning
    return $false
}

Export-ModuleMember -Function *
