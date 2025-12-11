# Step 2: Certificate Generation Script
# Generates a self-signed certificate for EFI signing

param(
    [string]$KeyName = "my-key",
    [int]$ValidYears = 10
)

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Certificate Generation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KeyFile = Join-Path $ScriptDir "$KeyName.key"
$CertFile = Join-Path $ScriptDir "$KeyName.crt"
$DerFile = Join-Path $ScriptDir "$KeyName.cer"

# Check if certificate already exists
if ((Test-Path $KeyFile) -and (Test-Path $CertFile)) {
    Write-Host "WARNING: Certificate already exists!" -ForegroundColor Yellow
    Write-Host "  Key:  $KeyFile" -ForegroundColor Yellow
    Write-Host "  Cert: $CertFile" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Do you want to regenerate? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "Keeping existing certificate." -ForegroundColor Green
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

# Step 1: Check for WSL
Write-Host "[1/6] Checking for WSL..." -ForegroundColor Yellow
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
    Write-Host "  Then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 2: Check for OpenSSL in WSL
Write-Host "`n[2/6] Checking for OpenSSL in WSL..." -ForegroundColor Yellow
$opensslCheck = wsl bash -c "which openssl" 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($opensslCheck)) {
    Write-Host "  OpenSSL not found. Installing..." -ForegroundColor Yellow
    wsl bash -c "sudo apt-get update && sudo apt-get install -y openssl" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OpenSSL installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to install OpenSSL" -ForegroundColor Red
        Write-Host "  Please install manually: sudo apt-get install openssl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "  OpenSSL found: $opensslCheck" -ForegroundColor Green
}

# Use current directory approach to avoid encoding issues
Set-Location $ScriptDir

# Step 3: Generate RSA private key
Write-Host "`n[3/6] Generating RSA 2048-bit private key..." -ForegroundColor Yellow
$keyOutput = wsl openssl genrsa -out "$KeyName.key" 2048 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Private key generated successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to generate private key" -ForegroundColor Red
    Write-Host "  $keyOutput" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 4: Create self-signed certificate
Write-Host "`n[4/6] Creating self-signed X.509 certificate..." -ForegroundColor Yellow
$ValidDays = $ValidYears * 365
$Subject = "/CN=L2 EFI Signing Key/O=L2 HWID Spoofer/C=US"

$certOutput = wsl openssl req -new -x509 -key "$KeyName.key" -out "$KeyName.crt" -days $ValidDays -subj "$Subject" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Certificate created successfully" -ForegroundColor Green
    Write-Host "    Subject: $Subject" -ForegroundColor Gray
    Write-Host "    Valid for: $ValidYears years" -ForegroundColor Gray
} else {
    Write-Host "  ERROR: Failed to create certificate" -ForegroundColor Red
    Write-Host "  $certOutput" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 5: Convert to DER format (for MOK enrollment)
Write-Host "`n[5/6] Converting certificate to DER format..." -ForegroundColor Yellow
$derOutput = wsl openssl x509 -in "$KeyName.crt" -outform DER -out "$KeyName.cer" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  DER certificate created successfully" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Failed to create DER certificate" -ForegroundColor Yellow
    Write-Host "  You may need to convert manually for MOK enrollment" -ForegroundColor Yellow
}

# Step 6: Verify outputs
Write-Host "`n[6/6] Verifying certificate files..." -ForegroundColor Yellow

$AllGood = $true

if (Test-Path $KeyFile) {
    $keySize = (Get-Item $KeyFile).Length
    Write-Host "  OK: Private key ($keySize bytes)" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Private key not found" -ForegroundColor Red
    $AllGood = $false
}

if (Test-Path $CertFile) {
    $certSize = (Get-Item $CertFile).Length
    Write-Host "  OK: Certificate PEM ($certSize bytes)" -ForegroundColor Green
    
    # Display certificate info
    $certInfo = wsl openssl x509 -in "$KeyName.crt" -noout -subject -dates 2>&1
    Write-Host "    $certInfo" -ForegroundColor Gray
} else {
    Write-Host "  ERROR: Certificate not found" -ForegroundColor Red
    $AllGood = $false
}

if (Test-Path $DerFile) {
    $derSize = (Get-Item $DerFile).Length
    Write-Host "  OK: Certificate DER ($derSize bytes)" -ForegroundColor Green
} else {
    Write-Host "  WARNING: DER certificate not found" -ForegroundColor Yellow
}

# Set proper permissions on private key
Write-Host "`n  Setting file permissions..." -ForegroundColor Gray
wsl chmod 600 "$KeyName.key" 2>&1 | Out-Null
wsl chmod 644 "$KeyName.crt" 2>&1 | Out-Null
if (Test-Path $DerFile) {
    wsl chmod 644 "$KeyName.cer" 2>&1 | Out-Null
}

Write-Host "`n=================================" -ForegroundColor Cyan
if ($AllGood) {
    Write-Host "Certificate Generation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Generated files:" -ForegroundColor White
    Write-Host "  Private Key: $KeyFile" -ForegroundColor White
    Write-Host "  Certificate (PEM): $CertFile" -ForegroundColor White
    Write-Host "  Certificate (DER): $DerFile" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT: Keep your private key secure!" -ForegroundColor Yellow
    Write-Host "  - Never share $KeyName.key with anyone" -ForegroundColor Yellow
    Write-Host "  - Back it up to a secure location" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next step: Sign your EFI spoofer (Step 3)" -ForegroundColor Cyan
} else {
    Write-Host "Certificate generation failed!" -ForegroundColor Red
    Write-Host "Please check errors above." -ForegroundColor Yellow
}
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


