#!/bin/bash
set -euo pipefail

# OpenWrt Version Check Script
# Automatically detects new OpenWrt releases and triggers builds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# Configuration
OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
VERSION_FILE="${PROJECT_ROOT}/.last_version"
RELEASES_API="https://api.github.com/repos/openwrt/openwrt/tags"

get_latest_stable_version() {
    log_info "Fetching latest OpenWrt stable version..."
    
    # Get tags from GitHub API and filter for stable releases
    local latest_version
    latest_version=$(curl -s "$RELEASES_API" | \
        jq -r '.[].name' | \
        grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | \
        sort -V | \
        tail -1)
    
    if [ -z "$latest_version" ]; then
        log_error "Failed to fetch latest version"
        return 1
    fi
    
    echo "$latest_version"
}

get_current_tracked_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo ""
    fi
}

update_tracked_version() {
    local version="$1"
    echo "$version" > "$VERSION_FILE"
    log_info "Updated tracked version to: $version"
}

check_for_updates() {
    local latest_version
    local current_version
    
    latest_version=$(get_latest_stable_version)
    current_version=$(get_current_tracked_version)
    
    log_info "Current tracked version: ${current_version:-none}"
    log_info "Latest available version: $latest_version"
    
    if [ "$latest_version" != "$current_version" ]; then
        log_success "New version available: $latest_version"
        return 0
    else
        log_info "No new version available"
        return 1
    fi
}

generate_build_matrix() {
    local version="$1"
    
    # Create build matrix for GitHub Actions
    cat > "${PROJECT_ROOT}/build-matrix.json" << EOF
{
  "include": [
    {
      "device": "netgear-r7800",
      "profile": "home",
      "version": "$version"
    },
    {
      "device": "netgear-r7800",
      "profile": "business",
      "version": "$version"
    },
    {
      "device": "netgear-r6900v2",
      "profile": "home",
      "version": "$version"
    },
    {
      "device": "netgear-r6900v2",
      "profile": "business",
      "version": "$version"
    }
  ]
}
EOF
    
    log_info "Generated build matrix for version: $version"
}

create_release_notes() {
    local version="$1"
    local notes_file="${PROJECT_ROOT}/release-notes.md"
    
    cat > "$notes_file" << EOF
# OpenWrt Custom Build - $version

## Supported Devices
- **Netgear Nighthawk X4S R7800** - High-performance dual-band router with advanced features
- **Netgear Nighthawk AC1900 R6900v2** - Reliable dual-band router for home and small business

## Build Profiles

### Home Profile
Security-focused configuration optimized for home use:
- Enhanced firewall with nftables
- WireGuard VPN support
- Ad-blocking with DNS filtering
- Quality of Service (QoS) management
- Secure wireless with WPA3 support
- USB storage support
- Web interface (LuCI) for easy management

### Business Profile
Enterprise-grade features with enhanced security:
- All home profile features plus:
- VLAN support for network segmentation
- OpenVPN server for remote access
- Network monitoring and statistics
- SNMP support for enterprise monitoring
- Load balancing and failover (mwan3)
- Captive portal support
- Print server functionality
- Enhanced logging and backup features
- Certificate management tools

## Security Features
- Hardened default configurations
- Regular security updates
- Secure boot support where available
- Network intrusion detection
- Automated vulnerability scanning
- Reproducible builds for verification

## Installation Instructions

### Factory Installation
1. Download the appropriate factory image for your device
2. Access your router's web interface
3. Navigate to firmware upgrade section
4. Upload the factory image and wait for installation to complete

### Sysupgrade (For existing OpenWrt installations)
1. Download the sysupgrade image for your device
2. Copy to your router: \`scp image.bin root@192.168.1.1:/tmp/\`
3. SSH to router and run: \`sysupgrade /tmp/image.bin\`

## Build Information
- **OpenWrt Version**: $version
- **Build Date**: $(date)
- **Build System**: GitHub Actions with automated testing
- **Security Hardening**: Enabled
- **Reproducible Build**: Yes

## Support
For issues and support, please visit the project repository.

## Changelog
See OpenWrt official changelog for upstream changes: https://openwrt.org/releases/start
EOF
    
    log_info "Created release notes: $notes_file"
}

show_usage() {
    cat << EOF
OpenWrt Version Check Script

Usage: $0 [OPTIONS]

Options:
    --check                Check for new versions only
    --force VERSION        Force update to specific version
    --generate-matrix      Generate build matrix for current version
    --create-notes         Create release notes for current version
    -h, --help             Show this help message

Examples:
    $0 --check
    $0 --force v23.05.2
    $0 --generate-matrix

EOF
}

main() {
    local action="check"
    local force_version=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                action="check"
                shift
                ;;
            --force)
                action="force"
                force_version="$2"
                shift 2
                ;;
            --generate-matrix)
                action="generate-matrix"
                shift
                ;;
            --create-notes)
                action="create-notes"
                shift
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
    
    case $action in
        "check")
            if check_for_updates; then
                local latest_version
                latest_version=$(get_latest_stable_version)
                update_tracked_version "$latest_version"
                generate_build_matrix "$latest_version"
                create_release_notes "$latest_version"
                echo "new_version=$latest_version" >> "${GITHUB_OUTPUT:-/dev/stdout}"
                echo "version_changed=true" >> "${GITHUB_OUTPUT:-/dev/stdout}"
            else
                echo "version_changed=false" >> "${GITHUB_OUTPUT:-/dev/stdout}"
            fi
            ;;
        "force")
            log_info "Forcing update to version: $force_version"
            update_tracked_version "$force_version"
            generate_build_matrix "$force_version"
            create_release_notes "$force_version"
            echo "new_version=$force_version" >> "${GITHUB_OUTPUT:-/dev/stdout}"
            echo "version_changed=true" >> "${GITHUB_OUTPUT:-/dev/stdout}"
            ;;
        "generate-matrix")
            local current_version
            current_version=$(get_current_tracked_version)
            if [ -n "$current_version" ]; then
                generate_build_matrix "$current_version"
            else
                log_error "No tracked version found"
                exit 1
            fi
            ;;
        "create-notes")
            local current_version
            current_version=$(get_current_tracked_version)
            if [ -n "$current_version" ]; then
                create_release_notes "$current_version"
            else
                log_error "No tracked version found"
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"