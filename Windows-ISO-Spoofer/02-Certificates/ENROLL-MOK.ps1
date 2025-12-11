# MOK Enrollment Script
# Run this to enroll your certificate for Secure Boot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MOK (Machine Owner Key) Enrollment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Check if certificate exists
if (-not (Test-Path "my-key.cer")) {
    Write-Host "ERROR: Certificate not found!" -ForegroundColor Red
    Write-Host "Please run generate-cert.ps1 first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Certificate found: my-key.cer" -ForegroundColor Green
Write-Host ""

Write-Host "What happens next:" -ForegroundColor Yellow
Write-Host "1. You'll be asked for your WSL sudo password" -ForegroundColor White
Write-Host "2. Then mokutil will ask you to set a NEW password" -ForegroundColor White
Write-Host "3. Remember this password - you'll need it after restart" -ForegroundColor White
Write-Host "4. After restart, a blue MOK screen will appear" -ForegroundColor White
Write-Host "5. Enter that password to complete enrollment" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Continue? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Running mokutil..." -ForegroundColor Cyan
Write-Host ""

# Run mokutil
wsl sudo mokutil --import my-key.cer

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "MOK Import Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Restart your computer" -ForegroundColor White
    Write-Host ""
    Write-Host "2. MOK Manager will appear (blue screen)" -ForegroundColor White
    Write-Host "   - Select: 'Enroll MOK'" -ForegroundColor Gray
    Write-Host "   - Select: 'Continue'" -ForegroundColor Gray
    Write-Host "   - Enter the password you just set" -ForegroundColor Gray
    Write-Host "   - Select: 'Yes' to confirm" -ForegroundColor Gray
    Write-Host "   - Select: 'Reboot'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. After reboot, boot Windows normally" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Run dashboard -> '4. Install to System'" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Your certificate is now trusted!" -ForegroundColor Green
    Write-Host "   Secure Boot will stay enabled." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: MOK import failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "- WSL not running as admin" -ForegroundColor Gray
    Write-Host "- mokutil not installed" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alternative: Disable Secure Boot (see QUICK-FIX.txt)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

