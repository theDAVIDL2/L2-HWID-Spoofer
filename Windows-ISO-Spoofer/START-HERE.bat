@echo off
REM L2 HWID Spoofer - Main Entry Point
REM This batch file launches the dashboard with proper permissions

title L2 HWID Spoofer - Launcher

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ========================================
    echo  L2 HWID Spoofer
    echo ========================================
    echo.
    echo ERROR: Administrator rights required!
    echo.
    echo Please right-click this file and select:
    echo "Run as administrator"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: Clear screen
cls

:: Display welcome message
echo ========================================
echo  L2 HWID Spoofer
echo  Main Dashboard Launcher
echo ========================================
echo.
echo Starting dashboard...
echo.

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

:: Set the dashboard path
set "DASHBOARD=%SCRIPT_DIR%06-Dashboard\DASHBOARD.ps1"

:: Check if dashboard exists
if not exist "%DASHBOARD%" (
    echo ERROR: Dashboard not found!
    echo Looking for: %DASHBOARD%
    echo.
    echo Please ensure all project files are intact.
    echo.
    pause
    exit /b 1
)

:: Launch dashboard with PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DASHBOARD%"

:: Exit
exit /b 0


