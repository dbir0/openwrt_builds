#!/bin/bash

# Docker Build Wrapper Script
# This script provides easy access to the containerized OpenWrt build environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

show_usage() {
    cat << EOF
Docker OpenWrt Build Wrapper

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    build [build-options]   Run build with specified options
    shell                   Open interactive shell in build container
    clean                   Clean build environment and Docker volumes
    logs                    Show build container logs
    status                  Show container status

Build Options (when using 'build' command):
    All options from scripts/build.sh are supported:
    -d, --device DEVICE     Target device (netgear-r6850)
    -p, --profile PROFILE   Build profile (home, business)
    -b, --branch BRANCH     OpenWrt branch/tag (default: v24.10.3)
    -c, --clean            Clean build environment before building
    -f, --force            Force rebuild even if up-to-date
    -j, --jobs JOBS        Number of parallel jobs (default: nproc)

Examples:
    $0 build -d netgear-r6850 -p home
    $0 build -d netgear-r6850 -p business --clean
    $0 shell
    $0 clean

EOF
}

build_image() {
    log_info "Building Docker image..."
    if ! docker compose build openwrt-builder; then
        log_error "Failed to build Docker image"
        exit 1
    fi
    log_success "Docker image built successfully"
}

run_build() {
    # Ensure Docker image is built
    if ! docker image inspect opernwrt_builds_openwrt-builder &>/dev/null; then
        build_image
    fi
    
    log_info "Starting OpenWrt build in container..."
    docker compose run --rm openwrt-builder ./scripts/build.sh "$@"
}

open_shell() {
    # Ensure Docker image is built
    if ! docker image inspect opernwrt_builds_openwrt-builder &>/dev/null; then
        build_image
    fi
    
    log_info "Opening interactive shell in build container..."
    docker compose run --rm openwrt-builder /bin/bash
}

clean_environment() {
    log_info "Cleaning build environment and Docker volumes..."
    
    # Stop and remove containers
    docker compose down --remove-orphans
    
    # Remove volumes
    docker compose down --volumes
    
    # Remove Docker image
    docker image rm opernwrt_builds_openwrt-builder 2>/dev/null || true
    
    # Clean local build directory
    if [ -d "./build" ]; then
        log_warn "Removing local build directory..."
        rm -rf ./build
    fi
    
    log_success "Environment cleaned"
}

show_logs() {
    docker compose logs openwrt-builder
}

show_status() {
    log_info "Container status:"
    docker compose ps
    
    log_info "Docker volumes:"
    docker volume ls | grep opernwrt_builds || echo "No volumes found"
    
    log_info "Docker images:"
    docker images | grep opernwrt_builds || echo "No images found"
}

# Main command handling
case "${1:-}" in
    "build")
        shift
        run_build "$@"
        ;;
    "shell")
        open_shell
        ;;
    "clean")
        clean_environment
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "-h"|"--help"|"help"|"")
        show_usage
        ;;
    *)
        log_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac