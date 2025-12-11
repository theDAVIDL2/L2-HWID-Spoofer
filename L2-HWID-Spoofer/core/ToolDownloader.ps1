# L2 HWID Spoofer - Tool Downloader
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SpoofingToolsDownloadService.cs
# Downloads and manages required spoofing tools

#Requires -RunAsAdministrator

. "$PSScriptRoot\..\core\SpoofingCore.ps1"

$script:ToolsDirectory = Join-Path $env:LOCALAPPDATA "L2Spoofer\Tools"

# Tool definitions - Same as L2 Setup tools-config.json
$script:Tools = @{
    "VolumeID" = @{
        Name = "VolumeID"
        FileName = "Volumeid.exe"
        DownloadUrl = "https://drive.google.com/uc?export=download&id=13LXCBltHIQheRIq1DlNndPvDWioVETJj"
        ExpectedSha256 = "22a2484d7fa799e6e71e310141614884f3bc8dad8ac749b6f1c475b5398a72f3"
        Description = "Sysinternals tool for changing volume serial numbers"
        IsZipArchive = $true
        FolderName = "VolumeID"
    }
    "MonitorSpoofer" = @{
        Name = "Monitor Spoofer"
        FileName = "MonitorSpoofer.exe"
        DownloadUrl = "https://drive.google.com/uc?export=download&id=1B2nVPTBPrM0yrI-jAnIDi0wyR_PzAZGC"
        Description = "Tool for spoofing monitor serial numbers and EDIDs"
        IsZipArchive = $true
        FolderName = "MonitorSpoofer"
    }
    "AFUWIN" = @{
        Name = "AFUWIN"
        FileName = "AFUWINx64.EXE"
        DownloadUrl = "https://drive.google.com/uc?export=download&id=1G2r5NOSss822yLKKUHN0Ua2YBY3C2F24"
        ExpectedSha256 = "2f5bacd0ecbfc34f41568adaccfe1457c84585baac3bd5f8a5a2a5363c1f7b1e"
        Description = "AMI Firmware Update utility for BIOS flashing"
        IsZipArchive = $true
        FolderName = "AFUWIN"
    }
    "DMIEdit" = @{
        Name = "DMIEdit"
        FileName = "DMIEDIT.EXE"
        DownloadUrl = "https://drive.google.com/uc?export=download&id=1-Tatx33EZf7WNzvH7geBLy-3l4At4y3m"
        ExpectedSha256 = "5d37e5e7ce01549965bf2166adcba33d1e2c4bd2c90711032f3987b58452ce49"
        Description = "SMBIOS editing tool for system information modification"
        IsZipArchive = $true
        FolderName = "DMIEdit"
    }
    "MaxioTool" = @{
        Name = "MaxioTool"
        FileName = "MXMPTool_MAP1202_USB_V0_01_009d.exe"
        DownloadUrl = "https://drive.google.com/uc?export=download&id=1r2fIQwK9o1SDxAQc9pb8cnJ-SxDu-UV4"
        ExpectedSha256 = "808dffe9a868f575391930095c3c4717db194fd316f5d0c53ca536860ca19839"
        Description = "Maxio MAP1202 SSD controller flashing tool"
        IsZipArchive = $true
        FolderName = "MaxioTool"
    }
    "CrystalDiskInfo" = @{
        Name = "CrystalDiskInfo"
        FileName = "DiskInfo64.exe"
        DownloadUrl = "https://drive.google.com/uc?export=download&id=1tpIU8uFJhreuOMZkOY15yhuEA6-WocYm"
        ExpectedSha256 = "8b6489d484003e5ef21382413a77b87a1e1e420001f2ffff0d5eb289d25a48ec"
        Description = "Disk information and health monitoring tool"
        IsZipArchive = $true
        FolderName = "CrystalDiskInfo"
    }
    "HxD" = @{
        Name = "HxD Hex Editor"
        FileName = "HxDSetup.exe"
        DownloadUrl = "https://mh-nexus.de/downloads/HxDSetup.zip"
        ExpectedSha256 = "dccfa4b16aa79e273cc7ffc35493c495a7fd09f92a4b790f2dc41c65f64d5378"
        Description = "Hex editor for advanced manual BIOS editing"
        IsZipArchive = $true
        FolderName = "HxD"
        IsInstaller = $true
        SilentInstallArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
        InstalledPath = "$env:ProgramFiles\HxD\HxD.exe"
    }
}

function Initialize-ToolsDirectory {
    if (-not (Test-Path $script:ToolsDirectory)) {
        New-Item -ItemType Directory -Path $script:ToolsDirectory -Force | Out-Null
        Write-SpooferLog "Created tools directory: $script:ToolsDirectory" -Level Info
    }
}

function Get-ToolPath {
    param([string]$ToolName)
    
    $tool = $script:Tools[$ToolName]
    if (-not $tool) {
        return Join-Path $script:ToolsDirectory $ToolName
    }
    
    if ($tool.FolderName) {
        return Join-Path $script:ToolsDirectory $tool.FolderName $tool.FileName
    }
    return Join-Path $script:ToolsDirectory $tool.FileName
}

function Test-ToolDownloaded {
    param([string]$ToolName)
    
    $toolPath = Get-ToolPath -ToolName $ToolName
    return Test-Path $toolPath
}

function Get-AllToolsStatus {
    $status = @()
    foreach ($key in $script:Tools.Keys) {
        $tool = $script:Tools[$key]
        $isDownloaded = Test-ToolDownloaded -ToolName $key
        $status += @{
            Name = $tool.Name
            Key = $key
            Downloaded = $isDownloaded
            Description = $tool.Description
            Path = Get-ToolPath -ToolName $key
        }
    }
    return $status
}

function Install-SpoofingTool {
    <#
    .SYNOPSIS
    Downloads and installs a spoofing tool
    .DESCRIPTION
    Based on SpoofingToolsDownloadService.DownloadTool()
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )
    
    Initialize-ToolsDirectory
    
    $tool = $script:Tools[$ToolName]
    if (-not $tool) {
        Write-SpooferLog "Unknown tool: $ToolName" -Level Error
        return $false
    }
    
    # Check if already exists
    $toolPath = Get-ToolPath -ToolName $ToolName
    if (Test-Path $toolPath) {
        Write-SpooferLog "$($tool.Name) already downloaded" -Level Success
        return $true
    }
    
    Write-SpooferLog "Downloading $($tool.Name)..." -Level Info
    
    try {
        $tempFile = Join-Path $env:TEMP "$ToolName-$(Get-Random).tmp"
        
        # Download
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "L2Spoofer/1.0")
        $webClient.DownloadFile($tool.DownloadUrl, $tempFile)
        
        Write-SpooferLog "Download complete" -Level Success
        
        # Handle ZIP archives
        if ($tool.IsZipArchive) {
            Write-SpooferLog "Extracting archive..." -Level Info
            
            $extractPath = Join-Path $script:ToolsDirectory $tool.FolderName
            if (-not (Test-Path $extractPath)) {
                New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
            }
            
            Expand-Archive -Path $tempFile -DestinationPath $extractPath -Force
            
            Write-SpooferLog "Extracted to $extractPath" -Level Success
        }
        else {
            # Direct file
            $destDir = Split-Path $toolPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Move-Item $tempFile $toolPath -Force
        }
        
        # Cleanup
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        
        # Verify
        if (Test-Path $toolPath) {
            Write-SpooferLog "$($tool.Name) installed successfully!" -Level Success
            return $true
        }
        else {
            Write-SpooferLog "Installation failed - file not found at expected path" -Level Error
            return $false
        }
    }
    catch {
        Write-SpooferLog "Download failed: $_" -Level Error
        return $false
    }
}

function Install-AllTools {
    <#
    .SYNOPSIS
    Downloads all required spoofing tools
    #>
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  L2 HWID SPOOFER - TOOL INSTALLER" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $toolsNeeded = @("VolumeID", "MonitorSpoofer")
    $allSuccess = $true
    
    foreach ($tool in $toolsNeeded) {
        $result = Install-SpoofingTool -ToolName $tool
        if (-not $result) {
            $allSuccess = $false
        }
    }
    
    Write-Host ""
    if ($allSuccess) {
        Write-SpooferLog "All tools installed successfully!" -Level Success
    }
    else {
        Write-SpooferLog "Some tools failed to install" -Level Warning
    }
    
    return $allSuccess
}

function Show-ToolsStatus {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  INSTALLED TOOLS STATUS" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $status = Get-AllToolsStatus
    
    foreach ($tool in $status) {
        $icon = if ($tool.Downloaded) { "✅" } else { "❌" }
        $statusText = if ($tool.Downloaded) { "Installed" } else { "Not installed" }
        
        Write-Host "  $icon $($tool.Name)" -ForegroundColor $(if ($tool.Downloaded) { "Green" } else { "Red" })
        Write-Host "     Status: $statusText" -ForegroundColor Gray
        Write-Host "     Description: $($tool.Description)" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Open-ToolsDirectory {
    Initialize-ToolsDirectory
    Start-Process explorer.exe -ArgumentList $script:ToolsDirectory
}

# Export functions
Export-ModuleMember -Function *
