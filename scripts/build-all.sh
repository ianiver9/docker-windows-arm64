#!/bin/bash
set -euo pipefail

# Docker for Windows ARM64 - Complete Build Script
# This script builds Docker CLI, Engine, and creates the installer package

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
DOCKER_CLI_DIR="$PROJECT_ROOT/docker-cli"
DOCKER_ENGINE_DIR="$PROJECT_ROOT/docker-engine"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Go installation
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed. Please install Go 1.23 or later."
        exit 1
    fi

    # Check Go version
    GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    REQUIRED_VERSION="1.23"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        log_success "Go $GO_VERSION is installed"
    else
        log_warning "Go $GO_VERSION found, but 1.23+ is recommended"
    fi

    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install Git."
        exit 1
    fi

    # Check Make
    if ! command -v make &> /dev/null; then
        log_warning "Make is not installed. Some features may not work."
    fi

    log_success "Prerequisites check completed"
}

# Setup build environment
setup_environment() {
    log_info "Setting up build environment..."

    # Create build directory
    mkdir -p "$BUILD_DIR"

    # Set Go environment for cross-compilation
    export GOOS=windows
    export GOARCH=arm64
    export CGO_ENABLED=0

    log_success "Build environment configured for Windows ARM64"
}

# Clone or update Docker CLI source
setup_docker_cli() {
    log_info "Setting up Docker CLI source..."

    if [ ! -d "$DOCKER_CLI_DIR" ]; then
        log_info "Cloning Docker CLI repository..."
        git clone https://github.com/docker/cli.git "$DOCKER_CLI_DIR"
    else
        log_info "Docker CLI repository already exists, updating..."
        cd "$DOCKER_CLI_DIR"
        git fetch origin
        git reset --hard origin/master
    fi

    cd "$DOCKER_CLI_DIR"

    # Get current version
    CLI_VERSION=$(git describe --tags --always)
    log_info "Docker CLI version: $CLI_VERSION"

    # Setup go.mod from vendor.mod
    if [ -f "vendor.mod" ]; then
        cp vendor.mod go.mod
        log_success "Configured Docker CLI for module builds"
    else
        log_error "vendor.mod not found in Docker CLI repository"
        exit 1
    fi
}

# Clone or update Docker Engine (Moby) source
setup_docker_engine() {
    log_info "Setting up Docker Engine source..."

    if [ ! -d "$DOCKER_ENGINE_DIR" ]; then
        log_info "Cloning Docker Engine (Moby) repository..."
        git clone https://github.com/moby/moby.git "$DOCKER_ENGINE_DIR"
    else
        log_info "Docker Engine repository already exists, updating..."
        cd "$DOCKER_ENGINE_DIR"
        git fetch origin
        git reset --hard origin/master
    fi

    cd "$DOCKER_ENGINE_DIR"

    # Get current version
    ENGINE_VERSION=$(git describe --tags --always)
    log_info "Docker Engine version: $ENGINE_VERSION"
}

# Build Docker CLI
build_docker_cli() {
    log_info "Building Docker CLI..."

    cd "$DOCKER_CLI_DIR"

    # Set build variables
    GITCOMMIT=$(git rev-parse --short HEAD)
    BUILDTIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    VERSION=$(git describe --tags --always | sed 's/^v//')

    # Build CLI
    log_info "Compiling Docker CLI for Windows ARM64..."
    go build \
        -mod=vendor \
        -ldflags "-X github.com/docker/cli/cli/version.GitCommit=$GITCOMMIT -X github.com/docker/cli/cli/version.BuildTime=$BUILDTIME -X github.com/docker/cli/cli/version.Version=$VERSION" \
        -o "$BUILD_DIR/docker-windows-arm64.exe" \
        ./cmd/docker

    if [ -f "$BUILD_DIR/docker-windows-arm64.exe" ]; then
        log_success "Docker CLI built successfully"
        # Check file size
        CLI_SIZE=$(du -h "$BUILD_DIR/docker-windows-arm64.exe" | cut -f1)
        log_info "Docker CLI size: $CLI_SIZE"
    else
        log_error "Failed to build Docker CLI"
        exit 1
    fi
}

# Build Docker Engine
build_docker_engine() {
    log_info "Building Docker Engine..."

    cd "$DOCKER_ENGINE_DIR"

    # Build Engine
    log_info "Compiling Docker Engine for Windows ARM64..."
    go build \
        -o "$BUILD_DIR/dockerd-windows-arm64.exe" \
        ./cmd/dockerd

    if [ -f "$BUILD_DIR/dockerd-windows-arm64.exe" ]; then
        log_success "Docker Engine built successfully"
        # Check file size
        ENGINE_SIZE=$(du -h "$BUILD_DIR/dockerd-windows-arm64.exe" | cut -f1)
        log_info "Docker Engine size: $ENGINE_SIZE"
    else
        log_error "Failed to build Docker Engine"
        exit 1
    fi
}

# Verify binaries
verify_binaries() {
    log_info "Verifying built binaries..."

    if command -v file &> /dev/null; then
        log_info "Docker CLI architecture:"
        file "$BUILD_DIR/docker-windows-arm64.exe"

        log_info "Docker Engine architecture:"
        file "$BUILD_DIR/dockerd-windows-arm64.exe"
    else
        log_warning "file command not available, skipping architecture verification"
    fi

    # Check file sizes
    CLI_SIZE_BYTES=$(stat -f%z "$BUILD_DIR/docker-windows-arm64.exe" 2>/dev/null || stat -c%s "$BUILD_DIR/docker-windows-arm64.exe" 2>/dev/null || echo "unknown")
    ENGINE_SIZE_BYTES=$(stat -f%z "$BUILD_DIR/dockerd-windows-arm64.exe" 2>/dev/null || stat -c%s "$BUILD_DIR/dockerd-windows-arm64.exe" 2>/dev/null || echo "unknown")

    log_info "Binary sizes:"
    log_info "  Docker CLI: $CLI_SIZE_BYTES bytes"
    log_info "  Docker Engine: $ENGINE_SIZE_BYTES bytes"

    # Basic validation - check that files are not empty
    if [ ! -s "$BUILD_DIR/docker-windows-arm64.exe" ]; then
        log_error "Docker CLI binary is empty or missing"
        exit 1
    fi

    if [ ! -s "$BUILD_DIR/dockerd-windows-arm64.exe" ]; then
        log_error "Docker Engine binary is empty or missing"
        exit 1
    fi

    log_success "Binary verification completed"
}

# Create build info file
create_build_info() {
    log_info "Creating build information file..."

    cat > "$BUILD_DIR/build-info.txt" << EOF
Docker for Windows ARM64 - Build Information
==========================================

Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Build Host: $(hostname)
Build User: $(whoami)
Go Version: $(go version)

Docker CLI:
  Source: https://github.com/docker/cli.git
  Commit: $(cd "$DOCKER_CLI_DIR" && git rev-parse HEAD)
  Version: $(cd "$DOCKER_CLI_DIR" && git describe --tags --always)

Docker Engine:
  Source: https://github.com/moby/moby.git
  Commit: $(cd "$DOCKER_ENGINE_DIR" && git rev-parse HEAD)
  Version: $(cd "$DOCKER_ENGINE_DIR" && git describe --tags --always)

Build Configuration:
  GOOS: windows
  GOARCH: arm64
  CGO_ENABLED: 0

Files Built:
  - docker-windows-arm64.exe
  - dockerd-windows-arm64.exe
EOF

    log_success "Build information saved to build-info.txt"
}

# Main build function
main() {
    log_info "Starting Docker for Windows ARM64 build process..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "Build directory: $BUILD_DIR"

    # Run build steps
    check_prerequisites
    setup_environment
    setup_docker_cli
    setup_docker_engine
    build_docker_cli
    build_docker_engine
    verify_binaries
    create_build_info

    log_success "Build process completed successfully!"
    log_info ""
    log_info "Built files:"
    log_info "  - $BUILD_DIR/docker-windows-arm64.exe"
    log_info "  - $BUILD_DIR/dockerd-windows-arm64.exe"
    log_info "  - $BUILD_DIR/build-info.txt"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Run './scripts/create-installer.sh' to create the installer package"
    log_info "  2. Transfer files to a Windows ARM64 system for testing"
    log_info "  3. Test installation using the installer package"
}

# Handle script interruption
cleanup() {
    log_warning "Build process interrupted"
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"