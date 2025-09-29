#!/bin/bash
set -euo pipefail

# Docker for Windows ARM64 - Cleanup Script
# Removes build artifacts and temporary files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# Show usage
show_usage() {
    echo "Docker for Windows ARM64 - Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all, -a       Clean everything (build artifacts, sources, releases)"
    echo "  --build, -b     Clean only build artifacts"
    echo "  --sources, -s   Clean only source repositories"
    echo "  --releases, -r  Clean only release packages"
    echo "  --installer, -i Clean installer binaries"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --build           # Clean only build artifacts"
    echo "  $0 --all             # Clean everything"
    echo "  $0 -b -i             # Clean build artifacts and installer binaries"
}

# Clean build artifacts
clean_build() {
    local build_dir="$PROJECT_ROOT/build"

    if [ -d "$build_dir" ]; then
        log_info "Cleaning build artifacts..."

        # List what will be removed
        if [ "$(ls -A "$build_dir" 2>/dev/null)" ]; then
            log_info "Removing:"
            ls -la "$build_dir" | grep -v "^total" | tail -n +2 | while read -r line; do
                echo "  - $(echo "$line" | awk '{print $9}')"
            done

            rm -rf "$build_dir"/*
            log_success "Build artifacts cleaned"
        else
            log_info "Build directory is already clean"
        fi
    else
        log_info "Build directory doesn't exist"
    fi
}

# Clean source repositories
clean_sources() {
    log_info "Cleaning source repositories..."

    local cleaned_any=false

    # Clean Docker CLI source
    if [ -d "$PROJECT_ROOT/docker-cli" ]; then
        log_info "Removing Docker CLI source..."
        rm -rf "$PROJECT_ROOT/docker-cli"
        cleaned_any=true
    fi

    # Clean Docker Engine source
    if [ -d "$PROJECT_ROOT/docker-engine" ]; then
        log_info "Removing Docker Engine source..."
        rm -rf "$PROJECT_ROOT/docker-engine"
        cleaned_any=true
    fi

    if $cleaned_any; then
        log_success "Source repositories cleaned"
    else
        log_info "No source repositories found"
    fi
}

# Clean release packages
clean_releases() {
    local releases_dir="$PROJECT_ROOT/releases"

    if [ -d "$releases_dir" ]; then
        log_info "Cleaning release packages..."

        # List what will be removed
        if [ "$(ls -A "$releases_dir" 2>/dev/null)" ]; then
            log_info "Removing:"
            ls -la "$releases_dir" | grep -v "^total" | tail -n +2 | while read -r line; do
                echo "  - $(echo "$line" | awk '{print $9}')"
            done

            rm -rf "$releases_dir"/*
            log_success "Release packages cleaned"
        else
            log_info "Releases directory is already clean"
        fi
    else
        log_info "Releases directory doesn't exist"
    fi
}

# Clean installer binaries
clean_installer() {
    local installer_dir="$PROJECT_ROOT/installer"

    if [ -d "$installer_dir" ]; then
        log_info "Cleaning installer binaries..."

        # Remove only the executable files, keep scripts and docs
        local cleaned_any=false

        if [ -f "$installer_dir/docker-windows-arm64.exe" ]; then
            rm -f "$installer_dir/docker-windows-arm64.exe"
            log_info "Removed: docker-windows-arm64.exe"
            cleaned_any=true
        fi

        if [ -f "$installer_dir/dockerd-windows-arm64.exe" ]; then
            rm -f "$installer_dir/dockerd-windows-arm64.exe"
            log_info "Removed: dockerd-windows-arm64.exe"
            cleaned_any=true
        fi

        if $cleaned_any; then
            log_success "Installer binaries cleaned"
        else
            log_info "No installer binaries found"
        fi
    else
        log_info "Installer directory doesn't exist"
    fi
}

# Clean Go module cache (optional)
clean_go_cache() {
    log_info "Cleaning Go module cache..."

    if command -v go &> /dev/null; then
        # Clean Go module cache
        go clean -modcache
        log_success "Go module cache cleaned"
    else
        log_warning "Go not found, skipping module cache cleanup"
    fi
}

# Clean temporary files
clean_temp() {
    log_info "Cleaning temporary files..."

    # Find and remove common temporary files
    find "$PROJECT_ROOT" -name "*.tmp" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name ".DS_Store" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name "Thumbs.db" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name "*.log" -type f -delete 2>/dev/null || true

    log_success "Temporary files cleaned"
}

# Show what would be cleaned (dry run)
show_cleanup_plan() {
    log_info "Cleanup Plan:"
    log_info "============="

    # Check build directory
    if [ -d "$PROJECT_ROOT/build" ] && [ "$(ls -A "$PROJECT_ROOT/build" 2>/dev/null)" ]; then
        log_info "Build artifacts ($(du -sh "$PROJECT_ROOT/build" 2>/dev/null | cut -f1)):"
        ls -la "$PROJECT_ROOT/build" | grep -v "^total" | tail -n +2 | while read -r line; do
            echo "  - $(echo "$line" | awk '{print $9}')"
        done
    fi

    # Check sources
    if [ -d "$PROJECT_ROOT/docker-cli" ]; then
        local cli_size=$(du -sh "$PROJECT_ROOT/docker-cli" 2>/dev/null | cut -f1)
        log_info "Docker CLI source ($cli_size)"
    fi

    if [ -d "$PROJECT_ROOT/docker-engine" ]; then
        local engine_size=$(du -sh "$PROJECT_ROOT/docker-engine" 2>/dev/null | cut -f1)
        log_info "Docker Engine source ($engine_size)"
    fi

    # Check releases
    if [ -d "$PROJECT_ROOT/releases" ] && [ "$(ls -A "$PROJECT_ROOT/releases" 2>/dev/null)" ]; then
        log_info "Release packages ($(du -sh "$PROJECT_ROOT/releases" 2>/dev/null | cut -f1)):"
        ls -la "$PROJECT_ROOT/releases" | grep -v "^total" | tail -n +2 | while read -r line; do
            echo "  - $(echo "$line" | awk '{print $9}')"
        done
    fi

    # Check installer binaries
    if [ -f "$PROJECT_ROOT/installer/docker-windows-arm64.exe" ] || [ -f "$PROJECT_ROOT/installer/dockerd-windows-arm64.exe" ]; then
        log_info "Installer binaries:"
        [ -f "$PROJECT_ROOT/installer/docker-windows-arm64.exe" ] && echo "  - docker-windows-arm64.exe"
        [ -f "$PROJECT_ROOT/installer/dockerd-windows-arm64.exe" ] && echo "  - dockerd-windows-arm64.exe"
    fi
}

# Main cleanup function
main() {
    local clean_build=false
    local clean_sources=false
    local clean_releases=false
    local clean_installer=false
    local clean_all=false
    local show_plan=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all|-a)
                clean_all=true
                shift
                ;;
            --build|-b)
                clean_build=true
                shift
                ;;
            --sources|-s)
                clean_sources=true
                shift
                ;;
            --releases|-r)
                clean_releases=true
                shift
                ;;
            --installer|-i)
                clean_installer=true
                shift
                ;;
            --plan|-p)
                show_plan=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # If no specific options, show usage
    if [ "$clean_all" = false ] && [ "$clean_build" = false ] && [ "$clean_sources" = false ] && [ "$clean_releases" = false ] && [ "$clean_installer" = false ] && [ "$show_plan" = false ]; then
        show_usage
        exit 0
    fi

    log_info "Docker for Windows ARM64 - Cleanup"
    log_info "Project root: $PROJECT_ROOT"
    log_info ""

    # Show cleanup plan if requested
    if [ "$show_plan" = true ]; then
        show_cleanup_plan
        exit 0
    fi

    # Perform cleanup based on options
    if [ "$clean_all" = true ]; then
        clean_build
        clean_sources
        clean_releases
        clean_installer
        clean_temp
        clean_go_cache
    else
        [ "$clean_build" = true ] && clean_build
        [ "$clean_sources" = true ] && clean_sources
        [ "$clean_releases" = true ] && clean_releases
        [ "$clean_installer" = true ] && clean_installer
    fi

    log_success ""
    log_success "Cleanup completed!"
    log_info ""
    log_info "To rebuild everything:"
    log_info "  ./scripts/build-all.sh"
    log_info ""
    log_info "To recreate installer:"
    log_info "  ./scripts/create-installer.sh"
}

# Handle script interruption
cleanup_on_exit() {
    log_warning "Cleanup interrupted"
    exit 1
}

trap cleanup_on_exit INT TERM

# Run main function
main "$@"