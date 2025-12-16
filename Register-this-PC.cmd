@echo off
REM ================================================================================
REM Register-this-PC.cmd - Launcher for Autopilot Registration Tool
REM ================================================================================
REM
REM PURPOSE:
REM This batch file launches the PowerShell Autopilot registration script.
REM Designed to be run during Windows OOBE (Out-of-Box Experience) via Shift+F10.
REM
REM DEPLOYMENT STRUCTURE (ISO):
REM   ISO Root/
REM   ├── Register-ThisPC.cmd        (this file - at root)
REM   └── scripts/
REM       ├── Register-ThisPC.ps1
REM       ├── Register-ThisPC.json
REM       ├── branding.ps1
REM       └── Documentation/
REM
REM USAGE:
REM 1. Boot from ISO/USB containing this structure
REM 2. During OOBE, press Shift+F10 to open Command Prompt
REM 3. Navigate to drive letter (e.g., D:, E:, F:)
REM 4. Run: Register-ThisPC.cmd
REM
REM AUTHORIZED PERSONNEL ONLY - See scripts\Documentation\SECURITY_README.md
REM ================================================================================

echo.
echo ================================================================================
echo           YourCompany Autopilot Device Registration
echo ================================================================================
echo.
echo WARNING: AUTHORIZED PERSONNEL ONLY
echo This tool registers devices in your organization's Autopilot service.
echo.
echo Starting registration process...
echo.

REM Determine the script directory
set SCRIPT_DIR=%~dp0scripts

REM Check if scripts folder exists
if not exist "%SCRIPT_DIR%" (
    echo ERROR: scripts folder not found at: %SCRIPT_DIR%
    echo.
    echo Expected structure:
    echo   %~dp0
    echo   ├── Register-ThisPC.cmd ^(this file^)
    echo   └── scripts\
    echo       └── Register-ThisPC.ps1
    echo.
    echo Please verify the ISO/USB structure and try again.
    exit /b 1
)

REM Check if Register-ThisPC.ps1 exists
if not exist "%SCRIPT_DIR%\Register-ThisPC.ps1" (
    echo ERROR: Register-ThisPC.ps1 not found in scripts folder
    echo Looking for: %SCRIPT_DIR%\Register-ThisPC.ps1
    echo.
    exit /b 1
)

echo Found script at: %SCRIPT_DIR%\Register-ThisPC.ps1
echo.

REM Try PowerShell 7 first (pwsh.exe)
where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Using PowerShell 7...
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Register-ThisPC.ps1"
) else (
    REM Fallback to Windows PowerShell 5.1
    echo PowerShell 7 not found, using Windows PowerShell 5.1...
    echo Note: Script will auto-install PowerShell 7 if needed.
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Register-ThisPC.ps1"
)

echo.
echo ================================================================================
echo Registration process completed.
echo ================================================================================
echo.

