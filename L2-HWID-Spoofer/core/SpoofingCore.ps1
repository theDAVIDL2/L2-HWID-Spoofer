# L2 Spoofing Core Module
# Based on: L2 SETUP/src/WindowsSetup.App/Services/SystemIdSpooferService.cs
# This module provides core functions used by all spoofing methods

#Requires -RunAsAdministrator

$script:BackupDirectory = Join-Path $env:LOCALAPPDATA "L2Spoofer\Backups"
$script:LogFile = Join-Path $env:LOCALAPPDATA "L2Spoofer\spoofing.log"

# Ensure directories exist
if (-not (Test-Path $script:BackupDirectory)) {
    New-Item -ItemType Directory -Path $script:BackupDirectory -Force | Out-Null
}

function Write-SpooferLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        "Info"    { Write-Host "   $Message" -ForegroundColor Cyan }
        "Success" { Write-Host "✅ $Message" -ForegroundColor Green }
        "Warning" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "❌ $Message" -ForegroundColor Red }
    }
    
    # File output
    Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Get-RandomHexString {
    param([int]$Length = 16)
    
    $bytes = New-Object byte[] ($Length / 2)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString("X2") }) -join ""
}

function Get-RandomMac {
    <#
    .SYNOPSIS
    Generates a random locally-administered MAC address
    #>
    $bytes = New-Object byte[] 6
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    
    # Set locally administered bit (bit 1 of first byte)
    # Clear multicast bit (bit 0 of first byte)
    $bytes[0] = ($bytes[0] -bor 0x02) -band 0xFE
    
    return ($bytes | ForEach-Object { $_.ToString("X2") }) -join "-"
}

function Get-RandomGuid {
    return [guid]::NewGuid().ToString()
}

function Get-RandomVolumeSerial {
    $random = Get-Random -Minimum 0x10000000 -Maximum 0x7FFFFFFF
    $hex = $random.ToString("X8")
    return "$($hex.Substring(0,4))-$($hex.Substring(4,4))"
}

function Test-AdminPrivileges {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($value) {
            return $value.$Name
        }
    }
    catch {
        return $null
    }
    return $null
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "String"
    )
    
    try {
        # Create path if it doesn't exist
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        return $true
    }
    catch {
        Write-SpooferLog "Failed to set registry value: $_" -Level Error
        return $false
    }
}

# Export functions for use by other modules
Export-ModuleMember -Function *
