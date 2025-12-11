# Step 3: EFI Signing Script
# Signs the EFI spoofer with the generated certificate

param(
    [string]$SpooferPath = "",
    [string]$KeyName = "my-key"
)

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "EFI Spoofer Signing" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$CertDir = Join-Path $ProjectRoot "02-Certificates"
$SpooferDir = Join-Path $ProjectRoot "01-EFI-Spoofer"

# Locate spoofer file
if ([string]::IsNullOrWhiteSpace($SpooferPath)) {
    $SpooferPath = Join-Path $SpooferDir "amideefix64.efi"
}

$OutputPath = Join-Path $SpooferDir "spoofer-signed.efi"
$KeyFile = Join-Path $CertDir "$KeyName.key"
$CertFile = Join-Path $CertDir "$KeyName.crt"

# Step 1: Validate spoofer exists
Write-Host "[1/7] Validating spoofer file..." -ForegroundColor Yellow
if (-not (Test-Path $SpooferPath)) {
    Write-Host "  ERROR: Spoofer file not found!" -ForegroundColor Red
    Write-Host "  Looking for: $SpooferPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please ensure amideefix64.efi is in 01-EFI-Spoofer folder." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$fileSize = (Get-Item $SpooferPath).Length
Write-Host "  Found: $SpooferPath ($fileSize bytes)" -ForegroundColor Green

# Validate it's a PE file (EFI files are PE format)
$peHeader = Get-Content $SpooferPath -Encoding Byte -TotalCount 2 -ErrorAction SilentlyContinue
if ($peHeader[0] -ne 0x4D -or $peHeader[1] -ne 0x5A) {  # "MZ" signature
    Write-Host "  WARNING: File does not appear to be a valid PE/EFI file" -ForegroundColor Yellow
    $response = Read-Host "  Continue anyway? (yes/no)"
    if ($response -ne "yes") {
        exit 1
    }
} else {
    Write-Host "  Valid PE/EFI file detected" -ForegroundColor Green
}

# Step 2: Check certificate exists
Write-Host "`n[2/7] Checking for certificate..." -ForegroundColor Yellow
if (-not (Test-Path $KeyFile)) {
    Write-Host "  ERROR: Private key not found!" -ForegroundColor Red
    Write-Host "  Looking for: $KeyFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please run Step 2 (generate-cert.ps1) first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if (-not (Test-Path $CertFile)) {
    Write-Host "  ERROR: Certificate not found!" -ForegroundColor Red
    Write-Host "  Looking for: $CertFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please run Step 2 (generate-cert.ps1) first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  Certificate found" -ForegroundColor Green

# Step 3: Check for WSL
Write-Host "`n[3/7] Checking for WSL..." -ForegroundColor Yellow
try {
    $wslCheck = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL not available"
    }
    Write-Host "  WSL detected" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: WSL is not installed or not available" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Install WSL with: wsl --install" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 4: Check for sbsigntool in WSL
Write-Host "`n[4/7] Checking for sbsigntool in WSL..." -ForegroundColor Yellow
$sbsignCheck = wsl bash -c "which sbsign" 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sbsignCheck)) {
    Write-Host "  sbsigntool not found. Installing..." -ForegroundColor Yellow
    wsl bash -c "sudo apt-get update && sudo apt-get install -y sbsigntool" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  sbsigntool installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to install sbsigntool" -ForegroundColor Red
        Write-Host "  Please install manually: sudo apt-get install sbsigntool" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "  sbsigntool found: $sbsignCheck" -ForegroundColor Green
}

# Use current directory approach to avoid encoding issues
# Copy files to a temp location to work around path issues
$TempDir = Join-Path $SpooferDir "temp_sign"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

$TempSpoofer = Join-Path $TempDir "spoofer.efi"
$TempKey = Join-Path $TempDir "key.key"
$TempCert = Join-Path $TempDir "cert.crt"
$TempOutput = Join-Path $TempDir "spoofer-signed.efi"

Copy-Item $SpooferPath $TempSpoofer -Force
Copy-Item $KeyFile $TempKey -Force
Copy-Item $CertFile $TempCert -Force

Set-Location $TempDir

# Step 5: Sign the EFI file
Write-Host "`n[5/7] Signing EFI file..." -ForegroundColor Yellow
Write-Host "  This may take a moment..." -ForegroundColor Gray

$signOutput = wsl sbsign --key "key.key" --cert "cert.crt" --output "spoofer-signed.efi" "spoofer.efi" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  EFI file signed successfully!" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to sign EFI file" -ForegroundColor Red
    Write-Host "  Output: $signOutput" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 6: Verify the signature
Write-Host "`n[6/7] Verifying signature..." -ForegroundColor Yellow

$verifyOutput = wsl sbverify --cert "cert.crt" "spoofer-signed.efi" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Signature verified successfully!" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Signature verification failed" -ForegroundColor Yellow
    Write-Host "  Output: $verifyOutput" -ForegroundColor Yellow
    Write-Host "  The file may still work, but signature is not valid" -ForegroundColor Yellow
}

# Step 7: Copy signed file back and cleanup
Write-Host "`n[7/7] Final checks..." -ForegroundColor Yellow

if (Test-Path $TempOutput) {
    Copy-Item $TempOutput $OutputPath -Force
    Write-Host "  Copied signed file to output location" -ForegroundColor Gray
}

# Cleanup temp directory
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Set-Location $ScriptDir

if (Test-Path $OutputPath) {
    $outputSize = (Get-Item $OutputPath).Length
    Write-Host "  Signed file created: $OutputPath" -ForegroundColor Green
    Write-Host "  Size: $outputSize bytes (original: $fileSize bytes)" -ForegroundColor Gray
    
    # Compare sizes (signed should be larger)
    if ($outputSize -le $fileSize) {
        Write-Host "  WARNING: Signed file is not larger than original" -ForegroundColor Yellow
        Write-Host "  This might indicate signing didn't work properly" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR: Signed file not created" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "Signing Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Signed file location:" -ForegroundColor White
Write-Host "  $OutputPath" -ForegroundColor White
Write-Host ""
Write-Host "Next step: Create bootable USB (Step 4)" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


