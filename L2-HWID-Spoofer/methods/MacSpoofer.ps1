# L2 MAC Address Spoofer
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SystemIdSpooferService.cs
# Lines 619-764: MAC Address Spoofing region

#Requires -RunAsAdministrator

param(
    [string]$AdapterName,
    [string]$CustomMac,
    [switch]$All,
    [switch]$List
)

. "$PSScriptRoot\..\core\SpoofingCore.ps1"
. "$PSScriptRoot\..\core\BackupService.ps1"

function Get-NetworkAdapters {
    <#
    .SYNOPSIS
    Gets all physical network adapters
    .DESCRIPTION
    Based on SystemIdSpooferService.GetNetworkAdapters() lines 621-664
    #>
    $adapters = @()
    
    Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $adapters += @{
            Name = $_.Name
            Description = $_.InterfaceDescription
            CurrentMac = $_.MacAddress
            Status = $_.Status
            AdapterId = $_.InterfaceGuid
        }
    }
    
    return $adapters
}

function Set-MacAddress {
    <#
    .SYNOPSIS
    Sets MAC address for a network adapter
    .DESCRIPTION
    Based on SystemIdSpooferService.SetMacAddress() lines 680-730
    Uses registry modification + adapter restart
    #>
    param(
        [Parameter(Mandatory)]
        [string]$AdapterName,
        [string]$MacAddress
    )
    
    if (-not $MacAddress) {
        $MacAddress = Get-RandomMac
    }
    
    Write-SpooferLog "Setting MAC for $AdapterName to $MacAddress" -Level Info
    
    # Find adapter in registry
    $networkCardsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
    
    $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-SpooferLog "Adapter not found: $AdapterName" -Level Error
        return $false
    }
    
    $found = $false
    Get-ChildItem $networkCardsKey -ErrorAction SilentlyContinue | ForEach-Object {
        $driverDesc = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc
        if ($driverDesc -eq $adapter.InterfaceDescription) {
            # Remove dashes/colons from MAC
            $macNoSep = $MacAddress.Replace("-", "").Replace(":", "")
            
            # Set NetworkAddress in registry
            Set-ItemProperty -Path $_.PSPath -Name "NetworkAddress" -Value $macNoSep -Force
            Write-SpooferLog "Set NetworkAddress to $macNoSep" -Level Info
            $found = $true
        }
    }
    
    if (-not $found) {
        Write-SpooferLog "Could not find registry key for adapter" -Level Error
        return $false
    }
    
    # Restart adapter
    Write-SpooferLog "Restarting adapter..." -Level Info
    Disable-NetAdapter -Name $AdapterName -Confirm:$false
    Start-Sleep -Seconds 2
    Enable-NetAdapter -Name $AdapterName -Confirm:$false
    Start-Sleep -Seconds 3
    
    # Verify
    $newAdapter = Get-NetAdapter -Name $AdapterName
    Write-SpooferLog "New MAC: $($newAdapter.MacAddress)" -Level Success
    
    return $true
}

function Invoke-MacSpoofing {
    <#
    .SYNOPSIS
    Main MAC spoofing function
    #>
    param(
        [string]$TargetAdapter,
        [string]$CustomMac,
        [switch]$AllAdapters
    )
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "       L2 MAC ADDRESS SPOOFER                          " -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Create backup first
    New-SystemIdBackup -Description "Pre-MAC-Spoofing Backup" | Out-Null
    
    $adapters = Get-NetworkAdapters
    
    if ($AllAdapters) {
        foreach ($adapter in $adapters) {
            $newMac = if ($CustomMac) { $CustomMac } else { Get-RandomMac }
            Set-MacAddress -AdapterName $adapter.Name -MacAddress $newMac
        }
    }
    elseif ($TargetAdapter) {
        $newMac = if ($CustomMac) { $CustomMac } else { Get-RandomMac }
        Set-MacAddress -AdapterName $TargetAdapter -MacAddress $newMac
    }
    else {
        # Interactive mode
        Write-Host "Available Network Adapters:" -ForegroundColor Yellow
        Write-Host ""
        
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            Write-Host "  [$($i + 1)] $($adapters[$i].Name)" -ForegroundColor White
            Write-Host "      MAC: $($adapters[$i].CurrentMac)" -ForegroundColor Gray
            Write-Host "      $($adapters[$i].Description)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        $choice = Read-Host "Select adapter number (or 'all' for all adapters)"
        
        if ($choice -eq "all") {
            foreach ($adapter in $adapters) {
                Set-MacAddress -AdapterName $adapter.Name
            }
        }
        else {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $adapters.Count) {
                Set-MacAddress -AdapterName $adapters[$index].Name
            }
            else {
                Write-SpooferLog "Invalid selection" -Level Error
            }
        }
    }
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ MAC Spoofing Complete!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
}

# Main execution
if ($List) {
    Get-NetworkAdapters | Format-Table Name, CurrentMac, Description -AutoSize
}
else {
    Invoke-MacSpoofing -TargetAdapter $AdapterName -CustomMac $CustomMac -AllAdapters:$All
}
