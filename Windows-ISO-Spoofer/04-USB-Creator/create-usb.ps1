# Step 4: USB Creator Script
# Creates a bootable USB with signed EFI spoofer

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Bootable USB Creator" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SpooferDir = Join-Path $ProjectRoot "01-EFI-Spoofer"
$CertDir = Join-Path $ProjectRoot "02-Certificates"
$BootloaderDir = Join-Path $ScriptDir "bootloader"

$SignedSpoofer = Join-Path $SpooferDir "spoofer-signed.efi"
$ShimFile = Join-Path $BootloaderDir "shimx64.efi"
$MokManager = Join-Path $BootloaderDir "mmx64.efi"
$CertFile = Join-Path $CertDir "my-key.cer"

# Step 1: Verify prerequisites
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Yellow

$AllGood = $true

if (-not (Test-Path $SignedSpoofer)) {
    Write-Host "  ERROR: Signed spoofer not found!" -ForegroundColor Red
    Write-Host "  Looking for: $SignedSpoofer" -ForegroundColor Yellow
    Write-Host "  Please run Step 3 (sign-spoofer.ps1) first." -ForegroundColor Yellow
    $AllGood = $false
}

if (-not (Test-Path $ShimFile)) {
    Write-Host "  ERROR: Shim bootloader not found!" -ForegroundColor Red
    Write-Host "  Looking for: $ShimFile" -ForegroundColor Yellow
    Write-Host "  Please obtain shimx64.efi (Microsoft-signed shim)" -ForegroundColor Yellow
    $AllGood = $false
}

if (-not (Test-Path $MokManager)) {
    Write-Host "  ERROR: MOK Manager not found!" -ForegroundColor Red
    Write-Host "  Looking for: $MokManager" -ForegroundColor Yellow
    Write-Host "  Please obtain mmx64.efi (MOK Manager)" -ForegroundColor Yellow
    $AllGood = $false
}

if (-not (Test-Path $CertFile)) {
    Write-Host "  WARNING: Certificate (DER) not found!" -ForegroundColor Yellow
    Write-Host "  Looking for: $CertFile" -ForegroundColor Yellow
    Write-Host "  MOK enrollment may not work without this." -ForegroundColor Yellow
}

if (-not $AllGood) {
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  All prerequisites found" -ForegroundColor Green

# Step 2: List available USB drives
Write-Host "`n[2/8] Detecting USB drives..." -ForegroundColor Yellow

# Force result to be an array to handle single drive correctly
$UsbDrives = @(Get-Disk | Where-Object { $_.BusType -eq 'USB' })

if ($UsbDrives.Count -eq 0) {
    Write-Host "  ERROR: No USB drives detected!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please insert a USB drive and try again." -ForegroundColor Yellow
    Write-Host "  Minimum size: 1 GB" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  Found $($UsbDrives.Count) USB drive(s):" -ForegroundColor Green
Write-Host ""

$Index = 1
foreach ($drive in $UsbDrives) {
    $SizeGB = [math]::Round($drive.Size / 1GB, 2)
    Write-Host "  [$Index] Disk $($drive.Number): $($drive.FriendlyName)" -ForegroundColor White
    Write-Host "      Size: $SizeGB GB" -ForegroundColor Gray
    Write-Host "      Status: $($drive.OperationalStatus)" -ForegroundColor Gray
    
    # Show partitions
    $partitions = Get-Partition -DiskNumber $drive.Number -ErrorAction SilentlyContinue
    if ($partitions) {
        foreach ($part in $partitions) {
            $volume = Get-Volume -Partition $part -ErrorAction SilentlyContinue
            if ($volume) {
                Write-Host "      Partition: $($volume.DriveLetter): [$($volume.FileSystemLabel)]" -ForegroundColor Gray
            }
        }
    }
    Write-Host ""
    $Index++
}

# Step 3: Select USB drive
Write-Host "[3/8] Select USB drive to use:" -ForegroundColor Yellow
Write-Host "  WARNING: ALL DATA ON SELECTED DRIVE WILL BE ERASED!" -ForegroundColor Red
Write-Host ""

$Selection = Read-Host "  Enter drive number (1-$($UsbDrives.Count)) or 'cancel'"

# Trim any whitespace
$Selection = $Selection.Trim()

if ($Selection -eq "cancel") {
    Write-Host "  Operation cancelled." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Validate selection is a number
$SelectionNum = 0
if (-not [int]::TryParse($Selection, [ref]$SelectionNum)) {
    Write-Host "  ERROR: '$Selection' is not a valid number" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Convert to array index (1-based to 0-based)
$DriveIndex = $SelectionNum - 1

# Validate selection is in range
if ($SelectionNum -lt 1 -or $SelectionNum -gt $UsbDrives.Count) {
    Write-Host "  ERROR: Invalid selection. Please enter a number between 1 and $($UsbDrives.Count)" -ForegroundColor Red
    Write-Host "  You entered: $SelectionNum" -ForegroundColor Yellow
    Write-Host "  Valid range: 1 to $($UsbDrives.Count)" -ForegroundColor Yellow
    Write-Host "  Drive count: $($UsbDrives.Count)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$SelectedDrive = $UsbDrives[$DriveIndex]
$DiskNumber = $SelectedDrive.Number
$SizeGB = [math]::Round($SelectedDrive.Size / 1GB, 2)

Write-Host "  Selected: Disk $DiskNumber ($SizeGB GB)" -ForegroundColor Green
Write-Host ""
Write-Host "  FINAL WARNING: This will erase Disk $DiskNumber completely!" -ForegroundColor Red
$Confirm = Read-Host "  Type 'YES' to confirm"

# Make confirmation case-insensitive
if ($Confirm.ToUpper() -ne "YES") {
    Write-Host "  Operation cancelled." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Step 4: Clean and format USB
Write-Host "`n[4/8] Formatting USB drive..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Gray

try {
    # Clean disk
    Clear-Disk -Number $DiskNumber -RemoveData -Confirm:$false -ErrorAction Stop
    Write-Host "  Disk cleaned" -ForegroundColor Green
    
    # Wait for disk to be ready
    Start-Sleep -Seconds 2
    
    # Check if disk is already initialized
    $disk = Get-Disk -Number $DiskNumber
    if ($disk.PartitionStyle -eq 'RAW') {
        # Initialize as GPT only if RAW
        Initialize-Disk -Number $DiskNumber -PartitionStyle GPT -ErrorAction Stop
        Write-Host "  Initialized as GPT" -ForegroundColor Green
        Start-Sleep -Seconds 1
    } else {
        Write-Host "  Disk already initialized as $($disk.PartitionStyle)" -ForegroundColor Green
    }
    
    # Create EFI partition (FAT32)
    $Partition = New-Partition -DiskNumber $DiskNumber -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
    $DriveLetter = $Partition.DriveLetter
    Write-Host "  Partition created: $DriveLetter`:" -ForegroundColor Green
    
    # Format as FAT32
    Format-Volume -DriveLetter $DriveLetter -FileSystem FAT32 -NewFileSystemLabel "L2-SPOOFER" -Confirm:$false -ErrorAction Stop | Out-Null
    Write-Host "  Formatted as FAT32" -ForegroundColor Green
    
} catch {
    Write-Host "  ERROR: Failed to format USB drive" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 5: Create EFI folder structure
Write-Host "`n[5/8] Creating EFI folder structure..." -ForegroundColor Yellow

$UsbRoot = "${DriveLetter}:\"
$EfiBootDir = Join-Path $UsbRoot "EFI\Boot"
$EfiSpooferDir = Join-Path $UsbRoot "EFI\Spoofer"

try {
    New-Item -ItemType Directory -Path $EfiBootDir -Force | Out-Null
    Write-Host "  Created: EFI\Boot\" -ForegroundColor Green
    
    New-Item -ItemType Directory -Path $EfiSpooferDir -Force | Out-Null
    Write-Host "  Created: EFI\Spoofer\" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to create directories" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 6: Copy EFI files
Write-Host "`n[6/8] Copying EFI files to USB..." -ForegroundColor Yellow

try {
    # Copy shim as bootx64.efi (UEFI standard boot file)
    $BootX64 = Join-Path $EfiBootDir "bootx64.efi"
    Copy-Item $ShimFile $BootX64 -Force
    Write-Host "  Copied: bootx64.efi (shim)" -ForegroundColor Green
    
    # Copy MOK Manager (needed for certificate enrollment)
    $MmX64 = Join-Path $EfiBootDir "mmx64.efi"
    Copy-Item $MokManager $MmX64 -Force
    Write-Host "  Copied: mmx64.efi (MOK Manager)" -ForegroundColor Green
    
    # Copy signed spoofer
    $SpooferDest = Join-Path $EfiSpooferDir "spoofer-signed.efi"
    Copy-Item $SignedSpoofer $SpooferDest -Force
    Write-Host "  Copied: spoofer-signed.efi" -ForegroundColor Green
    
    # Copy certificate for MOK enrollment (to EFI\Boot for easy access)
    if (Test-Path $CertFile) {
        $CertDest = Join-Path $EfiBootDir "cert.cer"
        Copy-Item $CertFile $CertDest -Force
        Write-Host "  Copied: cert.cer (for MOK)" -ForegroundColor Green
    }
    
    # IMPORTANT: On first boot, grubx64.efi should be MOK Manager
    # Copy MOK Manager as grubx64.efi so shim chainloads it first
    $GrubFile = Join-Path $EfiBootDir "grubx64.efi"
    Copy-Item $MokManager $GrubFile -Force
    Write-Host "  Copied: grubx64.efi (MOK Manager for first boot)" -ForegroundColor Green
    
    # Copy spoofer as fbx64.efi (fallback)
    $FallbackFile = Join-Path $EfiBootDir "fbx64.efi"
    Copy-Item $SignedSpoofer $FallbackFile -Force
    Write-Host "  Copied: fbx64.efi (spoofer fallback)" -ForegroundColor Green
    
    # Copy startup.nsh if it exists
    $StartupNsh = Join-Path $ScriptDir "startup.nsh"
    if (Test-Path $StartupNsh) {
        $StartupDest = Join-Path $UsbRoot "startup.nsh"
        Copy-Item $StartupNsh $StartupDest -Force
        Write-Host "  Copied: startup.nsh (UEFI shell script)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ERROR: Failed to copy files" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Step 7: Create README on USB
Write-Host "`n[7/8] Creating README file..." -ForegroundColor Yellow

$ReadmeContent = @"
========================================
L2 HWID Spoofer - Bootable USB
========================================

FIRST BOOT - MOK ENROLLMENT (ONE TIME ONLY):
1. Restart your computer
2. Enter BIOS boot menu (F2, Del, F12, or ESC)
3. Select this USB drive (L2-SPOOFER)
4. MOK Manager will appear (blue screen)
5. Select "Enroll key from disk"
6. Navigate to: This Disk -> EFI -> Boot -> cert.cer
7. Select the certificate file
8. Confirm enrollment (select Continue -> Yes)
9. Select "Reboot"

AFTER MOK ENROLLMENT - ENABLE SPOOFER:
10. Boot from USB again
11. At UEFI Shell (if appears), type: \EFI\Boot\fbx64.efi
12. Or rename fbx64.efi to grubx64.efi on the USB

ALTERNATIVE - Use System Install:
After MOK is enrolled, you can install to system:
- Boot Windows normally
- Run dashboard -> "Install to System"
- Spoofer will run automatically every boot

FIRST TIME SETUP:
- MOK enrollment is required only ONCE
- After enrollment, this USB will boot with Secure Boot ON
- The same MOK works for system installation

TROUBLESHOOTING:
- If boot fails, ensure Secure Boot is ENABLED
- If MOK screen doesn't appear, try booting again
- Check BIOS boot mode is UEFI (not Legacy)

FILES ON THIS USB:
- EFI\Boot\bootx64.efi - Shim bootloader (Microsoft-signed)
- EFI\Boot\grubx64.efi - Your signed spoofer
- EFI\Spoofer\spoofer-signed.efi - Your signed spoofer (backup)
- EFI\Spoofer\cert.cer - Your certificate (for MOK)

Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

For support: https://github.com/yourusername/l2-hwid-spoofer
========================================
"@

$ReadmePath = Join-Path $UsbRoot "README.txt"
Set-Content -Path $ReadmePath -Value $ReadmeContent -Encoding ASCII
Write-Host "  Created: README.txt" -ForegroundColor Green

# Step 8: Verify USB contents
Write-Host "`n[8/8] Verifying USB contents..." -ForegroundColor Yellow

$FilesToCheck = @(
    "EFI\Boot\bootx64.efi",
    "EFI\Boot\mmx64.efi",
    "EFI\Boot\grubx64.efi",
    "EFI\Boot\fbx64.efi",
    "EFI\Boot\cert.cer",
    "EFI\Spoofer\spoofer-signed.efi",
    "README.txt"
)

$AllGood = $true
foreach ($file in $FilesToCheck) {
    $fullPath = Join-Path $UsbRoot $file
    if (Test-Path $fullPath) {
        $size = (Get-Item $fullPath).Length
        Write-Host "  OK: $file ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $file" -ForegroundColor Red
        $AllGood = $false
    }
}

Write-Host "`n=================================" -ForegroundColor Cyan
if ($AllGood) {
    Write-Host "USB Creation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "USB Drive: $UsbRoot" -ForegroundColor White
    Write-Host "Label: L2-SPOOFER" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT - TWO-STAGE PROCESS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "STAGE 1: MOK Enrollment (First Boot)" -ForegroundColor Cyan
    Write-Host "1. Safely eject USB" -ForegroundColor White
    Write-Host "2. Restart and boot from USB" -ForegroundColor White
    Write-Host "3. MOK Manager appears (blue screen)" -ForegroundColor White
    Write-Host "4. Select: Enroll key from disk" -ForegroundColor White
    Write-Host "5. Navigate: This Disk > EFI > Boot > cert.cer" -ForegroundColor White
    Write-Host "6. Confirm and reboot" -ForegroundColor White
    Write-Host ""
    Write-Host "STAGE 2: After MOK Enrollment" -ForegroundColor Cyan
    Write-Host "7. Boot Windows normally (NOT from USB)" -ForegroundColor White
    Write-Host "8. Run dashboard -> '4. Install to System'" -ForegroundColor White
    Write-Host "9. Spoofer runs automatically every boot" -ForegroundColor White
    Write-Host ""
    Write-Host "See README.txt on USB for detailed instructions." -ForegroundColor Gray
} else {
    Write-Host "USB creation completed with errors!" -ForegroundColor Red
    Write-Host "Please check missing files above." -ForegroundColor Yellow
}
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


