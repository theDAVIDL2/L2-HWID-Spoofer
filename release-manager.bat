@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion enableextensions
color 0B

:: ================================================================
:: L2 HWID SPOOFER - Release Manager
:: Hardware Identification Spoofing System
:: ================================================================

:: Configuration
set "PROJECT_NAME=L2 HWID Spoofer"
set "REPO_URL=https://github.com/theDAVIDL2/L2-HWID-Spoofer.git"
set "DEFAULT_BRANCH=main"

:: Set title
title %PROJECT_NAME% - Release Manager

:MENU
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║          L2 HWID SPOOFER - RELEASE MANAGER v1.0            ║
echo ║           Hardware Identification Spoofing System          ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📦 Project: %PROJECT_NAME%
echo 🔗 Remote:  %REPO_URL%
echo.
echo ════════════════════════════════════════════════════════════
echo.
echo  [1] 🎛️  Launch Dashboard        (EFI Spoofer GUI)
echo  [2] 🔑 Connect GitHub (SSH)    (Setup Remote)
echo  [3] 📤 Quick Push              (Git Add + Commit + Push)
echo  [4] � Full Release            (Tag + Push)
echo  [5] � Check Status            (Git Status)
echo  [6] � Verify Installation     (Check Spoofer Status)
echo  [7] 📖 Open Documentation      (View README)
echo  [8] 🧹 Clean Workspace         (Remove temp files)
echo  [0] ❌ Exit
echo.
echo ════════════════════════════════════════════════════════════
echo.

set /p choice="Enter your choice (0-8): "

if "%choice%"=="1" goto LAUNCH_DASHBOARD
if "%choice%"=="2" goto CONNECT_SSH
if "%choice%"=="3" goto QUICK_PUSH
if "%choice%"=="4" goto FULL_RELEASE
if "%choice%"=="5" goto CHECK_STATUS
if "%choice%"=="6" goto VERIFY_INSTALL
if "%choice%"=="7" goto OPEN_DOCS
if "%choice%"=="8" goto CLEAN_WORKSPACE
if "%choice%"=="0" goto EXIT
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto MENU

:: ================================================================
:: 1. LAUNCH DASHBOARD
:: ================================================================
:LAUNCH_DASHBOARD
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              Launching Spoofer Dashboard 🎛️                ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
if exist "Windows-ISO-Spoofer\START-HERE.bat" (
    echo Launching EFI Spoofer Dashboard...
    echo.
    call "Windows-ISO-Spoofer\START-HERE.bat"
) else (
    echo ❌ Dashboard not found!
    echo Expected: Windows-ISO-Spoofer\START-HERE.bat
)
pause
goto MENU

:: ================================================================
:: 2. CONNECT GITHUB (SSH)
:: ================================================================
:CONNECT_SSH
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║               Connecting to GitHub (SSH) 🔑                ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Current Remote:
git remote -v
echo.
echo Enter your SSH remote URL (e.g., git@github.com:username/repo.git)
set /p ssh_url="SSH URL: "
if "%ssh_url%"=="" goto MENU

echo.
echo Setting remote 'origin' to %ssh_url%...
git remote set-url origin %ssh_url%
if errorlevel 1 (
    echo.
    echo ⚠️  'origin' remote not found. Adding new remote...
    git remote add origin %ssh_url%
)

echo.
echo ✅ Remote updated!
git remote -v
pause
goto MENU

:: ================================================================
:: 3. QUICK PUSH
:: ================================================================
:QUICK_PUSH
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                  Quick Push to GitHub 📤                   ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
git status --short
echo.
set /p msg="📝 Commit Message: "
if "%msg%"=="" goto MENU

echo.
echo [1/3] Adding files...
git add .
echo [2/3] Committing...
git commit -m "%msg%"
echo [3/3] Pushing...
git push origin %DEFAULT_BRANCH%
if errorlevel 1 (
    echo.
    echo ❌ Push Failed!
) else (
    echo.
    echo ✅ Push Successful!
)
pause
goto MENU

:: ================================================================
:: 4. FULL RELEASE
:: ================================================================
:FULL_RELEASE
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                  Full Release Workflow �                  ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo This will:
echo 1. Commit all changes
echo 2. Create a git tag
echo 3. Push everything
echo.
set /p version="🏷️  Enter Version (e.g., v1.0.0): "
if "%version%"=="" goto MENU

echo.
echo [1/3] Committing...
git add .
git commit -m "release: %version%"

echo.
echo [2/3] Tagging...
git tag -a %version% -m "Release %version%"

echo.
echo [3/3] Pushing...
git push origin %DEFAULT_BRANCH%
git push origin %version%

echo.
echo ✅ Release %version% Deployed!
pause
goto MENU

:: ================================================================
:: 5. CHECK STATUS
:: ================================================================
:CHECK_STATUS
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                    Git Status �                           ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
git status
echo.
echo ────────────────────────────────────────────────────────────
echo Recent Commits:
git log --oneline -5
echo.
pause
goto MENU

:: ================================================================
:: 6. VERIFY INSTALLATION
:: ================================================================
:VERIFY_INSTALL
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              Verifying Spoofer Installation �             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Checking components...
echo.

echo [EFI Spoofer]
if exist "Windows-ISO-Spoofer\01-EFI-Spoofer\amideefix64.efi" (
    echo   ✅ amideefix64.efi - Found
) else (
    echo   ❌ amideefix64.efi - Missing
)

if exist "Windows-ISO-Spoofer\01-EFI-Spoofer\spoofer-signed.efi" (
    echo   ✅ spoofer-signed.efi - Found (Signed)
) else (
    echo   ⚠️  spoofer-signed.efi - Not signed yet
)

echo.
echo [Certificates]
if exist "Windows-ISO-Spoofer\02-Certificates\my-key.crt" (
    echo   ✅ Certificate - Generated
) else (
    echo   ❌ Certificate - Not generated
)

echo.
echo [Hypervisor Source]
if exist "Hypervisor-Test-Spoofer\01-Source\hypervisor\vmx_intel.c" (
    echo   ✅ Intel VT-x Source - Present
) else (
    echo   ❌ Intel VT-x Source - Missing
)

if exist "Hypervisor-Test-Spoofer\01-Source\hypervisor\svm_amd.c" (
    echo   ✅ AMD-V Source - Present
) else (
    echo   ❌ AMD-V Source - Missing
)

echo.
echo [Boot Entry]
bcdedit /enum firmware 2>nul | findstr /i "L2signed" >nul
if errorlevel 1 (
    echo   ⚠️  L2signed boot entry - Not installed
) else (
    echo   ✅ L2signed boot entry - Installed
)

echo.
pause
goto MENU

:: ================================================================
:: 7. OPEN DOCUMENTATION
:: ================================================================
:OPEN_DOCS
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                 Opening Documentation 📖                   ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Select documentation to open:
echo.
echo  [1] README.md (Main)
echo  [2] WORKFLOW.md (EFI Spoofer Guide)
echo  [3] README-START-HERE.md (Quick Start)
echo  [4] ARCHITECTURE-COMPARISON.md (Technical)
echo  [0] Back to Menu
echo.
set /p doc_choice="Choice: "

if "%doc_choice%"=="1" start notepad "README.md"
if "%doc_choice%"=="2" start notepad "Windows-ISO-Spoofer\WORKFLOW.md"
if "%doc_choice%"=="3" start notepad "README-START-HERE.md"
if "%doc_choice%"=="4" start notepad "ARCHITECTURE-COMPARISON.md"
goto MENU

:: ================================================================
:: 8. CLEAN WORKSPACE
:: ================================================================
:CLEAN_WORKSPACE
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                 Cleaning Workspace 🧹                      ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo This will clean temporary files:
echo.

:: Clean temp directories
if exist "Windows-ISO-Spoofer\01-EFI-Spoofer\temp_sign" (
    echo Removing temp_sign directory...
    rmdir /s /q "Windows-ISO-Spoofer\01-EFI-Spoofer\temp_sign"
    echo   ✅ temp_sign removed
)

:: Clean any .log files
echo.
echo Cleaning .log files...
del /s /q *.log 2>nul
echo   ✅ Log files cleaned

echo.
echo ✅ Workspace cleaned!
pause
goto MENU

:EXIT
exit
