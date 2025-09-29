#!/bin/bash
set -euo pipefail

# Docker for Windows ARM64 - Development Environment Setup
# Sets up the development environment with all required dependencies

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

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat Enterprise Linux"
        VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    log_info "Detected OS: $OS $VER"
}

# Install dependencies for Fedora/RHEL/CentOS
install_fedora_deps() {
    log_info "Installing dependencies for Fedora/RHEL/CentOS..."

    sudo dnf update -y

    # Install basic development tools
    sudo dnf install -y \
        golang \
        git \
        make \
        gcc \
        glibc-devel \
        kernel-headers \
        zip \
        unzip \
        curl \
        wget

    # Install NSIS for advanced installer creation (optional)
    sudo dnf install -y mingw64-nsis || log_warning "NSIS installation failed (optional)"

    log_success "Fedora/RHEL/CentOS dependencies installed"
}

# Install dependencies for Ubuntu/Debian
install_ubuntu_deps() {
    log_info "Installing dependencies for Ubuntu/Debian..."

    sudo apt update

    # Install basic development tools
    sudo apt install -y \
        golang \
        git \
        make \
        gcc \
        libc6-dev \
        linux-headers-generic \
        zip \
        unzip \
        curl \
        wget \
        build-essential

    # Install NSIS for advanced installer creation (optional)
    sudo apt install -y nsis || log_warning "NSIS installation failed (optional)"

    log_success "Ubuntu/Debian dependencies installed"
}

# Install dependencies for macOS
install_macos_deps() {
    log_info "Installing dependencies for macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install dependencies via Homebrew
    brew install \
        go \
        git \
        make \
        zip \
        curl \
        wget

    log_success "macOS dependencies installed"
}

# Verify Go installation
verify_go() {
    log_info "Verifying Go installation..."

    if ! command -v go &> /dev/null; then
        log_error "Go is not installed or not in PATH"
        return 1
    fi

    GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    REQUIRED_VERSION="1.21"

    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        log_success "Go $GO_VERSION is installed and meets requirements"
    else
        log_warning "Go $GO_VERSION is installed but version 1.21+ is recommended"
    fi

    # Display Go environment
    log_info "Go environment:"
    go env GOOS GOARCH GOVERSION GOROOT GOPATH
}

# Configure Go environment
configure_go() {
    log_info "Configuring Go environment..."

    # Ensure GOPATH is set if not using modules globally
    if [ -z "${GOPATH:-}" ]; then
        GOPATH="$HOME/go"
        echo "export GOPATH=$GOPATH" >> ~/.bashrc
        export GOPATH
        mkdir -p "$GOPATH"
        log_info "GOPATH set to: $GOPATH"
    fi

    # Ensure Go binary directory is in PATH
    GO_BIN_DIR="$(go env GOPATH)/bin"
    if [[ ":$PATH:" != *":$GO_BIN_DIR:"* ]]; then
        echo "export PATH=\$PATH:$GO_BIN_DIR" >> ~/.bashrc
        export PATH="$PATH:$GO_BIN_DIR"
        log_info "Added Go bin directory to PATH: $GO_BIN_DIR"
    fi

    log_success "Go environment configured"
}

# Install additional Go tools
install_go_tools() {
    log_info "Installing additional Go tools..."

    # Install useful Go tools for development
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest || log_warning "Failed to install golangci-lint"
    go install golang.org/x/tools/cmd/goimports@latest || log_warning "Failed to install goimports"
    go install github.com/go-delve/delve/cmd/dlv@latest || log_warning "Failed to install delve debugger"

    log_success "Additional Go tools installed"
}

# Test cross-compilation
test_cross_compilation() {
    log_info "Testing cross-compilation capabilities..."

    # Create a test program
    TEST_DIR=$(mktemp -d)
    cat > "$TEST_DIR/main.go" << 'EOF'
package main

import (
    "fmt"
    "runtime"
)

func main() {
    fmt.Printf("Hello from %s/%s\n", runtime.GOOS, runtime.GOARCH)
}
EOF

    cd "$TEST_DIR"

    # Test Windows ARM64 compilation
    log_info "Testing Windows ARM64 cross-compilation..."
    GOOS=windows GOARCH=arm64 go build -o test-windows-arm64.exe main.go

    if [ -f "test-windows-arm64.exe" ]; then
        log_success "Windows ARM64 cross-compilation works"

        # Verify architecture if file command is available
        if command -v file &> /dev/null; then
            ARCH=$(file test-windows-arm64.exe | grep -o "ARM64" || echo "")
            if [ "$ARCH" = "ARM64" ]; then
                log_success "Binary architecture verified: ARM64"
            fi
        fi
    else
        log_error "Windows ARM64 cross-compilation failed"
        return 1
    fi

    # Cleanup
    rm -rf "$TEST_DIR"
    cd - > /dev/null

    log_success "Cross-compilation test completed"
}

# Create development directories
setup_directories() {
    log_info "Setting up development directories..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

    # Create necessary directories
    mkdir -p "$PROJECT_ROOT"/{build,releases,docs}

    log_info "Created directories:"
    log_info "  - $PROJECT_ROOT/build (for compiled binaries)"
    log_info "  - $PROJECT_ROOT/releases (for release packages)"
    log_info "  - $PROJECT_ROOT/docs (for documentation)"

    log_success "Development directories created"
}

# Create environment validation script
create_validation_script() {
    log_info "Creating environment validation script..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VALIDATION_SCRIPT="$SCRIPT_DIR/validate-environment.sh"

    cat > "$VALIDATION_SCRIPT" << 'EOF'
#!/bin/bash
# Docker for Windows ARM64 - Environment Validation

echo "Docker for Windows ARM64 - Environment Validation"
echo "================================================"

# Check Go
if command -v go &> /dev/null; then
    echo "✓ Go: $(go version)"
else
    echo "✗ Go: Not installed"
fi

# Check Git
if command -v git &> /dev/null; then
    echo "✓ Git: $(git --version)"
else
    echo "✗ Git: Not installed"
fi

# Check Make
if command -v make &> /dev/null; then
    echo "✓ Make: $(make --version | head -1)"
else
    echo "✗ Make: Not installed"
fi

# Check file command
if command -v file &> /dev/null; then
    echo "✓ File: Available for binary verification"
else
    echo "? File: Not available (binary verification will be skipped)"
fi

# Check zip
if command -v zip &> /dev/null; then
    echo "✓ Zip: Available for package creation"
else
    echo "? Zip: Not available (will use tar.gz instead)"
fi

# Test cross-compilation
echo ""
echo "Testing cross-compilation..."
TEMP_DIR=$(mktemp -d)
echo 'package main; import "fmt"; func main() { fmt.Println("test") }' > "$TEMP_DIR/test.go"
cd "$TEMP_DIR"

if GOOS=windows GOARCH=arm64 go build -o test.exe test.go 2>/dev/null; then
    echo "✓ Windows ARM64 cross-compilation: Working"
else
    echo "✗ Windows ARM64 cross-compilation: Failed"
fi

rm -rf "$TEMP_DIR"

echo ""
echo "Environment validation completed!"
EOF

    chmod +x "$VALIDATION_SCRIPT"
    log_success "Environment validation script created: $VALIDATION_SCRIPT"
}

# Main setup function
main() {
    log_info "Setting up Docker for Windows ARM64 development environment..."

    detect_os

    # Install dependencies based on OS
    case "$OS" in
        *"Fedora"*|*"Red Hat"*|*"CentOS"*|*"Rocky"*|*"AlmaLinux"*)
            install_fedora_deps
            ;;
        *"Ubuntu"*|*"Debian"*)
            install_ubuntu_deps
            ;;
        *"Darwin"*)
            install_macos_deps
            ;;
        *)
            log_warning "Unsupported OS: $OS"
            log_info "Please install the following manually:"
            log_info "  - Go 1.21+"
            log_info "  - Git"
            log_info "  - Make"
            log_info "  - ZIP/unzip utilities"
            ;;
    esac

    # Common setup steps
    verify_go
    configure_go
    install_go_tools
    test_cross_compilation
    setup_directories
    create_validation_script

    log_success ""
    log_success "Development environment setup completed!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Restart your shell or run: source ~/.bashrc"
    log_info "  2. Validate environment: ./scripts/validate-environment.sh"
    log_info "  3. Build Docker: ./scripts/build-all.sh"
    log_info "  4. Create installer: ./scripts/create-installer.sh"
    log_info ""
    log_info "For help: cat README.md"
}

# Handle script interruption
cleanup() {
    log_warning "Setup interrupted"
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"