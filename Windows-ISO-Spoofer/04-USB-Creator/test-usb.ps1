# Step 4: USB Testing Script
# Verifies the bootable USB was created correctly

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "USB Verification Tool" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Detect USB drives with L2-SPOOFER label
Write-Host "[1/5] Detecting L2-SPOOFER USB drive..." -ForegroundColor Yellow

$UsbVolumes = Get-Volume | Where-Object { $_.FileSystemLabel -eq "L2-SPOOFER" -and $_.DriveType -eq "Removable" }

if ($UsbVolumes.Count -eq 0) {
    Write-Host "  ERROR: L2-SPOOFER USB drive not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please insert the USB drive you created with create-usb.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$UsbVolume = $UsbVolumes[0]
$DriveLetter = $UsbVolume.DriveLetter
$UsbRoot = "${DriveLetter}:\"

Write-Host "  Found: $UsbRoot ($($UsbVolume.FileSystemLabel))" -ForegroundColor Green
Write-Host "  Size: $([math]::Round($UsbVolume.Size / 1GB, 2)) GB" -ForegroundColor Gray
Write-Host "  File System: $($UsbVolume.FileSystem)" -ForegroundColor Gray

# Step 2: Verify EFI folder structure
Write-Host "`n[2/5] Verifying folder structure..." -ForegroundColor Yellow

$RequiredDirs = @(
    "EFI",
    "EFI\Boot",
    "EFI\Spoofer"
)

$AllGood = $true
foreach ($dir in $RequiredDirs) {
    $fullPath = Join-Path $UsbRoot $dir
    if (Test-Path $fullPath) {
        Write-Host "  OK: $dir\" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $dir\" -ForegroundColor Red
        $AllGood = $false
    }
}

if (-not $AllGood) {
    Write-Host ""
    Write-Host "  ERROR: USB structure is incomplete!" -ForegroundColor Red
    Write-Host "  Please recreate the USB with create-usb.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 3: Verify required files
Write-Host "`n[3/5] Verifying EFI files..." -ForegroundColor Yellow

$RequiredFiles = @(
    @{Path="EFI\Boot\bootx64.efi"; Name="Shim bootloader"; MinSize=500KB},
    @{Path="EFI\Boot\grubx64.efi"; Name="Chainloader (spoofer)"; MinSize=10KB},
    @{Path="EFI\Spoofer\spoofer-signed.efi"; Name="Signed spoofer"; MinSize=10KB},
    @{Path="README.txt"; Name="Instructions"; MinSize=100}
)

$AllGood = $true
foreach ($file in $RequiredFiles) {
    $fullPath = Join-Path $UsbRoot $file.Path
    if (Test-Path $fullPath) {
        $size = (Get-Item $fullPath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        
        if ($size -ge $file.MinSize) {
            Write-Host "  OK: $($file.Path) ($sizeKB KB)" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: $($file.Path) is too small ($sizeKB KB)" -ForegroundColor Yellow
            Write-Host "          Expected at least $([math]::Round($file.MinSize / 1KB, 2)) KB" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  MISSING: $($file.Path)" -ForegroundColor Red
        $AllGood = $false
    }
}

# Check for optional certificate
$CertPath = Join-Path $UsbRoot "EFI\Spoofer\cert.cer"
if (Test-Path $CertPath) {
    $size = (Get-Item $CertPath).Length
    Write-Host "  OK: EFI\Spoofer\cert.cer ($size bytes)" -ForegroundColor Green
} else {
    Write-Host "  INFO: cert.cer not found (optional)" -ForegroundColor Gray
}

# Step 4: Verify EFI file signatures
Write-Host "`n[4/5] Checking EFI file signatures..." -ForegroundColor Yellow

# Check if PE files
$EfiFiles = @(
    "EFI\Boot\bootx64.efi",
    "EFI\Boot\grubx64.efi",
    "EFI\Spoofer\spoofer-signed.efi"
)

foreach ($efi in $EfiFiles) {
    $fullPath = Join-Path $UsbRoot $efi
    if (Test-Path $fullPath) {
        # Read first 2 bytes for MZ signature
        try {
            $bytes = Get-Content $fullPath -Encoding Byte -TotalCount 2 -ErrorAction SilentlyContinue
            if ($bytes[0] -eq 0x4D -and $bytes[1] -eq 0x5A) {
                Write-Host "  OK: $efi is valid PE file" -ForegroundColor Green
            } else {
                Write-Host "  WARNING: $efi may not be valid PE file" -ForegroundColor Yellow
                $AllGood = $false
            }
        } catch {
            Write-Host "  WARNING: Could not verify $efi" -ForegroundColor Yellow
        }
    }
}

# Step 5: Display boot instructions
Write-Host "`n[5/5] Boot readiness check..." -ForegroundColor Yellow

if ($AllGood) {
    Write-Host "  USB is ready to boot!" -ForegroundColor Green
} else {
    Write-Host "  USB has warnings (may still work)" -ForegroundColor Yellow
}

# Calculate checksums
Write-Host "`n  Calculating checksums..." -ForegroundColor Gray
$BootX64Path = Join-Path $UsbRoot "EFI\Boot\bootx64.efi"
if (Test-Path $BootX64Path) {
    $hash = Get-FileHash -Path $BootX64Path -Algorithm SHA256
    Write-Host "  bootx64.efi SHA256: $($hash.Hash.Substring(0,16))..." -ForegroundColor Gray
}

$SpooferPath = Join-Path $UsbRoot "EFI\Spoofer\spoofer-signed.efi"
if (Test-Path $SpooferPath) {
    $hash = Get-FileHash -Path $SpooferPath -Algorithm SHA256
    Write-Host "  spoofer-signed.efi SHA256: $($hash.Hash.Substring(0,16))..." -ForegroundColor Gray
}

# Display contents
Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "USB Verification Complete" -ForegroundColor Cyan
Write-Host ""
Write-Host "USB Drive: $UsbRoot" -ForegroundColor White
Write-Host "Status: $(if ($AllGood) { 'READY' } else { 'WARNINGS' })" -ForegroundColor $(if ($AllGood) { 'Green' } else { 'Yellow' })
Write-Host ""

if ($AllGood) {
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "1. Safely eject the USB drive" -ForegroundColor White
    Write-Host "2. Restart your computer" -ForegroundColor White
    Write-Host "3. Enter BIOS boot menu (usually F12, F8, or ESC)" -ForegroundColor White
    Write-Host "4. Select: $($UsbVolume.FileSystemLabel)" -ForegroundColor White
    Write-Host "5. Complete MOK enrollment when prompted" -ForegroundColor White
    Write-Host "6. Verify HWIDs are spoofed in Windows" -ForegroundColor White
    Write-Host ""
    Write-Host "MOK ENROLLMENT STEPS:" -ForegroundColor Cyan
    Write-Host "- Blue screen will appear on first boot" -ForegroundColor Gray
    Write-Host "- Select: Enroll MOK -> Continue -> Yes -> Reboot" -ForegroundColor Gray
    Write-Host "- This is required only ONCE" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See README.txt on USB for detailed instructions" -ForegroundColor Gray
} else {
    Write-Host "WARNING: Issues detected above." -ForegroundColor Yellow
    Write-Host "USB may not boot correctly. Consider recreating it." -ForegroundColor Yellow
}

Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Display all files on USB
Write-Host "All files on USB:" -ForegroundColor White
Get-ChildItem -Path $UsbRoot -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Replace($UsbRoot, "")
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    Write-Host "  $relativePath ($sizeKB KB)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


