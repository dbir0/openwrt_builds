#!/bin/bash
set -euo pipefail

# OpenWrt Build Script
# Supports multi-device, multi-config builds with security hardening

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build"
OPENWRT_DIR="${BUILD_DIR}/openwrt"

# Configuration
OPENWRT_REPO="https://github.com/openwrt/openwrt.git"
DEFAULT_BRANCH="v24.10.3"

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
OpenWrt Build Script

Usage: $0 [OPTIONS]

Options:
    -d, --device DEVICE     Target device (netgear-r6850)
    -p, --profile PROFILE   Build profile (home, business)
    -b, --branch BRANCH     OpenWrt branch/tag (default: $DEFAULT_BRANCH)
    -c, --clean            Clean build environment before building
    -f, --force            Force rebuild even if up-to-date
    -j, --jobs JOBS        Number of parallel jobs (default: nproc)
    -h, --help             Show this help message

Examples:
    $0 -d netgear-r6850 -p home
    $0 -d netgear-r6850 -p business --clean
    $0 --device netgear-r6850 --profile home --branch openwrt-24.10

Supported Devices:
    netgear-r6850    - Netgear R6850 AC2000 (ramips/mt7621)

Supported Profiles:
    home      - Security-focused home configuration
    business  - Enterprise features with enhanced security

EOF
}

check_dependencies() {
    local deps=("git" "make" "gcc" "g++" "unzip" "wget" "python3" "rsync" "which")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Please install the missing dependencies and try again."
        exit 1
    fi
}

setup_openwrt() {
    local branch="$1"
    
    log_info "Setting up OpenWrt build environment..."
    
    # Clean out any existing content in the mounted directory
    if [ -d "$OPENWRT_DIR" ]; then
        log_info "Cleaning existing OpenWrt directory content..."
        rm -rf "$OPENWRT_DIR"/*
        rm -rf "$OPENWRT_DIR"/.[!.]*
    fi
    
    # Clone to a temporary directory first
    local temp_dir="/tmp/openwrt_clone"
    log_info "Cloning OpenWrt repository to temporary location..."
    rm -rf "$temp_dir"
    git clone "$OPENWRT_REPO" "$temp_dir"
    
    cd "$temp_dir"
    
    log_info "Checking out tag: $branch"
    git checkout "$branch"
    
    # Move everything from temp to the mounted directory
    log_info "Moving repository to build directory..."
    mv "$temp_dir"/* "$OPENWRT_DIR"/
    mv "$temp_dir"/.git "$OPENWRT_DIR"/
    mv "$temp_dir"/.[!.]* "$OPENWRT_DIR"/ 2>/dev/null || true
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    cd "$OPENWRT_DIR"
    
    log_info "Current OpenWrt version: $(git describe --tags --always)"
    
    log_info "Updating and installing feeds..."
    ./scripts/feeds update -a
    ./scripts/feeds install -a
}

apply_device_config() {
    local device="$1"
    local config_file="${PROJECT_ROOT}/configs/devices/${device}.config"
    
    if [ ! -f "$config_file" ]; then
        log_error "Device configuration not found: $config_file"
        exit 1
    fi
    
    log_info "Applying device configuration for: $device"
    cp "$config_file" "$OPENWRT_DIR/.config"
}

apply_profile_config() {
    local profile="$1"
    local profile_file="${PROJECT_ROOT}/configs/profiles/${profile}.config"
    
    if [ ! -f "$profile_file" ]; then
        log_error "Profile configuration not found: $profile_file"
        exit 1
    fi
    
    log_info "Applying profile configuration: $profile"
    cat "$profile_file" >> "$OPENWRT_DIR/.config"
}

build_firmware() {
    local jobs="$1"
    local device="$2"
    local profile="$3"
    
    cd "$OPENWRT_DIR"
    
    log_info "Expanding configuration..."
    make menuconfig
    
    log_info "Running menuconfig (non-interactive)..."
    # For automated builds, we skip interactive menuconfig
    # Configuration is already applied from device and profile configs
    
    
    log_info "Pre-downloading packages with $jobs parallel jobs..."
    make -j"$jobs"
    
    log_info "Starting main build with $jobs parallel jobs..."
    log_info "Device: $device, Profile: $profile"
    
    if ! make -j"$jobs" V=s; then
        log_error "Build failed!"
        log_info "Check build logs for details"
        exit 1
    fi
    
    log_success "Build completed successfully!"
}

copy_artifacts() {
    local device="$1"
    local profile="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local artifacts_dir="${PROJECT_ROOT}/artifacts/${device}/${profile}/${timestamp}"
    
    mkdir -p "$artifacts_dir"
    
    log_info "Copying build artifacts to: $artifacts_dir"
    
    # Find and copy firmware files
    find "$OPENWRT_DIR/bin" -name "*.bin" -o -name "*.img" -o -name "*.tar.gz" | while read -r file; do
        cp "$file" "$artifacts_dir/"
        log_info "Copied: $(basename "$file")"
    done
    
    # Copy package list
    find "$OPENWRT_DIR/bin" -name "*.buildinfo" -o -name "*.manifest" | while read -r file; do
        cp "$file" "$artifacts_dir/"
    done
    
    # Create build info
    cat > "$artifacts_dir/build_info.txt" << EOF
Build Information
================
Device: $device
Profile: $profile
Timestamp: $timestamp
OpenWrt Branch: $(cd "$OPENWRT_DIR" && git describe --tags --always)
Build Host: $(hostname)
Build User: $(whoami)
Build Date: $(date)
EOF
    
    log_success "Artifacts saved to: $artifacts_dir"
}

main() {
    local device=""
    local profile=""
    local branch="$DEFAULT_BRANCH"
    local clean=false
    local force=false
    local jobs
    jobs=$(nproc)
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--device)
                device="$2"
                shift 2
                ;;
            -p|--profile)
                profile="$2"
                shift 2
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -j|--jobs)
                jobs="$2"
                shift 2
                ;;
            -h|--help)
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
    
    # Validate required arguments
    if [ -z "$device" ] || [ -z "$profile" ]; then
        log_error "Device and profile are required"
        show_usage
        exit 1
    fi
    
    # Validate device
    if [[ ! "$device" =~ ^(netgear-r6850)$ ]]; then
        log_error "Unsupported device: $device"
        show_usage
        exit 1
    fi
    
    # Validate profile
    if [[ ! "$profile" =~ ^(home|business)$ ]]; then
        log_error "Unsupported profile: $profile"
        show_usage
        exit 1
    fi
    
    log_info "Starting OpenWrt build process..."
    log_info "Device: $device"
    log_info "Profile: $profile"
    log_info "Branch: $branch"
    log_info "Jobs: $jobs"
    
    check_dependencies
    
    if [ "$clean" = true ]; then
        log_info "Cleaning build environment..."
        rm -rf "$BUILD_DIR"
    fi
    
    setup_openwrt "$branch"
    apply_device_config "$device"
    apply_profile_config "$profile"
    build_firmware "$jobs" "$device" "$profile"
    copy_artifacts "$device" "$profile"
    
    log_success "Build process completed successfully!"
}

# Run main function with all arguments
main "$@"