#!/bin/bash
set -euo pipefail

# Security hardening script for OpenWrt builds
# Applies additional security configurations post-build

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

create_security_config() {
    local profile="$1"
    local output_file="$2"
    
    log_info "Creating security hardening configuration for profile: $profile"
    
    cat > "$output_file" << 'EOF'
# Security Hardening Configuration
# This file contains additional security settings applied during build

# Disable unnecessary services
CONFIG_BUSYBOX_CONFIG_TELNETD=n
CONFIG_PACKAGE_telnet=n

# Enable security features
CONFIG_BUSYBOX_CONFIG_FEATURE_SECURETTY=y
CONFIG_BUSYBOX_CONFIG_FEATURE_SU_SYSLOG=y
CONFIG_BUSYBOX_CONFIG_FEATURE_UTMP=y
CONFIG_BUSYBOX_CONFIG_FEATURE_WTMP=y

# Network security
CONFIG_NETFILTER_NETLINK_GLUE_CT=y
CONFIG_NETFILTER_XT_TARGET_CT=y
CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y
CONFIG_NETFILTER_XT_MATCH_STATE=y

# Kernel security features
CONFIG_KERNEL_CC_STACKPROTECTOR_REGULAR=y
CONFIG_KERNEL_SLUB_DEBUG=y
CONFIG_KERNEL_PANIC_ON_OOPS=y

# Crypto acceleration where available
CONFIG_PACKAGE_kmod-crypto-aead=y
CONFIG_PACKAGE_kmod-crypto-hash=y
CONFIG_PACKAGE_kmod-crypto-manager=y

# Secure random number generation
CONFIG_PACKAGE_urngd=y

# Additional security packages
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_ca-certificates=y

# Disable debug features in production
# CONFIG_KERNEL_DEBUG_KERNEL is not set
# CONFIG_KERNEL_DEBUG_INFO is not set
# CONFIG_KERNEL_KALLSYMS is not set

EOF

    if [ "$profile" == "business" ]; then
        cat >> "$output_file" << 'EOF'
# Business profile additional security
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_iptables-mod-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y

# Advanced logging
CONFIG_PACKAGE_rsyslog=y
CONFIG_PACKAGE_logrotate=y

# Certificate management
CONFIG_PACKAGE_openssl-util=y

# Network monitoring
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_nmap=y

EOF
    fi
    
    log_success "Security configuration created: $output_file"
}

apply_kernel_hardening() {
    local kernel_config="$1"
    
    log_info "Applying kernel security hardening..."
    
    cat >> "$kernel_config" << 'EOF'
# Kernel hardening options
CONFIG_SECURITY=y
CONFIG_SECURITY_DMESG_RESTRICT=y
CONFIG_SECURITY_PERF_EVENTS_RESTRICT=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_STACKPROTECTOR=y
CONFIG_STACKPROTECTOR_STRONG=y
CONFIG_STRICT_KERNEL_RWX=y
CONFIG_STRICT_MODULE_RWX=y
CONFIG_PAGE_POISONING=y
CONFIG_PAGE_POISONING_NO_SANITY=y
CONFIG_PAGE_POISONING_ZERO=y
CONFIG_SLAB_FREELIST_RANDOM=y
CONFIG_SLAB_FREELIST_HARDENED=y
CONFIG_SHUFFLE_PAGE_ALLOCATOR=y
CONFIG_SLUB_DEBUG=y
CONFIG_SLUB_DEBUG_PANIC_ON=y

# Disable dangerous features
# CONFIG_DEVMEM is not set
# CONFIG_DEVKMEM is not set
# CONFIG_PROC_KCORE is not set
# CONFIG_HIBERNATION is not set
# CONFIG_LEGACY_VSYSCALL_EMULATE is not set
# CONFIG_LEGACY_VSYSCALL_NATIVE is not set

# Network security
CONFIG_INET_DIAG_DESTROY=y
CONFIG_NETFILTER_XT_MATCH_OWNER=y
CONFIG_NETFILTER_XT_TARGET_TCPMSS=y
CONFIG_SYN_COOKIES=y
CONFIG_INET_TCP_DIAG=y

EOF
    
    log_success "Kernel hardening configuration applied"
}

create_post_install_script() {
    local output_file="$1"
    
    log_info "Creating post-installation security script..."
    
    cat > "$output_file" << 'EOF'
#!/bin/sh
# Post-installation security hardening script
# Run this script after installing the firmware

echo "Applying security hardening..."

# Disable unnecessary services
/etc/init.d/uhttpd stop 2>/dev/null || true
/etc/init.d/uhttpd disable 2>/dev/null || true

# Configure firewall for maximum security
uci set firewall.@defaults[0].drop_invalid='1'
uci set firewall.@defaults[0].input='REJECT'
uci set firewall.@defaults[0].output='ACCEPT'
uci set firewall.@defaults[0].forward='REJECT'
uci set firewall.@defaults[0].syn_flood='1'

# Enable SYN flood protection
uci set firewall.@defaults[0].tcp_syncookies='1'
uci set firewall.@defaults[0].tcp_window_scaling='1'

# Configure SSH security
uci set dropbear.@dropbear[0].PasswordAuth='0'
uci set dropbear.@dropbear[0].RootPasswordAuth='0'
uci set dropbear.@dropbear[0].Port='22'

# Set secure wireless defaults
uci set wireless.default_radio0.encryption='psk2+ccmp'
uci set wireless.default_radio1.encryption='psk2+ccmp'
uci set wireless.default_radio0.key='ChangeThisPassword!'
uci set wireless.default_radio1.key='ChangeThisPassword!'

# Disable WPS
uci set wireless.default_radio0.wps_pushbutton='0'
uci set wireless.default_radio1.wps_pushbutton='0'

# Configure system settings
uci set system.@system[0].hostname='OpenWrt-Secure'
uci set system.@system[0].timezone='UTC'

# Commit all changes
uci commit

echo "Security hardening completed!"
echo "Please:"
echo "1. Change the default wireless password"
echo "2. Set up SSH key authentication"
echo "3. Change the root password"
echo "4. Review firewall rules"
echo "5. Configure time synchronization"

EOF
    
    chmod +x "$output_file"
    log_success "Post-installation script created: $output_file"
}

verify_security_config() {
    local config_file="$1"
    local errors=0
    
    log_info "Verifying security configuration..."
    
    # Check for security-critical packages
    local required_packages=(
        "CONFIG_PACKAGE_dropbear=y"
        "CONFIG_PACKAGE_firewall4=y"
        "CONFIG_PACKAGE_ca-bundle=y"
        "CONFIG_PACKAGE_urngd=y"
    )
    
    local forbidden_packages=(
        "CONFIG_PACKAGE_telnet=y"
        "CONFIG_BUSYBOX_CONFIG_TELNETD=y"
    )
    
    for package in "${required_packages[@]}"; do
        if ! grep -q "$package" "$config_file"; then
            log_warn "Missing required security package: $package"
            ((errors++))
        fi
    done
    
    for package in "${forbidden_packages[@]}"; do
        if grep -q "$package" "$config_file"; then
            log_error "Forbidden insecure package found: $package"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "Security configuration verification passed"
        return 0
    else
        log_error "Security configuration verification failed with $errors error(s)"
        return 1
    fi
}

show_usage() {
    cat << EOF
Security Hardening Script for OpenWrt Builds

Usage: $0 [OPTIONS]

Options:
    --profile PROFILE      Target profile (home, business)
    --output DIR           Output directory for security configs
    --verify FILE          Verify security configuration file
    --post-install FILE    Create post-installation security script
    -h, --help             Show this help message

Examples:
    $0 --profile home --output ./security
    $0 --verify .config
    $0 --post-install /tmp/harden.sh

EOF
}

main() {
    local profile=""
    local output_dir=""
    local verify_file=""
    local post_install_file=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                profile="$2"
                shift 2
                ;;
            --output)
                output_dir="$2"
                shift 2
                ;;
            --verify)
                verify_file="$2"
                shift 2
                ;;
            --post-install)
                post_install_file="$2"
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
    
    if [ -n "$verify_file" ]; then
        verify_security_config "$verify_file"
        exit $?
    fi
    
    if [ -n "$post_install_file" ]; then
        create_post_install_script "$post_install_file"
        exit 0
    fi
    
    if [ -z "$profile" ] || [ -z "$output_dir" ]; then
        log_error "Profile and output directory are required"
        show_usage
        exit 1
    fi
    
    mkdir -p "$output_dir"
    
    create_security_config "$profile" "$output_dir/security-${profile}.config"
    apply_kernel_hardening "$output_dir/kernel-hardening.config"
    create_post_install_script "$output_dir/post-install-harden.sh"
    
    log_success "Security hardening configurations created in: $output_dir"
}

main "$@"