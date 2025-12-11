# Integration Script - Use Vision's Legal Tools
# This script integrates Vision's freeware tools into your spoofer
# NO reverse engineering needed!

<#
.SYNOPSIS
Integration layer for Vision's legal tools (CRU, Serial Checker)

.DESCRIPTION
Uses Vision's bundled tools that are either freeware or simple scripts:
- CRU.exe (Freeware by ToastyX)
- Backup Serial Checker.bat (PowerShell script)
- restart64.exe (Driver restart utility)

Your own hypervisor technology remains superior!
#>

$VisionPath = "$PSScriptRoot\Vision"

# Enhanced Hardware Fingerprint Checker (Better than Vision's!)
function Get-HardwareFingerprint {
    <#
    .SYNOPSIS
    Check current hardware fingerprint (Enhanced version of Vision's Serial Checker)
    
    .PARAMETER SaveToFile
    Save results to file for comparison
    
    .PARAMETER Compare
    Compare with previous fingerprint file
    #>
    
    param(
        [string]$SaveToFile,
        [string]$Compare
    )
    
    $results = @{}
    
    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     HARDWARE FINGERPRINT CHECKER (Enhanced)         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Disk Serials
    Write-Host "`n[+] Disk Serials:" -ForegroundColor Yellow
    $diskSerials = @()
    Get-PhysicalDisk | ForEach-Object {
        $info = "Model: $($_.FriendlyName) - Serial: $($_.SerialNumber)"
        Write-Host "    $info"
        $diskSerials += $info
    }
    $results['Disks'] = $diskSerials
    
    # CPU
    Write-Host "`n[+] CPU:" -ForegroundColor Yellow
    $cpuInfo = @()
    Get-CimInstance Win32_Processor | ForEach-Object {
        $info = "Name: $($_.Name) - ID: $($_.ProcessorId)"
        Write-Host "    $info"
        $cpuInfo += $info
    }
    $results['CPU'] = $cpuInfo
    
    # Motherboard
    Write-Host "`n[+] Motherboard:" -ForegroundColor Yellow
    $boardInfo = @()
    Get-CimInstance Win32_BaseBoard | ForEach-Object {
        $info = "Manufacturer: $($_.Manufacturer) - Serial: $($_.SerialNumber)"
        Write-Host "    $info"
        $boardInfo += $info
    }
    $results['Motherboard'] = $boardInfo
    
    # BIOS
    Write-Host "`n[+] BIOS:" -ForegroundColor Yellow
    $biosInfo = @()
    Get-CimInstance Win32_BIOS | ForEach-Object {
        $info = "Manufacturer: $($_.Manufacturer) - Serial: $($_.SerialNumber)"
        Write-Host "    $info"
        $biosInfo += $info
    }
    $results['BIOS'] = $biosInfo
    
    # SMBIOS
    Write-Host "`n[+] SMBIOS:" -ForegroundColor Yellow
    $smbiosInfo = @()
    Get-CimInstance Win32_ComputerSystemProduct | ForEach-Object {
        $info = "Name: $($_.Name) - UUID: $($_.UUID)"
        Write-Host "    $info"
        $smbiosInfo += $info
    }
    $results['SMBIOS'] = $smbiosInfo
    
    # MAC Addresses
    Write-Host "`n[+] Network (MAC Addresses):" -ForegroundColor Yellow
    $macInfo = @()
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        $info = "Name: $($_.Name) - MAC: $($_.MacAddress)"
        Write-Host "    $info"
        $macInfo += $info
    }
    $results['Network'] = $macInfo
    
    # Monitor EDID (Your Addition - Vision doesn't show this!)
    Write-Host "`n[+] Monitors (EDID):" -ForegroundColor Yellow
    $monitorInfo = @()
    try {
        $displays = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters" -Name EDID -ErrorAction SilentlyContinue
        foreach ($display in $displays) {
            if ($display.EDID) {
                $edid = $display.EDID
                $serial = [BitConverter]::ToUInt32($edid, 12)
                $info = "Monitor Serial: 0x$($serial.ToString('X8'))"
                Write-Host "    $info" -ForegroundColor Green
                $monitorInfo += $info
            }
        }
    } catch {
        Write-Host "    Unable to read monitor EDID" -ForegroundColor Red
    }
    $results['Monitors'] = $monitorInfo
    
    # GPU (Your Addition)
    Write-Host "`n[+] Graphics Cards:" -ForegroundColor Yellow
    $gpuInfo = @()
    Get-CimInstance Win32_VideoController | ForEach-Object {
        $info = "Name: $($_.Name) - PNPDeviceID: $($_.PNPDeviceID)"
        Write-Host "    $info"
        $gpuInfo += $info
    }
    $results['GPU'] = $gpuInfo
    
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Save to file if requested
    if ($SaveToFile) {
        $results | ConvertTo-Json | Out-File $SaveToFile
        Write-Host "`n✓ Fingerprint saved to: $SaveToFile" -ForegroundColor Green
    }
    
    # Compare with previous if requested
    if ($Compare -and (Test-Path $Compare)) {
        Write-Host "`n[COMPARISON] Checking changes from: $Compare" -ForegroundColor Magenta
        $previous = Get-Content $Compare | ConvertFrom-Json
        
        foreach ($key in $results.Keys) {
            $current = $results[$key] -join "`n"
            $prev = $previous.$key -join "`n"
            
            if ($current -ne $prev) {
                Write-Host "`n  ⚠️  $key CHANGED!" -ForegroundColor Yellow
                Write-Host "  Before: $prev" -ForegroundColor Red
                Write-Host "  After : $current" -ForegroundColor Green
            } else {
                Write-Host "`n  ✓ $key unchanged" -ForegroundColor Gray
            }
        }
    }
    
    return $results
}

# Use Vision's CRU (Custom Resolution Utility) for Monitor Spoofing
function Invoke-CRU {
    <#
    .SYNOPSIS
    Launch CRU (Custom Resolution Utility) from Vision's tools
    
    .DESCRIPTION
    CRU is freeware by ToastyX - legal to use!
    This is the tool Vision uses for monitor EDID spoofing
    #>
    
    $cruPath = "$VisionPath\Monitor Spoof\CRU.exe"
    
    if (!(Test-Path $cruPath)) {
        Write-Host "✗ CRU.exe not found at: $cruPath" -ForegroundColor Red
        Write-Host "  Vision tools may not be properly extracted" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n[CRU] Launching Custom Resolution Utility..." -ForegroundColor Cyan
    Write-Host "  This is Vision's tool for monitor EDID editing" -ForegroundColor Gray
    Write-Host "  (Freeware by ToastyX - legal to use!)" -ForegroundColor Gray
    
    & $cruPath
    
    Write-Host "`n[INFO] After editing EDID in CRU:" -ForegroundColor Yellow
    Write-Host "  1. Save your changes" -ForegroundColor White
    Write-Host "  2. Run Restart-GraphicsDriver to apply" -ForegroundColor White
}

# Restart Graphics Driver (Vision uses restart64.exe)
function Restart-GraphicsDriver {
    <#
    .SYNOPSIS
    Restart graphics driver to apply EDID changes
    
    .DESCRIPTION
    Vision uses restart64.exe - we can use it or our own implementation
    #>
    
    param([switch]$UseVisionTool)
    
    if ($UseVisionTool) {
        $restartPath = "$VisionPath\Monitor Spoof\restart64.exe"
        if (Test-Path $restartPath) {
            Write-Host "[Graphics Driver] Using Vision's restart64.exe..." -ForegroundColor Cyan
            & $restartPath
            return
        } else {
            Write-Host "⚠️  restart64.exe not found, using PowerShell method" -ForegroundColor Yellow
        }
    }
    
    Write-Host "[Graphics Driver] Restarting using PowerShell..." -ForegroundColor Cyan
    
    $adapters = Get-PnpDevice -Class Display | Where-Object {$_.Status -eq 'OK'}
    
    if ($adapters.Count -eq 0) {
        Write-Host "✗ No display adapters found" -ForegroundColor Red
        return
    }
    
    foreach ($adapter in $adapters) {
        Write-Host "  Restarting: $($adapter.FriendlyName)" -ForegroundColor Yellow
        
        try {
            Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction Stop
            Write-Host "  ✓ $($adapter.FriendlyName) restarted" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to restart $($adapter.FriendlyName): $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`n✓ Graphics driver restart complete" -ForegroundColor Green
}

# Spoof MAC Address (Vision has Realtek.exe - we build our own!)
function Set-MacAddress {
    <#
    .SYNOPSIS
    Spoof MAC address (Your own implementation - better than Vision!)
    
    .PARAMETER AdapterName
    Name of network adapter (use Get-NetAdapter to find)
    
    .PARAMETER NewMac
    New MAC address (format: 0A1B2C3D4E5F)
    
    .PARAMETER Random
    Generate random MAC address
    #>
    
    param(
        [string]$AdapterName,
        [string]$NewMac,
        [switch]$Random
    )
    
    Write-Host "`n[MAC Spoofer] Starting..." -ForegroundColor Cyan
    
    # Generate random MAC if requested
    if ($Random) {
        $NewMac = -join ((0..5) | ForEach-Object { "{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255) })
        Write-Host "  Generated random MAC: $NewMac" -ForegroundColor Yellow
    }
    
    if (!$NewMac) {
        Write-Host "✗ No MAC address specified" -ForegroundColor Red
        return
    }
    
    # Remove any separators
    $NewMac = $NewMac -replace '[:-]', ''
    
    if ($NewMac.Length -ne 12) {
        Write-Host "✗ Invalid MAC address format (must be 12 hex digits)" -ForegroundColor Red
        return
    }
    
    # Get adapters
    $adapters = Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'}
    
    if ($AdapterName) {
        $adapters = $adapters | Where-Object {$_.Name -eq $AdapterName}
    }
    
    if ($adapters.Count -eq 0) {
        Write-Host "✗ No matching network adapters found" -ForegroundColor Red
        return
    }
    
    foreach ($adapter in $adapters) {
        Write-Host "`n  Processing: $($adapter.Name)" -ForegroundColor Yellow
        Write-Host "    Current MAC: $($adapter.MacAddress)" -ForegroundColor Gray
        
        # Find adapter in registry
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
        $adapterKeys = Get-ChildItem $regPath
        
        $found = $false
        foreach ($key in $adapterKeys) {
            try {
                $props = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
                if ($props.DriverDesc -eq $adapter.InterfaceDescription) {
                    Set-ItemProperty -Path $key.PSPath -Name "NetworkAddress" -Value $NewMac
                    Write-Host "    ✓ Registry updated: $NewMac" -ForegroundColor Green
                    $found = $true
                    break
                }
            } catch {
                continue
            }
        }
        
        if (!$found) {
            Write-Host "    ✗ Could not find registry entry" -ForegroundColor Red
            continue
        }
        
        # Restart adapter
        Write-Host "    Restarting adapter..." -ForegroundColor Yellow
        Restart-NetAdapter -Name $adapter.Name -Confirm:$false
        
        Start-Sleep -Seconds 3
        
        # Verify
        $newAdapter = Get-NetAdapter -Name $adapter.Name
        Write-Host "    New MAC: $($newAdapter.MacAddress)" -ForegroundColor Green
    }
    
    Write-Host "`n✓ MAC address spoofing complete!" -ForegroundColor Green
}

# Compare Before/After Spoofing
function Compare-Fingerprints {
    <#
    .SYNOPSIS
    Compare hardware fingerprints before and after spoofing
    
    .PARAMETER BeforeFile
    Fingerprint file captured before spoofing
    
    .PARAMETER AfterFile
    Fingerprint file captured after spoofing
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$BeforeFile,
        
        [Parameter(Mandatory)]
        [string]$AfterFile
    )
    
    if (!(Test-Path $BeforeFile)) {
        Write-Host "✗ Before file not found: $BeforeFile" -ForegroundColor Red
        return
    }
    
    if (!(Test-Path $AfterFile)) {
        Write-Host "✗ After file not found: $AfterFile" -ForegroundColor Red
        return
    }
    
    $before = Get-Content $BeforeFile | ConvertFrom-Json
    $after = Get-Content $AfterFile | ConvertFrom-Json
    
    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        HARDWARE FINGERPRINT COMPARISON              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $changeCount = 0
    
    foreach ($key in $before.PSObject.Properties.Name) {
        $beforeValue = $before.$key -join ", "
        $afterValue = $after.$key -join ", "
        
        Write-Host "`n[$key]" -ForegroundColor Yellow
        
        if ($beforeValue -ne $afterValue) {
            Write-Host "  ⚠️  CHANGED!" -ForegroundColor Red
            Write-Host "  Before: $beforeValue" -ForegroundColor Gray
            Write-Host "  After:  $afterValue" -ForegroundColor Green
            $changeCount++
        } else {
            Write-Host "  ✓ Unchanged: $beforeValue" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Total Changes: $changeCount" -ForegroundColor $(if($changeCount -gt 0){'Green'}else{'Yellow'})
    
    if ($changeCount -eq 0) {
        Write-Host "`n⚠️  WARNING: No changes detected!" -ForegroundColor Yellow
        Write-Host "Your spoofing may not be working properly." -ForegroundColor Yellow
    } else {
        Write-Host "`n✓ Hardware fingerprint successfully modified!" -ForegroundColor Green
    }
}

# Main Integration Menu
function Show-VisionToolsMenu {
    <#
    .SYNOPSIS
    Interactive menu for using Vision's tools + your own implementations
    #>
    
    while ($true) {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║     VISION TOOLS INTEGRATION (Legal Tools Only)     ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Your Hypervisor Technology:" -ForegroundColor Yellow
        Write-Host "  ✓ Already superior to Vision.exe" -ForegroundColor Green
        Write-Host "  ✓ No need to reverse engineer!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Vision's Legal Tools We Can Use:" -ForegroundColor Yellow
        Write-Host "  1. Check Hardware Fingerprint (Enhanced version)" -ForegroundColor White
        Write-Host "  2. Launch CRU (Monitor EDID Editor)" -ForegroundColor White
        Write-Host "  3. Restart Graphics Driver" -ForegroundColor White
        Write-Host "  4. Spoof MAC Address (Your own implementation!)" -ForegroundColor White
        Write-Host "  5. Compare Before/After Fingerprints" -ForegroundColor White
        Write-Host ""
        Write-Host "Workflow:" -ForegroundColor Yellow
        Write-Host "  6. Full Spoof Workflow (Guided)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  0. Exit" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            "1" {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $filename = "fingerprint_$timestamp.json"
                Get-HardwareFingerprint -SaveToFile $filename
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" {
                Invoke-CRU
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                $useVision = Read-Host "Use Vision's restart64.exe? (y/n)"
                Restart-GraphicsDriver -UseVisionTool:($useVision -eq 'y')
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                Write-Host "`nAvailable adapters:" -ForegroundColor Yellow
                Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | 
                    Format-Table Name, InterfaceDescription, MacAddress -AutoSize
                
                $adapterName = Read-Host "Enter adapter name (or press Enter for all)"
                $randomChoice = Read-Host "Generate random MAC? (y/n)"
                
                if ($randomChoice -eq 'y') {
                    Set-MacAddress -AdapterName $adapterName -Random
                } else {
                    $newMac = Read-Host "Enter new MAC address (format: 0A1B2C3D4E5F)"
                    Set-MacAddress -AdapterName $adapterName -NewMac $newMac
                }
                
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                $before = Read-Host "Enter 'before' fingerprint file"
                $after = Read-Host "Enter 'after' fingerprint file"
                Compare-Fingerprints -BeforeFile $before -AfterFile $after
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                # Full workflow
                Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║          FULL SPOOFING WORKFLOW (Guided)            ║" -ForegroundColor Cyan
                Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
                
                # Step 1: Capture before
                Write-Host "`n[Step 1] Capturing current fingerprint..." -ForegroundColor Yellow
                $beforeFile = "fingerprint_before_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                Get-HardwareFingerprint -SaveToFile $beforeFile
                
                # Step 2: Monitor spoofing
                Write-Host "`n[Step 2] Monitor EDID Spoofing" -ForegroundColor Yellow
                $doMonitor = Read-Host "Spoof monitor EDID? (y/n)"
                if ($doMonitor -eq 'y') {
                    Write-Host "  Launching CRU..." -ForegroundColor Cyan
                    Write-Host "  1. Edit monitor serial number" -ForegroundColor White
                    Write-Host "  2. Save and close CRU" -ForegroundColor White
                    Write-Host "  3. Press Enter here when done" -ForegroundColor White
                    Invoke-CRU
                    Read-Host "Press Enter after editing CRU"
                    Restart-GraphicsDriver
                }
                
                # Step 3: MAC spoofing
                Write-Host "`n[Step 3] MAC Address Spoofing" -ForegroundColor Yellow
                $doMac = Read-Host "Spoof MAC address? (y/n)"
                if ($doMac -eq 'y') {
                    Set-MacAddress -Random
                }
                
                # Step 4: Capture after
                Write-Host "`n[Step 4] Capturing new fingerprint..." -ForegroundColor Yellow
                $afterFile = "fingerprint_after_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                Get-HardwareFingerprint -SaveToFile $afterFile
                
                # Step 5: Compare
                Write-Host "`n[Step 5] Comparing results..." -ForegroundColor Yellow
                Compare-Fingerprints -BeforeFile $beforeFile -AfterFile $afterFile
                
                Write-Host "`n✓ Workflow complete!" -ForegroundColor Green
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                return
            }
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-HardwareFingerprint',
    'Invoke-CRU',
    'Restart-GraphicsDriver',
    'Set-MacAddress',
    'Compare-Fingerprints',
    'Show-VisionToolsMenu'
)

# If run directly, show menu
if ($MyInvocation.InvocationName -ne '.') {
    Show-VisionToolsMenu
}

