# Docker for Windows ARM64 - Custom Build Installer

This installer package contains Docker CLI and Engine compiled specifically for Windows ARM64 architecture.

## Package Contents

- `docker-windows-arm64.exe` - Docker CLI (renamed to `docker.exe` during installation)
- `dockerd-windows-arm64.exe` - Docker Engine/Daemon (renamed to `dockerd.exe` during installation)
- `Install-Docker.bat` - User-friendly batch installer
- `Docker-ARM64-Installer.ps1` - PowerShell installation script
- `LICENSE.txt` - License information

## Installation Methods

### Method 1: Interactive Batch Installer (Recommended)

1. Right-click `Install-Docker.bat` and select "Run as administrator"
2. Follow the prompts to configure your installation
3. The installer will:
   - Copy Docker binaries to your chosen location (default: `C:\Program Files\Docker`)
   - Optionally register Docker as a Windows service
   - Optionally add Docker to your system PATH
   - Create Start Menu and Desktop shortcuts
   - Set up uninstaller

### Method 2: PowerShell Installer (Advanced)

Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Docker-ARM64-Installer.ps1
```

#### PowerShell Parameters

```powershell
# Custom installation path
.\Docker-ARM64-Installer.ps1 -InstallPath "C:\MyApps\Docker"

# Don't register as service
.\Docker-ARM64-Installer.ps1 -NoService

# Don't add to PATH
.\Docker-ARM64-Installer.ps1 -NoPath

# Silent installation (no prompts)
.\Docker-ARM64-Installer.ps1 -Silent

# Combine parameters
.\Docker-ARM64-Installer.ps1 -InstallPath "C:\MyApps\Docker" -NoService -Silent
```

## System Requirements

- **Windows 10 version 1803 (build 17134) or later**
- **Windows 11** (any version)
- **ARM64 processor** (e.g., Snapdragon, Apple Silicon via Parallels, etc.)
- **Administrator privileges** for installation

## Post-Installation

### Testing Your Installation

Open a new Command Prompt or PowerShell and run:
```cmd
docker version
```

### Starting Docker Service

If you registered Docker as a service:
```cmd
# Start the service
sc start docker

# Stop the service
sc stop docker

# Check service status
sc query docker
```

### Manual Docker Daemon

If you didn't register the service, you can run Docker manually:
```cmd
# Start Docker daemon manually
dockerd.exe

# In another terminal, use Docker CLI
docker version
```

## Features

- ✅ Native ARM64 compilation
- ✅ Windows service registration
- ✅ System PATH integration
- ✅ Start Menu shortcuts
- ✅ Desktop shortcut
- ✅ Uninstaller included
- ✅ Registry integration (Programs and Features)

## Uninstalling

### Method 1: Through Programs and Features
1. Open "Programs and Features" (appwiz.cpl)
2. Find "Docker for Windows ARM64"
3. Click "Uninstall"

### Method 2: Manual Uninstall
Run as Administrator:
```powershell
& "C:\Program Files\Docker\Uninstall-Docker.ps1"
```

## Troubleshooting

### "Docker service failed to start"
- Ensure you're running Windows 10 1803+ or Windows 11
- Check Windows Event Viewer for detailed error messages
- Try running `dockerd.exe` manually to see error output

### "Command not found: docker"
- Ensure Docker was added to PATH during installation
- Open a new Command Prompt (existing ones won't see PATH changes)
- Manually add `C:\Program Files\Docker` to your PATH

### Permission Issues
- Ensure you ran the installer as Administrator
- Check that Docker files have proper permissions
- Some antivirus software may quarantine the executables

## Version Information

- **Docker CLI Version**: 28.3.3-custom
- **Build Date**: 2025-09-29
- **Architecture**: Windows ARM64
- **Source**: github.com/docker/cli and github.com/moby/moby

## License

This is a custom build of Docker for Windows ARM64. Docker is licensed under the Apache License 2.0.

For the official Docker license, visit: https://github.com/docker/cli/blob/master/LICENSE

## Support

This is a custom build not officially supported by Docker Inc. For issues related to:
- **Docker functionality**: Refer to official Docker documentation
- **This installer**: Check the PowerShell script for error details
- **ARM64 compatibility**: Ensure your Windows version supports the required features

## Security Notes

- Always verify the integrity of the Docker binaries
- Run the installer only with Administrator privileges
- Consider your organization's security policies before installation
- This build includes the same security features as official Docker builds