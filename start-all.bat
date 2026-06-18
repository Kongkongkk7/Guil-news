@echo off
chcp 65001 >nul 2>&1
title Guilin University News Center - One-Click Startup
cls

echo ==========================================
echo     Guilin University News Center
echo     One-Click Startup Script
echo ==========================================
echo.

:: Get script directory
set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%start-all.ps1"

:: Check if PowerShell is available
where powershell >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell not found!
    echo Please install Windows PowerShell 5.1+
    echo.
    pause
    exit /b 1
)

:: Check if ps1 file exists
if not exist "%PS1_FILE%" (
    echo ERROR: start-all.ps1 not found!
    echo Expected location: %PS1_FILE%
    echo.
    pause
    exit /b 1
)

echo Launching startup script...
echo.

:: Run PowerShell script (output displays directly in this window)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"

set EXITCODE=%ERRORLEVEL%
echo.
echo ==========================================
if %EXITCODE% neq 0 (
    echo  Startup FAILED ^(exit code: %EXITCODE%^)
    echo  Please check the error messages above
) else (
    echo  Script finished ^(services are running in separate windows^)
)
echo ==========================================
echo.
echo Note: Backend and frontend run in separate windows.
echo Close those windows to stop the services.
echo.
echo Press any key to close this launcher window...
pause >nul
