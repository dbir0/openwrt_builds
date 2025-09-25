#!/bin/bash
set -euo pipefail

# Configuration test script
# Validates device and profile configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

test_device_config() {
    local device="$1"
    local config_file="${PROJECT_ROOT}/configs/devices/${device}.config"
    local errors=0
    
    log_info "Testing device configuration: $device"
    
    if [ ! -f "$config_file" ]; then
        log_error "Device configuration file not found: $config_file"
        return 1
    fi
    
    # Check for required device settings
    local required_settings=(
        "CONFIG_TARGET_.*=y"
        "CONFIG_TARGET_.*_.*=y"
        "CONFIG_TARGET_.*_.*_DEVICE_.*=y"
    )
    
    for setting in "${required_settings[@]}"; do
        if ! grep -E "$setting" "$config_file" >/dev/null; then
            log_error "Missing required setting pattern: $setting"
            ((errors++))
        fi
    done
    
    # Check for device-specific packages
    local device_packages=(
        "CONFIG_PACKAGE_kmod-"
        "CONFIG_PACKAGE_.*-firmware"
    )
    
    local found_packages=0
    for package in "${device_packages[@]}"; do
        if grep -E "$package" "$config_file" >/dev/null; then
            ((found_packages++))
        fi
    done
    
    if [ $found_packages -eq 0 ]; then
        log_warn "No device-specific packages found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Device configuration test passed: $device"
        return 0
    else
        log_error "Device configuration test failed: $device ($errors errors)"
        return 1
    fi
}

test_profile_config() {
    local profile="$1"
    local config_file="${PROJECT_ROOT}/configs/profiles/${profile}.config"
    local errors=0
    
    log_info "Testing profile configuration: $profile"
    
    if [ ! -f "$config_file" ]; then
        log_error "Profile configuration file not found: $config_file"
        return 1
    fi
    
    # Check for essential packages
    local essential_packages=(
        "CONFIG_PACKAGE_base-files=y"
        "CONFIG_PACKAGE_busybox=y"
        "CONFIG_PACKAGE_firewall4=y"
        "CONFIG_PACKAGE_dropbear=y"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! grep -F "$package" "$config_file" >/dev/null; then
            log_error "Missing essential package: $package"
            ((errors++))
        fi
    done
    
    # Check profile-specific features
    case $profile in
        "home")
            local home_features=(
                "CONFIG_PACKAGE_luci=y"
                "CONFIG_PACKAGE_wireguard-tools=y"
                "CONFIG_PACKAGE_adblock=y"
            )
            for feature in "${home_features[@]}"; do
                if ! grep -F "$feature" "$config_file" >/dev/null; then
                    log_warn "Missing home profile feature: $feature"
                fi
            done
            ;;
        "business")
            local business_features=(
                "CONFIG_PACKAGE_openvpn-openssl=y"
                "CONFIG_PACKAGE_luci-app-statistics=y"
                "CONFIG_PACKAGE_snmpd=y"
            )
            for feature in "${business_features[@]}"; do
                if ! grep -F "$feature" "$config_file" >/dev/null; then
                    log_warn "Missing business profile feature: $feature"
                fi
            done
            ;;
    esac
    
    # Check for security issues
    local insecure_packages=(
        "CONFIG_PACKAGE_telnet=y"
        "CONFIG_BUSYBOX_CONFIG_TELNETD=y"
    )
    
    for package in "${insecure_packages[@]}"; do
        if grep -F "$package" "$config_file" >/dev/null; then
            log_error "Insecure package found: $package"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "Profile configuration test passed: $profile"
        return 0
    else
        log_error "Profile configuration test failed: $profile ($errors errors)"
        return 1
    fi
}

test_build_script() {
    log_info "Testing build script functionality..."
    
    local script="${PROJECT_ROOT}/scripts/build.sh"
    local errors=0
    
    if [ ! -x "$script" ]; then
        log_error "Build script not executable: $script"
        ((errors++))
    fi
    
    # Test help output
    if ! "$script" --help >/dev/null 2>&1; then
        log_error "Build script help function failed"
        ((errors++))
    fi
    
    # Test argument validation
    if "$script" --device invalid-device --profile home 2>/dev/null; then
        log_error "Build script should reject invalid device"
        ((errors++))
    fi
    
    if "$script" --device netgear-r7800 --profile invalid-profile 2>/dev/null; then
        log_error "Build script should reject invalid profile"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Build script test passed"
        return 0
    else
        log_error "Build script test failed ($errors errors)"
        return 1
    fi
}

test_version_script() {
    log_info "Testing version check script..."
    
    local script="${PROJECT_ROOT}/scripts/version-check.sh"
    local errors=0
    
    if [ ! -x "$script" ]; then
        log_error "Version script not executable: $script"
        ((errors++))
    fi
    
    # Test help output
    if ! "$script" --help >/dev/null 2>&1; then
        log_error "Version script help function failed"
        ((errors++))
    fi
    
    # Test matrix generation
    echo "v23.05.0" > "${PROJECT_ROOT}/.last_version"
    if ! "$script" --generate-matrix >/dev/null 2>&1; then
        log_error "Matrix generation failed"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Version script test passed"
        return 0
    else
        log_error "Version script test failed ($errors errors)"
        return 1
    fi
}

test_workflow() {
    log_info "Testing GitHub workflow configuration..."
    
    local workflow="${PROJECT_ROOT}/.github/workflows/build.yml"
    local errors=0
    
    if [ ! -f "$workflow" ]; then
        log_error "Workflow file not found: $workflow"
        ((errors++))
    fi
    
    # Basic YAML syntax check (if yq is available)
    if command -v yq >/dev/null 2>&1; then
        if ! yq eval . "$workflow" >/dev/null 2>&1; then
            log_error "Workflow YAML syntax error"
            ((errors++))
        fi
    else
        log_warn "yq not available, skipping YAML syntax check"
    fi
    
    # Check for required workflow components
    local required_jobs=(
        "version-check"
        "build"
        "create-release"
        "notify"
    )
    
    for job in "${required_jobs[@]}"; do
        if ! grep -q "^  $job:" "$workflow"; then
            log_error "Missing required job: $job"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "Workflow test passed"
        return 0
    else
        log_error "Workflow test failed ($errors errors)"
        return 1
    fi
}

run_all_tests() {
    local total_errors=0
    
    log_info "Running all configuration tests..."
    
    # Test device configurations
    for device in netgear-r7800 netgear-r6900v2; do
        if ! test_device_config "$device"; then
            ((total_errors++))
        fi
    done
    
    # Test profile configurations
    for profile in home business; do
        if ! test_profile_config "$profile"; then
            ((total_errors++))
        fi
    done
    
    # Test scripts
    if ! test_build_script; then
        ((total_errors++))
    fi
    
    if ! test_version_script; then
        ((total_errors++))
    fi
    
    # Test workflow
    if ! test_workflow; then
        ((total_errors++))
    fi
    
    echo
    if [ $total_errors -eq 0 ]; then
        log_success "All tests passed! ✅"
        return 0
    else
        log_error "Tests failed with $total_errors error(s) ❌"
        return 1
    fi
}

show_usage() {
    cat << EOF
Configuration Test Script

Usage: $0 [OPTIONS]

Options:
    --device DEVICE        Test specific device configuration
    --profile PROFILE      Test specific profile configuration
    --build-script         Test build script functionality
    --version-script       Test version check script
    --workflow             Test GitHub workflow
    --all                  Run all tests (default)
    -h, --help             Show this help message

Examples:
    $0 --all
    $0 --device netgear-r7800
    $0 --profile home
    $0 --build-script

EOF
}

main() {
    local test_type="all"
    local target=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --device)
                test_type="device"
                target="$2"
                shift 2
                ;;
            --profile)
                test_type="profile"
                target="$2"
                shift 2
                ;;
            --build-script)
                test_type="build-script"
                shift
                ;;
            --version-script)
                test_type="version-script"
                shift
                ;;
            --workflow)
                test_type="workflow"
                shift
                ;;
            --all)
                test_type="all"
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
    
    case $test_type in
        "device")
            test_device_config "$target"
            ;;
        "profile")
            test_profile_config "$target"
            ;;
        "build-script")
            test_build_script
            ;;
        "version-script")
            test_version_script
            ;;
        "workflow")
            test_workflow
            ;;
        "all")
            run_all_tests
            ;;
    esac
}

main "$@"