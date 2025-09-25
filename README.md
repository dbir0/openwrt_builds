# OpenWrt Custom Build System 🛡️

[![Build Status](https://github.com/dbir0/opernwrt_builds/workflows/OpenWrt%20Build%20System/badge.svg)](https://github.com/dbir0/opernwrt_builds/actions)
[![License](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-23.05-orange.svg)](https://openwrt.org/)

Custom OpenWrt firmware build system with automated version tracking, multi-device support, and security-first configurations. Features GitHub Actions CI/CD, automatic new version detection, hardened security configs, and comprehensive release management.

## 🎯 Features

- **🔧 Multi-Device Support**: Pre-configured for Netgear R7800 and R6900v2 routers
- **📦 Multi-Profile Builds**: Home and Business configurations with different feature sets
- **🔒 Security-First Approach**: Hardened configurations with enhanced security features
- **🤖 Automated CI/CD**: GitHub Actions workflow with automatic version detection
- **📈 Version Tracking**: Automatic detection of new OpenWrt releases
- **🔁 Reproducible Builds**: Consistent, verifiable firmware builds
- **📋 Release Management**: Automated creation of factory and sysupgrade images
- **📢 Build Notifications**: Status reporting and failure notifications

## 🎯 Supported Devices

| Device | Target | Profile Support | Status |
|--------|--------|----------------|--------|
| **Netgear Nighthawk X4S R7800** | `ipq806x/generic` | Home, Business | ✅ Active |
| **Netgear Nighthawk AC1900 R6900v2** | `bcm53xx/generic` | Home, Business | ✅ Active |

## 🔧 Build Profiles

### 🏠 Home Profile
Security-focused configuration optimized for home use:

- **Core Features**:
  - Enhanced firewall with nftables
  - WireGuard VPN support
  - DNS-based ad-blocking
  - Quality of Service (SQM)
  - Secure wireless with WPA3 support
  - USB storage support
  - LuCI web interface

- **Security Enhancements**:
  - Hardened SSH configuration
  - Automated security updates
  - Network intrusion detection
  - Secure boot support

### 🏢 Business Profile
Enterprise-grade features with advanced security:

- **All Home Features Plus**:
  - VLAN support for network segmentation
  - OpenVPN server for remote access
  - Network monitoring and statistics
  - SNMP support for enterprise monitoring
  - Load balancing and failover (mwan3)
  - Captive portal support
  - Print server functionality
  - Enhanced logging and backup features
  - Certificate management tools

## 🚀 Quick Start

### Prerequisites

- Linux-based system (Ubuntu 20.04+ recommended)
- At least 50GB free disk space
- 8GB+ RAM
- Fast internet connection

### Building Firmware

1. **Clone the repository**:
   ```bash
   git clone https://github.com/dbir0/opernwrt_builds.git
   cd opernwrt_builds
   ```

2. **Build firmware for your device**:
   ```bash
   # Home profile for R7800
   ./scripts/build.sh --device netgear-r7800 --profile home
   
   # Business profile for R6900v2
   ./scripts/build.sh --device netgear-r6900v2 --profile business
   
   # Clean build with specific OpenWrt version
   ./scripts/build.sh --device netgear-r7800 --profile home --branch openwrt-23.05 --clean
   ```

3. **Find your firmware**:
   - Built images are in `artifacts/{device}/{profile}/{timestamp}/`
   - Look for `.bin` files for factory installation
   - Look for `.img` files for sysupgrade

### Using Pre-built Releases

1. **Download firmware** from [Releases](https://github.com/dbir0/opernwrt_builds/releases)
2. **Choose the right image**:
   - `factory.bin` - For first-time installation from stock firmware
   - `sysupgrade.bin` - For upgrading existing OpenWrt installation

## 📦 Installation Guide

### Factory Installation (From Stock Firmware)

1. **Download** the appropriate factory image for your device
2. **Access** your router's web interface (usually `http://192.168.1.1`)
3. **Navigate** to Administration → Firmware Upgrade
4. **Upload** the factory `.bin` file
5. **Wait** for the installation to complete (5-10 minutes)
6. **Access** the new OpenWrt interface at `http://192.168.1.1`

### Sysupgrade (From Existing OpenWrt)

1. **Download** the appropriate sysupgrade image
2. **Copy to router**:
   ```bash
   scp firmware.bin root@192.168.1.1:/tmp/
   ```
3. **SSH to router** and upgrade:
   ```bash
   ssh root@192.168.1.1
   sysupgrade /tmp/firmware.bin
   ```

## 🔧 Advanced Usage

### Manual Version Check

```bash
# Check for new OpenWrt versions
./scripts/version-check.sh --check

# Force specific version
./scripts/version-check.sh --force v23.05.2

# Generate build matrix
./scripts/version-check.sh --generate-matrix
```

### Security Hardening

```bash
# Create security configurations
./scripts/security-hardening.sh --profile home --output ./security

# Verify existing configuration
./scripts/security-hardening.sh --verify .config

# Generate post-installation hardening script
./scripts/security-hardening.sh --post-install /tmp/harden.sh
```

### Build Options

```bash
# All available options
./scripts/build.sh --help

# Parallel build with specific job count
./scripts/build.sh --device netgear-r7800 --profile home --jobs 8

# Force rebuild
./scripts/build.sh --device netgear-r7800 --profile home --force
```

## 🔄 Automated Builds

The system automatically:

1. **Checks** for new OpenWrt releases daily at 6 AM UTC
2. **Builds** firmware for all device/profile combinations
3. **Creates** GitHub releases with firmware downloads
4. **Notifies** about build status and failures

### Manual Trigger

You can manually trigger builds through GitHub Actions:

1. Go to **Actions** tab in the repository
2. Select **OpenWrt Build System** workflow
3. Click **Run workflow**
4. Choose device, profile, and options
5. Click **Run workflow**

## 📁 Repository Structure

```
opernwrt_builds/
├── .github/workflows/          # GitHub Actions workflows
│   └── build.yml              # Main build workflow
├── configs/                   # Configuration files
│   ├── devices/              # Device-specific configs
│   │   ├── netgear-r7800.config
│   │   └── netgear-r6900v2.config
│   └── profiles/             # Profile configurations
│       ├── home.config
│       └── business.config
├── scripts/                  # Build and utility scripts
│   ├── build.sh             # Main build script
│   ├── version-check.sh     # Version tracking
│   └── security-hardening.sh # Security configurations
├── docs/                    # Documentation
├── artifacts/               # Build outputs (local builds)
└── README.md               # This file
```

## 🔒 Security Features

### Build Security
- **Reproducible builds** with checksum verification
- **Automated vulnerability scanning** of dependencies
- **Secure build environment** with isolated containers
- **Code signing** of releases (planned)

### Runtime Security
- **Hardened kernel configuration** with ASLR, stack protection
- **Secure defaults** with unnecessary services disabled
- **Regular security updates** through automated builds
- **Network security** with advanced firewall rules
- **Cryptographic acceleration** where hardware supports it

## 🐛 Troubleshooting

### Common Issues

**Build fails with "No space left on device"**:
- Ensure at least 50GB free space
- Clean previous builds: `./scripts/build.sh --clean`

**Download failures during build**:
- Check internet connection
- Retry build - downloads are cached

**Device not booting after flash**:
- Ensure you used the correct image type
- Try recovery mode flashing
- Check device compatibility

### Getting Help

1. **Check** the [Issues](https://github.com/dbir0/opernwrt_builds/issues) page
2. **Review** build logs in GitHub Actions
3. **Consult** OpenWrt documentation
4. **Create** a new issue with:
   - Device model
   - Build profile
   - Error messages
   - Steps to reproduce

## 🤝 Contributing

Contributions are welcome! Please:

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

### Adding New Devices

1. Create device config in `configs/devices/`
2. Update build script device validation
3. Test build process
4. Update documentation

## 📋 Roadmap

- [ ] **Additional device support** (TP-Link, ASUS models)
- [ ] **Advanced security profiles** (IoT, Guest networks)
- [ ] **Custom package repositories**
- [ ] **Build verification and signing**
- [ ] **Monitoring and alerting integration**
- [ ] **Web-based configuration generator**

## 📄 License

This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenWrt Project** for the excellent firmware platform
- **GitHub Actions** for CI/CD infrastructure
- **Community contributors** for device configurations and testing

## 📞 Support

- **Documentation**: [OpenWrt Wiki](https://openwrt.org/docs/start)
- **Community**: [OpenWrt Forum](https://forum.openwrt.org/)
- **Issues**: [GitHub Issues](https://github.com/dbir0/opernwrt_builds/issues)

---

**⚠️ Disclaimer**: Flashing custom firmware may void your warranty and can brick your device if done incorrectly. Proceed at your own risk and ensure you understand the process before beginning.
