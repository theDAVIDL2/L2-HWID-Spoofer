# UEFI Shell startup script for L2 Spoofer USB
# This helps with MOK enrollment on first boot

echo -off
cls

echo =========================================
echo L2 HWID Spoofer - MOK Enrollment Helper
echo =========================================
echo.
echo If this is your first boot, you need to:
echo 1. Enroll the MOK certificate
echo 2. Reboot
echo 3. Spoofer will work automatically
echo.
echo Starting MOK Manager...
echo.

# Try to load MOK Manager
\EFI\Boot\mmx64.efi

# If MOK Manager exits, try to boot spoofer
echo.
echo MOK enrollment complete or skipped.
echo Loading spoofer...
echo.

\EFI\Boot\grubx64.efi

