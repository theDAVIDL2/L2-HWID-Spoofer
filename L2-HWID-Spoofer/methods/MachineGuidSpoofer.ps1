# L2 Machine GUID Spoofer
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SystemIdSpooferService.cs
# Lines 391-437: Machine GUID Spoofing region

#Requires -RunAsAdministrator

param(
    [switch]$List
)

. "$PSScriptRoot\..\core\SpoofingCore.ps1"
. "$PSScriptRoot\..\core\BackupService.ps1"

$GuidPaths = @{
    "MachineGuid" = @{
        Path = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        Name = "MachineGuid"
        Description = "Windows Machine GUID"
        Format = "standard"  # xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    }
    "MachineId" = @{
        Path = "HKLM:\SOFTWARE\Microsoft\SQMClient"
        Name = "MachineId"
        Description = "SQM Client Machine ID"
        Format = "braced"  # {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
    }
    "HwProfileGuid" = @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\IDConfigDB\Hardware Profiles\0001"
        Name = "HwProfileGuid"
        Description = "Hardware Profile GUID"
        Format = "braced"
    }
    "ProductId" = @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        Name = "ProductId"
        Description = "Windows Product ID"
        Format = "productid"  # XXXXX-XXXXX-XXXXX-XXXXX
    }
}

function Get-MachineGuids {
    <#
    .SYNOPSIS
    Gets all machine GUIDs and identifiers
    #>
    $guids = @()
    
    foreach ($key in $GuidPaths.Keys) {
        $config = $GuidPaths[$key]
        $value = Get-RegistryValue -Path $config.Path -Name $config.Name
        
        $guids += @{
            Key = $key
            Description = $config.Description
            CurrentValue = if ($value) { $value } else { "(not found)" }
            Path = $config.Path
        }
    }
    
    return $guids
}

function New-FormattedGuid {
    <#
    .SYNOPSIS
    Generates a new GUID in the specified format
    #>
    param(
        [ValidateSet("standard", "braced", "productid")]
        [string]$Format = "standard"
    )
    
    $guid = [guid]::NewGuid()
    
    switch ($Format) {
        "standard" { return $guid.ToString() }
        "braced" { return "{$($guid.ToString().ToUpper())}" }
        "productid" {
            # Generate Windows Product ID format: XXXXX-XXXXX-XXXXX-XXXXX
            $random = [System.Random]::new()
            $parts = @()
            for ($i = 0; $i -lt 4; $i++) {
                $parts += $random.Next(10000, 99999).ToString()
            }
            return $parts -join "-"
        }
    }
}

function Set-MachineGuids {
    <#
    .SYNOPSIS
    Spoofs all machine GUIDs
    .DESCRIPTION
    Based on SystemIdSpooferService.SpoofMachineGuids() lines 393-435
    #>
    param(
        [switch]$IncludeProductId  # ProductId is more sensitive
    )
    
    Write-SpooferLog "Spoofing Windows Machine GUIDs..." -Level Info
    
    foreach ($key in $GuidPaths.Keys) {
        # Skip ProductId unless explicitly requested
        if ($key -eq "ProductId" -and -not $IncludeProductId) {
            Write-SpooferLog "Skipping ProductId (use -IncludeProductId to include)" -Level Info
            continue
        }
        
        $config = $GuidPaths[$key]
        
        try {
            $currentValue = Get-RegistryValue -Path $config.Path -Name $config.Name
            $newValue = New-FormattedGuid -Format $config.Format
            
            $result = Set-RegistryValue -Path $config.Path -Name $config.Name -Value $newValue
            
            if ($result) {
                Write-SpooferLog "$($config.Description): $currentValue → $newValue" -Level Success
            }
            else {
                Write-SpooferLog "Could not spoof $($config.Description)" -Level Warning
            }
        }
        catch {
            Write-SpooferLog "Error spoofing $key`: $_" -Level Warning
        }
    }
}

function Invoke-MachineGuidSpoofing {
    <#
    .SYNOPSIS
    Main Machine GUID spoofing function
    #>
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "       L2 MACHINE GUID SPOOFER                         " -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Create backup first
    New-SystemIdBackup -Description "Pre-MachineGUID-Spoofing Backup" | Out-Null
    
    # Show current values
    Write-Host "Current Machine Identifiers:" -ForegroundColor Yellow
    Write-Host ""
    
    $guids = Get-MachineGuids
    foreach ($guid in $guids) {
        Write-Host "  $($guid.Description):" -ForegroundColor White
        Write-Host "    $($guid.CurrentValue)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host ""
    $confirm = Read-Host "Spoof all GUIDs? (y/n, or 'all' to include ProductId)"
    
    if ($confirm -eq "y") {
        Set-MachineGuids
    }
    elseif ($confirm -eq "all") {
        Set-MachineGuids -IncludeProductId
    }
    else {
        Write-SpooferLog "Operation cancelled" -Level Warning
        return
    }
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ Machine GUID Spoofing Complete!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
}

# Main execution
if ($List) {
    Get-MachineGuids | Format-Table Key, Description, CurrentValue -AutoSize
}
else {
    Invoke-MachineGuidSpoofing
}
