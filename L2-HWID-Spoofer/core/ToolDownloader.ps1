# L2 HWID Spoofer - Tool Downloader
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SpoofingToolsDownloadService.cs
# Downloads and manages required spoofing tools

#Requires -RunAsAdministrator

. "$PSScriptRoot\..\core\SpoofingCore.ps1"

$script:ToolsDirectory = Join-Path $env:LOCALAPPDATA "L2Spoofer\Tools"

# Tool definitions
$script:Tools = @{
    "VolumeID" = @{
        Name = "VolumeID"
        FileName = "Volumeid.exe"
        DownloadUrl = "https://download.sysinternals.com/files/VolumeId.zip"
        Description = "Microsoft Sysinternals Volume Serial Changer"
        IsZipArchive = $true
        FolderName = "VolumeID"
    }
    "CRU" = @{
        Name = "Custom Resolution Utility"
        FileName = "CRU.exe"
        DownloadUrl = "https://www.monitortests.com/download/cru/cru-1.5.2.zip"
        Description = "Monitor EDID Editor by ToastyX"
        IsZipArchive = $true
        FolderName = "CRU"
    }
    "restart64" = @{
        Name = "Restart64"
        FileName = "restart64.exe"
        DownloadUrl = "https://www.monitortests.com/download/cru/cru-1.5.2.zip"
        Description = "Graphics Driver Restart Utility"
        IsZipArchive = $true
        FolderName = "CRU"
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
    
    $toolsNeeded = @("VolumeID", "CRU")
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
