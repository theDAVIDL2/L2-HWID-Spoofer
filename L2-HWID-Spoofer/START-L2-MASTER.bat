@echo off
:: L2 HWID Master - Quick Launcher
:: Run as Administrator for best results

title L2 HWID Master

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ============================================
    echo   Please run this as Administrator!
    echo ============================================
    echo.
    echo Right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

:: Run the PowerShell script
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoProfile -File "L2-HWID-Master.ps1"

pause
