#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Docker for Windows ARM64 Installer

.DESCRIPTION
    This script installs Docker CLI and Engine for Windows ARM64 architecture.
    It includes options to register Docker as a Windows service and add it to PATH.

.NOTES
    Requires Administrator privileges
    Compatible with Windows 10/11 ARM64
#>

param(
    [string]$InstallPath = "$env:ProgramFiles\Docker",
    [switch]$NoService,
    [switch]$NoPath,
    [switch]$Silent
)

# Color functions for better output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }
function Write-Info { Write-ColorOutput Cyan $args }

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires Administrator privileges. Please run as Administrator."
    exit 1
}

# Check if running on ARM64
$arch = (Get-WmiObject Win32_Processor).Architecture
if ($arch -ne 12) {  # 12 = ARM64
    Write-Warning "This installer is designed for ARM64 Windows systems."
    if (-not $Silent) {
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    } else {
        Write-Error "Not an ARM64 system. Exiting."
        exit 1
    }
}

# Check Windows version
$version = [System.Environment]::OSVersion.Version
if ($version.Build -lt 17134) {
    Write-Error "Windows 10 version 1803 (build 17134) or later is required."
    exit 1
}

Write-Info "Docker for Windows ARM64 Installer"
Write-Info "======================================="
Write-Info "Install Path: $InstallPath"
Write-Info "Register Service: $(-not $NoService)"
Write-Info "Add to PATH: $(-not $NoPath)"
Write-Info ""

# Get script directory (where the executables should be)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DockerExe = Join-Path $ScriptDir "docker-windows-arm64.exe"
$DockerdExe = Join-Path $ScriptDir "dockerd-windows-arm64.exe"

# Check if Docker binaries exist
if (-not (Test-Path $DockerExe)) {
    Write-Error "Docker CLI binary not found: $DockerExe"
    Write-Error "Please ensure docker-windows-arm64.exe is in the same directory as this script."
    exit 1
}

if (-not (Test-Path $DockerdExe)) {
    Write-Error "Docker daemon binary not found: $DockerdExe"
    Write-Error "Please ensure dockerd-windows-arm64.exe is in the same directory as this script."
    exit 1
}

try {
    # Create installation directory
    Write-Info "Creating installation directory..."
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    # Copy Docker binaries
    Write-Info "Installing Docker binaries..."
    Copy-Item $DockerExe (Join-Path $InstallPath "docker.exe") -Force
    Copy-Item $DockerdExe (Join-Path $InstallPath "dockerd.exe") -Force
    Write-Success "Docker binaries installed successfully."

    # Create data directories
    Write-Info "Creating Docker data directories..."
    $DataDir = "$env:ProgramData\Docker"
    $UserDataDir = "$env:LOCALAPPDATA\Docker"

    if (-not (Test-Path $DataDir)) {
        New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
    }
    if (-not (Test-Path $UserDataDir)) {
        New-Item -ItemType Directory -Path $UserDataDir -Force | Out-Null
    }

    # Add to PATH if requested
    if (-not $NoPath) {
        Write-Info "Adding Docker to system PATH..."
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$InstallPath*") {
            [Environment]::SetEnvironmentVariable("Path", $currentPath + ";$InstallPath", "Machine")
            Write-Success "Docker added to system PATH."
        } else {
            Write-Info "Docker already in system PATH."
        }
    }

    # Register Windows service if requested
    if (-not $NoService) {
        Write-Info "Registering Docker service..."

        # Stop and remove existing service if it exists
        try {
            Stop-Service -Name "docker" -Force -ErrorAction SilentlyContinue
            sc.exe delete docker | Out-Null
        } catch {
            # Service doesn't exist, that's fine
        }

        # Create new service
        $servicePath = Join-Path $InstallPath "dockerd.exe"
        $result = sc.exe create docker binPath= "`"$servicePath`"" DisplayName= "Docker Engine" start= auto

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker service registered successfully."

            if (-not $Silent) {
                $startNow = Read-Host "Would you like to start the Docker service now? (Y/n)"
                if ($startNow -ne 'n' -and $startNow -ne 'N') {
                    Write-Info "Starting Docker service..."
                    try {
                        Start-Service -Name "docker"
                        Write-Success "Docker service started successfully."
                    } catch {
                        Write-Warning "Failed to start Docker service: $($_.Exception.Message)"
                        Write-Info "You can start it manually later with: Start-Service docker"
                    }
                }
            }
        } else {
            Write-Warning "Failed to register Docker service. You may need to register it manually."
        }
    }

    # Create Start Menu shortcuts
    Write-Info "Creating shortcuts..."
    $WshShell = New-Object -comObject WScript.Shell
    $StartMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Docker"

    if (-not (Test-Path $StartMenuPath)) {
        New-Item -ItemType Directory -Path $StartMenuPath -Force | Out-Null
    }

    # Docker CLI shortcut
    $Shortcut = $WshShell.CreateShortcut("$StartMenuPath\Docker CLI.lnk")
    $Shortcut.TargetPath = "cmd.exe"
    $Shortcut.Arguments = "/k `"$InstallPath\docker.exe`" version"
    $Shortcut.WorkingDirectory = $InstallPath
    $Shortcut.IconLocation = "$InstallPath\docker.exe"
    $Shortcut.Save()

    # Desktop shortcut
    $DesktopShortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Docker CLI.lnk")
    $DesktopShortcut.TargetPath = "cmd.exe"
    $DesktopShortcut.Arguments = "/k `"$InstallPath\docker.exe`" version"
    $DesktopShortcut.WorkingDirectory = $InstallPath
    $DesktopShortcut.IconLocation = "$InstallPath\docker.exe"
    $DesktopShortcut.Save()

    # Create uninstaller
    Write-Info "Creating uninstaller..."
    $UninstallScript = @"
#Requires -RunAsAdministrator

Write-Host "Uninstalling Docker for Windows ARM64..." -ForegroundColor Cyan

# Stop and remove service
try {
    Stop-Service -Name "docker" -Force -ErrorAction SilentlyContinue
    sc.exe delete docker | Out-Null
    Write-Host "Docker service removed." -ForegroundColor Green
} catch {
    Write-Host "Service removal: `$(`$_.Exception.Message)" -ForegroundColor Yellow
}

# Remove from PATH
`$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
`$newPath = `$currentPath -replace ";$InstallPath", "" -replace "$InstallPath;", "" -replace "$InstallPath", ""
[Environment]::SetEnvironmentVariable("Path", `$newPath, "Machine")

# Remove files and directories
Remove-Item "$InstallPath" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Docker" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\Desktop\Docker CLI.lnk" -Force -ErrorAction SilentlyContinue

# Remove registry entries
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker-ARM64" -Name "*" -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker-ARM64" -ErrorAction SilentlyContinue

Write-Host "Docker uninstalled successfully." -ForegroundColor Green
Read-Host "Press Enter to exit"
"@

    $UninstallScript | Out-File -FilePath "$InstallPath\Uninstall-Docker.ps1" -Encoding UTF8

    # Create registry entries for Programs and Features
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker-ARM64"
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "DisplayName" -Value "Docker for Windows ARM64"
    Set-ItemProperty -Path $regPath -Name "DisplayVersion" -Value "28.3.3-custom"
    Set-ItemProperty -Path $regPath -Name "Publisher" -Value "Custom Build"
    Set-ItemProperty -Path $regPath -Name "InstallLocation" -Value $InstallPath
    Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$InstallPath\Uninstall-Docker.ps1`""
    Set-ItemProperty -Path $regPath -Name "NoModify" -Value 1 -Type DWord
    Set-ItemProperty -Path $regPath -Name "NoRepair" -Value 1 -Type DWord

    Write-Success ""
    Write-Success "Docker for Windows ARM64 installation completed successfully!"
    Write-Success ""
    Write-Info "Installation Summary:"
    Write-Info "  - Docker CLI: $InstallPath\docker.exe"
    Write-Info "  - Docker Engine: $InstallPath\dockerd.exe"
    if (-not $NoPath) { Write-Info "  - Added to system PATH" }
    if (-not $NoService) { Write-Info "  - Registered as Windows service" }
    Write-Info "  - Start Menu shortcuts created"
    Write-Info "  - Desktop shortcut created"
    Write-Info ""
    Write-Info "To test the installation, open a new Command Prompt and run: docker version"
    Write-Info "To uninstall, run: $InstallPath\Uninstall-Docker.ps1"
    Write-Info ""

    if (-not $Silent) {
        $testNow = Read-Host "Would you like to test Docker now? (Y/n)"
        if ($testNow -ne 'n' -and $testNow -ne 'N') {
            Write-Info "Testing Docker installation..."
            & "$InstallPath\docker.exe" version
        }
    }

} catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}

Write-Success "Installation completed successfully!"