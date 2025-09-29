# Build Guide - Docker for Windows ARM64

This guide provides detailed instructions for building Docker CLI and Engine for Windows ARM64 architecture from source.

## Prerequisites

### System Requirements

- **Linux development environment** (Ubuntu 20.04+, Fedora 35+, or similar)
- **Go 1.21 or later** - For compiling Docker components
- **Git** - For source code management
- **Make** - For build automation
- **4GB+ RAM** - For compilation process
- **10GB+ disk space** - For source code and build artifacts

### Quick Setup

Run the automated setup script:

```bash
./scripts/setup-environment.sh
```

This will install all required dependencies for your Linux distribution.

### Manual Setup

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y golang git make gcc libc6-dev linux-headers-generic \
                    zip unzip curl wget build-essential
```

#### Fedora/RHEL/CentOS

```bash
sudo dnf install -y golang git make gcc glibc-devel kernel-headers \
                    zip unzip curl wget
```

#### macOS

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install go git make zip curl wget
```

## Build Process

### Automated Build (Recommended)

The easiest way to build everything:

```bash
# Build Docker CLI and Engine
./scripts/build-all.sh

# Create installer package
./scripts/create-installer.sh
```

### Manual Build Process

#### 1. Environment Setup

```bash
# Set cross-compilation environment
export GOOS=windows
export GOARCH=arm64
export CGO_ENABLED=0

# Create build directory
mkdir -p build
```

#### 2. Build Docker CLI

```bash
# Clone Docker CLI source
git clone https://github.com/docker/cli.git docker-cli
cd docker-cli

# Setup Go modules (Docker CLI uses vendor.mod)
cp vendor.mod go.mod

# Build CLI for Windows ARM64
GOOS=windows GOARCH=arm64 go build \
  -mod=vendor \
  -ldflags "-X github.com/docker/cli/cli/version.GitCommit=$(git rev-parse --short HEAD) \
            -X github.com/docker/cli/cli/version.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
            -X github.com/docker/cli/cli/version.Version=$(git describe --tags --always)" \
  -o ../build/docker-windows-arm64.exe \
  ./cmd/docker

cd ..
```

#### 3. Build Docker Engine

```bash
# Clone Docker Engine (Moby) source
git clone https://github.com/moby/moby.git docker-engine
cd docker-engine

# Build Engine for Windows ARM64
GOOS=windows GOARCH=arm64 go build \
  -o ../build/dockerd-windows-arm64.exe \
  ./cmd/dockerd

cd ..
```

#### 4. Verify Build

```bash
# Check that binaries were created
ls -la build/

# Verify architecture (if file command is available)
file build/docker-windows-arm64.exe
file build/dockerd-windows-arm64.exe

# Expected output should show: "PE32+ executable ... ARM64"
```

## Build Configuration

### Cross-Compilation Settings

| Variable | Value | Purpose |
|----------|--------|---------|
| `GOOS` | `windows` | Target operating system |
| `GOARCH` | `arm64` | Target processor architecture |
| `CGO_ENABLED` | `0` | Disable CGO for static compilation |

### Build Flags

#### Docker CLI Build Flags

```bash
-mod=vendor                    # Use vendored dependencies
-ldflags "-X ..."             # Set version information
-o docker-windows-arm64.exe    # Output filename
```

#### Docker Engine Build Flags

```bash
-o dockerd-windows-arm64.exe   # Output filename
```

### Version Information

The build process embeds version information into the binaries:

- **GitCommit**: Short Git commit hash
- **BuildTime**: UTC timestamp of build
- **Version**: Git tag or commit description

## Troubleshooting

### Common Issues

#### 1. Go Version Too Old

**Error**: `package embed is not in GOROOT`

**Solution**: Upgrade to Go 1.21 or later:

```bash
# Remove old Go
sudo rm -rf /usr/local/go

# Download and install latest Go
wget https://go.dev/dl/go1.23.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.linux-amd64.tar.gz

# Update PATH
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### 2. Module Download Failures

**Error**: `go: module not found`

**Solution**: Ensure internet connectivity and clean module cache:

```bash
go clean -modcache
go mod download
```

#### 3. Cross-Compilation Issues

**Error**: `cannot find package`

**Solution**: Verify cross-compilation environment:

```bash
go env GOOS GOARCH
# Should show: windows arm64

# Test cross-compilation
cat > test.go << 'EOF'
package main
import "fmt"
func main() { fmt.Println("test") }
EOF

GOOS=windows GOARCH=arm64 go build test.go
```

#### 4. Build Size Issues

**Problem**: Binaries are very large

**Solution**: Use build flags to reduce size:

```bash
go build -ldflags "-s -w" ...  # Strip debug info
```

#### 5. Docker CLI vendor.mod Issues

**Error**: `cannot find main module`

**Solution**: Ensure vendor.mod is copied to go.mod:

```bash
cd docker-cli
cp vendor.mod go.mod
```

### Performance Optimization

#### Parallel Builds

Build both components in parallel:

```bash
# Build CLI in background
(cd docker-cli && GOOS=windows GOARCH=arm64 go build ...) &

# Build Engine in background
(cd docker-engine && GOOS=windows GOARCH=arm64 go build ...) &

# Wait for both to complete
wait
```

#### Build Cache

Enable Go build cache for faster rebuilds:

```bash
export GOCACHE=$HOME/.cache/go-build
```

#### Module Cache

Reuse downloaded modules:

```bash
export GOMODCACHE=$HOME/go/pkg/mod
```

## Advanced Configuration

### Custom Build Tags

Add build tags for specific features:

```bash
go build -tags "feature1,feature2" ...
```

### Custom LDFLAGS

Override default version information:

```bash
CUSTOM_VERSION="v1.0.0-custom"
CUSTOM_COMMIT="abc123"

go build -ldflags "-X github.com/docker/cli/cli/version.Version=$CUSTOM_VERSION \
                   -X github.com/docker/cli/cli/version.GitCommit=$CUSTOM_COMMIT" ...
```

### Static vs Dynamic Linking

For maximum compatibility, use static linking (default):

```bash
export CGO_ENABLED=0  # Static linking
```

For specific Windows features, dynamic linking may be required:

```bash
export CGO_ENABLED=1  # Dynamic linking (requires Windows cross-compilation tools)
```

## Validation

### Binary Verification

```bash
# Check binary properties
file build/docker-windows-arm64.exe build/dockerd-windows-arm64.exe

# Expected output:
# docker-windows-arm64.exe: PE32+ executable for MS Windows, ARM64
# dockerd-windows-arm64.exe: PE32+ executable for MS Windows, ARM64
```

### Size Validation

```bash
# Check binary sizes
ls -lh build/

# Typical sizes:
# docker-windows-arm64.exe:  ~40MB
# dockerd-windows-arm64.exe: ~90MB
```

### Dependency Check

```bash
# Verify no Linux dependencies (should show only Windows)
objdump -p build/docker-windows-arm64.exe | grep DLL || echo "Static binary"
```

## Build Scripts

The repository includes several build scripts:

| Script | Purpose |
|--------|---------|
| `scripts/build-all.sh` | Complete build process |
| `scripts/build-docker.sh` | Docker components only |
| `scripts/setup-environment.sh` | Development environment setup |
| `scripts/clean.sh` | Clean build artifacts |
| `scripts/validate-environment.sh` | Check build environment |

### Script Usage

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Setup environment (first time only)
./scripts/setup-environment.sh

# Build everything
./scripts/build-all.sh

# Clean build artifacts
./scripts/clean.sh --build

# Validate environment
./scripts/validate-environment.sh
```

## Continuous Integration

The repository includes GitHub Actions workflows for automated building:

- **`.github/workflows/build.yml`** - Build on push/PR
- **`.github/workflows/release.yml`** - Create releases on tags

### Local CI Simulation

Test the build process locally using the same steps as CI:

```bash
# Simulate CI environment
export CI=true
export GITHUB_WORKSPACE=$(pwd)

# Run build steps
./scripts/build-all.sh
```

## Contributing

### Build Environment

When contributing, ensure your build environment matches the CI:

- Go 1.23 (latest stable)
- Linux-based build system
- Same cross-compilation settings

### Build Verification

Before submitting changes, verify builds work:

```bash
# Clean build
./scripts/clean.sh --all

# Fresh build
./scripts/build-all.sh

# Create installer
./scripts/create-installer.sh
```

### Code Quality

Run quality checks:

```bash
# Format code
go fmt ./...

# Vet code
go vet ./...

# Lint (if golangci-lint is installed)
golangci-lint run
```

## Next Steps

After successful build:

1. **[Create Installer](../scripts/create-installer.sh)** - Package for distribution
2. **[Test Installation](INSTALL.md)** - Verify on Windows ARM64
3. **[Troubleshooting](TROUBLESHOOTING.md)** - Resolve any issues

For questions or issues, see [CONTRIBUTING.md](CONTRIBUTING.md) or open a GitHub issue.