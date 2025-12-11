# L2 Volume ID Spoofer
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SystemIdSpooferService.cs
# Lines 768-1100: Volume Serial Spoofing region

#Requires -RunAsAdministrator

param(
    [string]$Drive,
    [switch]$All,
    [switch]$List
)

. "$PSScriptRoot\..\core\SpoofingCore.ps1"
. "$PSScriptRoot\..\core\BackupService.ps1"

$VolumeIdToolPath = Join-Path $PSScriptRoot "..\..\tools\volumeid.exe"

function Get-VolumeInfo {
    <#
    .SYNOPSIS
    Gets all fixed volumes with their serials
    .DESCRIPTION
    Based on SystemIdSpooferService.GetVolumeInfo() lines 770-806
    #>
    $volumes = @()
    
    Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq "Fixed" } | ForEach-Object {
        $drive = "$($_.DriveLetter):"
        $serial = (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $drive }).VolumeSerialNumber
        
        if ($serial) {
            # Format serial with dash (XXXX-XXXX)
            $formattedSerial = if ($serial.Length -eq 8) {
                "$($serial.Substring(0,4))-$($serial.Substring(4,4))"
            } else { $serial }
            
            $volumes += @{
                DriveLetter = $drive
                Label = $_.FileSystemLabel
                CurrentSerial = $formattedSerial
                FileSystem = $_.FileSystem
                SizeGB = [math]::Round($_.Size / 1GB, 2)
            }
        }
    }
    
    return $volumes
}

function Get-VolumeIdTool {
    <#
    .SYNOPSIS
    Ensures VolumeID tool is available
    #>
    if (Test-Path $VolumeIdToolPath) {
        return $VolumeIdToolPath
    }
    
    Write-SpooferLog "VolumeID tool not found. Downloading..." -Level Warning
    
    # Download from Microsoft Sysinternals
    $url = "https://download.sysinternals.com/files/VolumeId.zip"
    $zipPath = Join-Path $env:TEMP "VolumeId.zip"
    $extractPath = Join-Path $env:TEMP "VolumeId"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        $toolDir = Split-Path $VolumeIdToolPath -Parent
        if (-not (Test-Path $toolDir)) {
            New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        }
        
        Copy-Item "$extractPath\volumeid.exe" -Destination $VolumeIdToolPath -Force
        
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-SpooferLog "VolumeID downloaded successfully" -Level Success
        return $VolumeIdToolPath
    }
    catch {
        Write-SpooferLog "Failed to download VolumeID: $_" -Level Error
        return $null
    }
}

function Set-VolumeSerial {
    <#
    .SYNOPSIS
    Changes volume serial number
    .DESCRIPTION
    Based on SystemIdSpooferService.SpoofVolumeSerial() lines 809-1098
    #>
    param(
        [Parameter(Mandatory)]
        [string]$DriveLetter,
        [string]$NewSerial
    )
    
    # Validate drive letter
    $DriveLetter = $DriveLetter.TrimEnd('\', '/').Trim()
    if ($DriveLetter.Length -eq 1) { $DriveLetter = "$DriveLetter`:" }
    
    Write-SpooferLog "Starting Volume Serial Spoofing for $DriveLetter" -Level Info
    
    # Check if system drive
    $systemDrive = $env:SystemDrive
    if ($DriveLetter -eq $systemDrive) {
        Write-SpooferLog "WARNING: $DriveLetter is your system drive!" -Level Warning
        Write-SpooferLog "This may affect Windows activation" -Level Warning
    }
    
    # Get current serial
    $currentSerial = (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $DriveLetter }).VolumeSerialNumber
    if ($currentSerial) {
        $formattedCurrent = "$($currentSerial.Substring(0,4))-$($currentSerial.Substring(4,4))"
        Write-SpooferLog "Current serial: $formattedCurrent" -Level Info
    }
    
    # Generate new serial if not provided
    if (-not $NewSerial) {
        $NewSerial = Get-RandomVolumeSerial
    }
    
    Write-SpooferLog "New serial: $NewSerial" -Level Info
    
    # Get VolumeID tool
    $toolPath = Get-VolumeIdTool
    if (-not $toolPath) {
        Write-SpooferLog "Cannot proceed without VolumeID.exe" -Level Error
        return $false
    }
    
    # Execute VolumeID
    Write-SpooferLog "Executing VolumeID..." -Level Info
    
    $process = Start-Process -FilePath $toolPath `
        -ArgumentList "/accepteula", $DriveLetter, $NewSerial `
        -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        Write-SpooferLog "VolumeID failed with exit code: $($process.ExitCode)" -Level Error
        return $false
    }
    
    Write-SpooferLog "Volume serial changed successfully!" -Level Success
    Write-SpooferLog "RESTART REQUIRED for changes to take effect" -Level Warning
    
    return $true
}

function Invoke-VolumeIdSpoofing {
    <#
    .SYNOPSIS
    Main Volume ID spoofing function
    #>
    param(
        [string]$TargetDrive,
        [switch]$AllDrives
    )
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "       L2 VOLUME ID SPOOFER                            " -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Create backup first
    New-SystemIdBackup -Description "Pre-VolumeID-Spoofing Backup" | Out-Null
    
    $volumes = Get-VolumeInfo
    
    if ($AllDrives) {
        foreach ($vol in $volumes) {
            Set-VolumeSerial -DriveLetter $vol.DriveLetter
        }
    }
    elseif ($TargetDrive) {
        Set-VolumeSerial -DriveLetter $TargetDrive
    }
    else {
        # Interactive mode
        Write-Host "Available Volumes:" -ForegroundColor Yellow
        Write-Host ""
        
        for ($i = 0; $i -lt $volumes.Count; $i++) {
            $isSystem = if ($volumes[$i].DriveLetter -eq $env:SystemDrive) { " [SYSTEM]" } else { "" }
            Write-Host "  [$($i + 1)] $($volumes[$i].DriveLetter)$isSystem" -ForegroundColor White
            Write-Host "      Serial: $($volumes[$i].CurrentSerial)" -ForegroundColor Gray
            Write-Host "      Label: $($volumes[$i].Label) | $($volumes[$i].FileSystem) | $($volumes[$i].SizeGB) GB" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        $choice = Read-Host "Select volume number (or 'all' for all volumes)"
        
        if ($choice -eq "all") {
            foreach ($vol in $volumes) {
                Set-VolumeSerial -DriveLetter $vol.DriveLetter
            }
        }
        else {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $volumes.Count) {
                Set-VolumeSerial -DriveLetter $volumes[$index].DriveLetter
            }
            else {
                Write-SpooferLog "Invalid selection" -Level Error
            }
        }
    }
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ Volume ID Spoofing Complete!" -ForegroundColor Green
    Write-Host "⚠️  RESTART REQUIRED for changes to take effect" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
}

# Main execution
if ($List) {
    Get-VolumeInfo | Format-Table DriveLetter, CurrentSerial, Label, FileSystem, SizeGB -AutoSize
}
else {
    Invoke-VolumeIdSpoofing -TargetDrive $Drive -AllDrives:$All
}
