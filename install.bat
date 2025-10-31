@echo off
setlocal

:: Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo PowerShell is not installed. Please install PowerShell to continue.
    exit /b 1
)

:: Run the PowerShell script with ExecutionPolicy Bypass and without loading any profiles
:: Forward all command-line arguments to the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0install.ps1" %*
if %errorlevel% neq 0 (
    echo PowerShell script failed with error code %errorlevel%.
    pause
    exit /b %errorlevel%
)

pause
endlocal
