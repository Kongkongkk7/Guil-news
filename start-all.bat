@echo off
chcp 65001 >nul 2>&1
cls

echo ==========================================
echo     Guilin University News Center
echo     One-Click Startup Script
echo ==========================================
echo.

:: Check if PowerShell is available
where powershell >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell not found!
    echo Please install Windows PowerShell 5.1+
    pause
    exit /b 1
)

:: Run the PowerShell script with execution policy bypass
echo Launching PowerShell script...
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0start-all.ps1"

if errorlevel 1 (
    echo.
    echo Startup failed. Please check the error messages above.
    pause
)
