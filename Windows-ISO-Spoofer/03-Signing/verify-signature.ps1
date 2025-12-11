# Step 3: Signature Verification Script
# Verifies the signature of a signed EFI file

param(
    [string]$EfiPath = "",
    [string]$KeyName = "my-key"
)

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "EFI Signature Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$CertDir = Join-Path $ProjectRoot "02-Certificates"
$SpooferDir = Join-Path $ProjectRoot "01-EFI-Spoofer"

# Locate EFI file
if ([string]::IsNullOrWhiteSpace($EfiPath)) {
    $EfiPath = Join-Path $SpooferDir "spoofer-signed.efi"
}

$CertFile = Join-Path $CertDir "$KeyName.crt"

# Step 1: Validate EFI file exists
Write-Host "[1/5] Checking EFI file..." -ForegroundColor Yellow
if (-not (Test-Path $EfiPath)) {
    Write-Host "  ERROR: EFI file not found!" -ForegroundColor Red
    Write-Host "  Looking for: $EfiPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please run sign-spoofer.ps1 first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$fileSize = (Get-Item $EfiPath).Length
Write-Host "  Found: $EfiPath ($fileSize bytes)" -ForegroundColor Green

# Step 2: Check for WSL
Write-Host "`n[2/5] Checking for WSL..." -ForegroundColor Yellow
try {
    $wslCheck = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL not available"
    }
    Write-Host "  WSL detected" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: WSL is not installed or not available" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 3: Check for sbsigntool in WSL
Write-Host "`n[3/5] Checking for sbsigntool..." -ForegroundColor Yellow
$sbverifyCheck = wsl bash -c "which sbverify" 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sbverifyCheck)) {
    Write-Host "  sbsigntool not found. Installing..." -ForegroundColor Yellow
    wsl bash -c "sudo apt-get update && sudo apt-get install -y sbsigntool" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Failed to install sbsigntool" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    Write-Host "  sbsigntool installed" -ForegroundColor Green
} else {
    Write-Host "  sbsigntool found" -ForegroundColor Green
}

# Use current directory approach to avoid encoding issues
$TempDir = Join-Path $env:TEMP "efi_verify_temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

$TempEfi = Join-Path $TempDir "file.efi"
$TempCert = Join-Path $TempDir "cert.crt"

Copy-Item $EfiPath $TempEfi -Force
if (Test-Path $CertFile) {
    Copy-Item $CertFile $TempCert -Force
}

Set-Location $TempDir

# Step 4: Check if file has a signature
Write-Host "`n[4/5] Checking for PKCS#7 signature..." -ForegroundColor Yellow

# Use pesign or sbverify to check signature
$listOutput = wsl sbverify --list "file.efi" 2>&1

if ($listOutput -match "signature") {
    Write-Host "  Signature found in EFI file" -ForegroundColor Green
    Write-Host "  $listOutput" -ForegroundColor Gray
} else {
    Write-Host "  No signature detected" -ForegroundColor Yellow
    Write-Host "  This file may not be signed" -ForegroundColor Yellow
}

# Step 5: Verify signature with certificate
Write-Host "`n[5/5] Verifying signature against certificate..." -ForegroundColor Yellow

if (Test-Path $TempCert) {
    $verifyOutput = wsl sbverify --cert "cert.crt" "file.efi" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Signature is VALID!" -ForegroundColor Green
        Write-Host "  Certificate: $CertFile" -ForegroundColor Gray
    } else {
        Write-Host "  Signature verification FAILED" -ForegroundColor Red
        Write-Host "  Output: $verifyOutput" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Certificate not found, skipping verification" -ForegroundColor Yellow
    Write-Host "  Looking for: $CertFile" -ForegroundColor Yellow
}

# Additional info
Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "Verification Complete" -ForegroundColor Cyan
Write-Host ""
Write-Host "EFI File: $EfiPath" -ForegroundColor White
Write-Host "Size: $fileSize bytes" -ForegroundColor White

# Check if pesign is available for more details
$pesignCheck = wsl bash -c "which pesign" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDetailed signature info:" -ForegroundColor White
    $pesignInfo = wsl pesign -S -i "file.efi" 2>&1
    Write-Host $pesignInfo -ForegroundColor Gray
}

# Cleanup
Set-Location $ScriptDir
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


