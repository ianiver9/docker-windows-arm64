# Docker for Windows ARM64

A custom build of Docker CLI and Engine specifically compiled for Windows ARM64 architecture, complete with a professional installer.

![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![ARM64](https://img.shields.io/badge/ARM64-FF6B35?style=for-the-badge&logo=arm&logoColor=white)

## 🚀 Quick Start

### For End Users

1. **Download** the latest release from [Releases](../../releases)
2. **Extract** the installer package
3. **Right-click** `Install-Docker.bat` and select "Run as administrator"
4. **Follow** the installation prompts
5. **Test** your installation: `docker version`

### For Developers

```bash
# Clone the repository
git clone https://github.com/your-username/docker-windows-arm64.git
cd docker-windows-arm64

# Build Docker components
./scripts/build-all.sh

# Create installer package
./scripts/create-installer.sh
```

## 📋 What's Included

- **Docker CLI** (`docker.exe`) - Full Docker command-line interface
- **Docker Engine** (`dockerd.exe`) - Docker daemon for container management
- **Professional Installer** - Windows service registration, PATH integration, shortcuts
- **Build Scripts** - Complete build environment for developers
- **Documentation** - Comprehensive guides and troubleshooting

## 🏗️ Architecture Support

| Platform | Architecture | Status |
|----------|-------------|---------|
| Windows 10 1803+ | ARM64 | ✅ Supported |
| Windows 11 | ARM64 | ✅ Supported |
| Windows 10 | x86_64 | ❌ Use official Docker |
| Windows 11 | x86_64 | ❌ Use official Docker |

## 🛠️ Developer Setup

### Prerequisites

- **Linux build environment** (Fedora, Ubuntu, or similar)
- **Go 1.23+** - For building Docker components
- **Git** - For source code management
- **Make** - For build automation
- **NSIS** (optional) - For advanced installer creation

### Quick Setup Script

```bash
# On Fedora/RHEL
sudo dnf install -y golang git make mingw64-nsis

# On Ubuntu/Debian
sudo apt update
sudo apt install -y golang git make nsis

# Verify installation
go version
git --version
make --version
```

### Building from Source

1. **Clone Dependencies**
   ```bash
   git clone https://github.com/docker/cli.git
   git clone https://github.com/moby/moby.git
   ```

2. **Build Docker CLI**
   ```bash
   cd cli
   cp vendor.mod go.mod
   GOOS=windows GOARCH=arm64 go build -mod=vendor -o ../build/docker-windows-arm64.exe ./cmd/docker
   ```

3. **Build Docker Engine**
   ```bash
   cd ../moby
   GOOS=windows GOARCH=arm64 go build -o ../build/dockerd-windows-arm64.exe ./cmd/dockerd
   ```

4. **Create Installer**
   ```bash
   cd ../installer
   # Copy binaries and run installer creation
   ```

### Automated Build

Use our build scripts for a streamlined process:

```bash
# Build everything
./scripts/build-all.sh

# Build only Docker components
./scripts/build-docker.sh

# Create installer package
./scripts/create-installer.sh

# Clean build artifacts
./scripts/clean.sh
```

## 📦 Repository Structure

```
docker-windows-arm64/
├── README.md                           # This file
├── LICENSE                            # License information
├── .gitignore                         # Git ignore rules
├── .github/
│   └── workflows/
│       ├── build.yml                  # Automated builds
│       └── release.yml                # Release automation
├── scripts/
│   ├── build-all.sh                   # Complete build script
│   ├── build-docker.sh                # Docker components only
│   ├── create-installer.sh            # Installer creation
│   ├── setup-environment.sh           # Development environment setup
│   └── clean.sh                       # Cleanup script
├── installer/
│   ├── Install-Docker.bat             # User-friendly installer
│   ├── Docker-ARM64-Installer.ps1     # PowerShell installer
│   ├── README.md                      # Installer documentation
│   └── LICENSE.txt                    # License for installer
├── build/                             # Build outputs (gitignored)
│   ├── docker-windows-arm64.exe
│   └── dockerd-windows-arm64.exe
├── releases/                          # Release packages (gitignored)
└── docs/
    ├── BUILD.md                       # Detailed build instructions
    ├── INSTALL.md                     # Installation guide
    ├── TROUBLESHOOTING.md             # Common issues and solutions
    └── CONTRIBUTING.md                # Contribution guidelines
```

## 🔧 Build Environment Details

### Docker CLI Build

The Docker CLI is built from the official [docker/cli](https://github.com/docker/cli) repository:

- **Source**: Latest stable release
- **Module Mode**: Vendor mode (`vendor.mod` → `go.mod`)
- **Target**: `windows/arm64`
- **Output**: `docker-windows-arm64.exe`

### Docker Engine Build

The Docker Engine is built from the [moby/moby](https://github.com/moby/moby) repository:

- **Source**: Latest stable release
- **Module Mode**: Standard Go modules
- **Target**: `windows/arm64`
- **Output**: `dockerd-windows-arm64.exe`

### Cross-Compilation Setup

```bash
# Set cross-compilation targets
export GOOS=windows
export GOARCH=arm64
export CGO_ENABLED=0

# Build with vendor dependencies
go build -mod=vendor -o output.exe ./cmd/target
```

## 🚀 Installation Features

### Installer Capabilities

- ✅ **Windows Service Registration** - Auto-start Docker with Windows
- ✅ **System PATH Integration** - Use `docker` from any terminal
- ✅ **Start Menu Shortcuts** - Easy access to Docker CLI
- ✅ **Desktop Shortcuts** - Quick Docker version check
- ✅ **Uninstaller** - Clean removal of all components
- ✅ **Registry Integration** - Appears in Programs & Features
- ✅ **Data Directory Setup** - Proper Docker data storage

### Installation Options

| Feature | Default | Description |
|---------|---------|-------------|
| Installation Path | `C:\Program Files\Docker` | Where Docker binaries are installed |
| Windows Service | Yes | Register Docker as auto-starting service |
| System PATH | Yes | Add Docker to system PATH |
| Shortcuts | Yes | Create Start Menu and Desktop shortcuts |

## 🧪 Testing

### Manual Testing

```bash
# Test Docker CLI
./build/docker-windows-arm64.exe version

# Test Docker Engine (requires Windows)
./build/dockerd-windows-arm64.exe --version
```

### Automated Testing

```bash
# Run all tests
./scripts/test-all.sh

# Test builds only
./scripts/test-builds.sh

# Test installer (requires Windows VM)
./scripts/test-installer.sh
```

## 📖 Documentation

- **[Build Guide](docs/BUILD.md)** - Detailed build instructions and troubleshooting
- **[Installation Guide](docs/INSTALL.md)** - Complete installation and configuration
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Contributing](docs/CONTRIBUTING.md)** - How to contribute to this project

## 🐛 Known Issues

- **Docker Compose**: Not included in this build (use pip install docker-compose)
- **Windows Containers**: Limited testing on ARM64 Windows
- **Hyper-V**: May require manual configuration on some ARM64 systems

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes (`./scripts/test-all.sh`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project contains custom build scripts and installers for Docker, which is licensed under the Apache License 2.0.

- **Docker CLI**: [Apache License 2.0](https://github.com/docker/cli/blob/master/LICENSE)
- **Docker Engine (Moby)**: [Apache License 2.0](https://github.com/moby/moby/blob/master/LICENSE)
- **This Repository**: [Apache License 2.0](LICENSE)

## 🙏 Acknowledgments

- **Docker Inc.** - For creating Docker and maintaining the open-source codebase
- **Moby Project** - For the Docker Engine implementation
- **Microsoft** - For Windows ARM64 support and development tools
- **Community** - For testing, feedback, and contributions

## 📞 Support

### Community Support

- **GitHub Issues**: [Report bugs and request features](../../issues)
- **Discussions**: [Ask questions and share ideas](../../discussions)

### Commercial Support

This is a community project and not officially supported by Docker Inc. For official Docker support:

- **Docker Official**: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- **Docker Documentation**: [docs.docker.com](https://docs.docker.com/)

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-09-29 | Initial release with Docker CLI and Engine |
| - | - | Professional installer with service registration |
| - | - | Complete build environment and documentation |

---

**⚠️ Disclaimer**: This is a custom build of Docker for Windows ARM64. While based on official Docker source code, it is not officially supported by Docker Inc. Use at your own risk and ensure compliance with your organization's software policies.