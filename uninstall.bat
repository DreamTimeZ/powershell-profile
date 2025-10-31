@echo off
setlocal

:: Detect which PowerShell to use - prefer pwsh if available, otherwise use powershell
set "PS_EXE=powershell"

:: Check if pwsh is available (PowerShell 7+)
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    set "PS_EXE=pwsh"
    goto :run
)

:: Check if powershell is available (Windows PowerShell 5.1)
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo PowerShell is not installed. Please install PowerShell to continue.
    exit /b 1
)

:run
:: Run the PowerShell uninstall script with ExecutionPolicy Bypass and without loading any profiles
:: Forward all command-line arguments to the PowerShell script
%PS_EXE% -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
if %errorlevel% neq 0 (
    echo PowerShell script failed with error code %errorlevel%.
    pause
    exit /b %errorlevel%
)

pause
endlocal
