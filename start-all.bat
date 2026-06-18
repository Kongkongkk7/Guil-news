@echo off
chcp 65001 >nul 2>&1
title Guilin University News Center - One-Click Startup
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
    echo.
    pause
    exit /b 1
)

:: Run the PowerShell script with execution policy bypass
echo Launching startup script...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-all.ps1"

set EXITCODE=%ERRORLEVEL%
echo.
if %EXITCODE% neq 0 (
    echo ==========================================
    echo  Startup failed (exit code: %EXITCODE%)
    echo  Please check the error messages above
    echo ==========================================
) else (
    echo ==========================================
    echo  Script finished
    echo ==========================================
)
echo.
pause
