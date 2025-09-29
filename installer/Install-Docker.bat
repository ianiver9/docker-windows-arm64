@echo off
setlocal EnableDelayedExpansion

title Docker for Windows ARM64 Installer

echo.
echo ==========================================
echo   Docker for Windows ARM64 Installer
echo ==========================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This installer requires Administrator privileges.
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Check if PowerShell is available
powershell -Command "Write-Output 'PowerShell is available'" >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: PowerShell is required but not available.
    echo Please ensure PowerShell is installed on your system.
    pause
    exit /b 1
)

echo Checking system requirements...
echo.

REM Check if required files exist
if not exist "%~dp0docker-windows-arm64.exe" (
    echo ERROR: docker-windows-arm64.exe not found in installer directory.
    echo Please ensure all Docker binaries are present.
    pause
    exit /b 1
)

if not exist "%~dp0dockerd-windows-arm64.exe" (
    echo ERROR: dockerd-windows-arm64.exe not found in installer directory.
    echo Please ensure all Docker binaries are present.
    pause
    exit /b 1
)

echo All required files found.
echo.

REM Ask user for installation options
echo Installation Options:
echo.
set /p "installPath=Installation directory (default: C:\Program Files\Docker): "
if "!installPath!"=="" set "installPath=C:\Program Files\Docker"

echo.
set /p "installService=Register Docker as Windows service? (Y/n): "
if "!installService!"=="" set "installService=Y"

echo.
set /p "addToPath=Add Docker to system PATH? (Y/n): "
if "!addToPath!"=="" set "addToPath=Y"

echo.
echo Installation Summary:
echo   Install Path: !installPath!
echo   Register Service: !installService!
echo   Add to PATH: !addToPath!
echo.

set /p "confirm=Proceed with installation? (Y/n): "
if "!confirm!"=="" set "confirm=Y"
if /i "!confirm!" neq "Y" (
    echo Installation cancelled.
    pause
    exit /b 0
)

echo.
echo Starting installation...
echo.

REM Build PowerShell command with parameters
set "psCmd=& '%~dp0Docker-ARM64-Installer.ps1'"
if /i "!installService!" equ "N" set "psCmd=!psCmd! -NoService"
if /i "!addToPath!" equ "N" set "psCmd=!psCmd! -NoPath"
if not "!installPath!"=="C:\Program Files\Docker" set "psCmd=!psCmd! -InstallPath '!installPath!'"

REM Execute PowerShell installer
powershell -ExecutionPolicy Bypass -Command "!psCmd!"

if %errorLevel% equ 0 (
    echo.
    echo ==========================================
    echo   Installation completed successfully!
    echo ==========================================
    echo.
    echo Docker has been installed to: !installPath!
    echo.
    if /i "!addToPath!" equ "Y" (
        echo Docker has been added to your system PATH.
        echo You can now use 'docker' commands from any Command Prompt.
    )
    echo.
    if /i "!installService!" equ "Y" (
        echo Docker has been registered as a Windows service.
        echo You can start/stop it using: sc start docker / sc stop docker
    )
    echo.
    echo To test your installation, open a new Command Prompt and run:
    echo   docker version
    echo.
) else (
    echo.
    echo ==========================================
    echo   Installation failed!
    echo ==========================================
    echo.
    echo Please check the error messages above and try again.
    echo You may need to run this installer as Administrator.
    echo.
)

echo Press any key to exit...
pause >nul