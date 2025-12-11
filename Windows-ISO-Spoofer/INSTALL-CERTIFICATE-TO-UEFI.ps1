# Install Certificate to UEFI Secure Boot Database
# This adds your certificate to the system's trusted certificates

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Install Certificate to UEFI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}

$CertPath = Join-Path $PSScriptRoot "02-Certificates\my-key.cer"
if (-not (Test-Path $CertPath)) {
    $CertPath = Join-Path $PSScriptRoot "my-key.cer"
}

if (-not (Test-Path $CertPath)) {
    Write-Host "ERROR: Certificate not found!" -ForegroundColor Red
    Write-Host "Looking for: $CertPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "Certificate found: $CertPath" -ForegroundColor Green
Write-Host ""

Write-Host "Attempting to add certificate to system..." -ForegroundColor Yellow
Write-Host ""

try {
    # Try to add to machine's trusted certificates
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
    
    Write-Host "SUCCESS: Certificate added to Windows Trusted Root!" -ForegroundColor Green
    Write-Host ""
    Write-Host "However, this may not be enough for UEFI Secure Boot..." -ForegroundColor Yellow
    
} catch {
    Write-Host "Could not add to Windows store: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "UEFI Secure Boot Certificate Options:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "To properly add your certificate to UEFI Secure Boot:" -ForegroundColor White
Write-Host ""
Write-Host "METHOD 1: Through BIOS/UEFI Setup" -ForegroundColor Cyan
Write-Host "1. Copy certificate to USB drive" -ForegroundColor Gray
Write-Host "2. Restart and enter BIOS (F2/Del)" -ForegroundColor Gray
Write-Host "3. Find: Security > Secure Boot > Key Management" -ForegroundColor Gray
Write-Host "4. Look for: 'Enroll Key' or 'Add Certificate'" -ForegroundColor Gray
Write-Host "5. Browse to USB and select: my-key.cer" -ForegroundColor Gray
Write-Host "6. Add to 'db' (authorized database)" -ForegroundColor Gray
Write-Host "7. Save and exit" -ForegroundColor Gray
Write-Host ""

Write-Host "METHOD 2: Use KeyTool (If BIOS doesn't support)" -ForegroundColor Cyan
Write-Host "Some ASUS motherboards have KeyTool in BIOS" -ForegroundColor Gray
Write-Host ""

Write-Host "METHOD 3: Linux Live USB + mokutil" -ForegroundColor Cyan
Write-Host "1. Create Ubuntu Live USB" -ForegroundColor Gray
Write-Host "2. Boot from it" -ForegroundColor Gray
Write-Host "3. Run: sudo mokutil --import /path/to/my-key.cer" -ForegroundColor Gray
Write-Host "4. Set password, reboot, complete enrollment" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "IMPORTANT: Your BIOS Model" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

$computerInfo = Get-ComputerInfo -Property CsManufacturer, CsModel
Write-Host "Manufacturer: $($computerInfo.CsManufacturer)" -ForegroundColor White
Write-Host "Model: $($computerInfo.CsModel)" -ForegroundColor White
Write-Host ""
Write-Host "Google: '$($computerInfo.CsManufacturer) $($computerInfo.CsModel) secure boot add certificate'" -ForegroundColor Cyan
Write-Host ""

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

