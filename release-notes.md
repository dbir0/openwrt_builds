# OpenWrt Custom Build - v24.10.3

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
2. Copy to your router: `scp image.bin root@192.168.1.1:/tmp/`
3. SSH to router and run: `sysupgrade /tmp/image.bin`

## Build Information
- **OpenWrt Version**: v24.10.3
- **Build Date**: Thu Sep 25 14:10:58 UTC 2025
- **Build System**: GitHub Actions with automated testing
- **Security Hardening**: Enabled
- **Reproducible Build**: Yes

## Support
For issues and support, please visit the project repository.

## Changelog
See OpenWrt official changelog for upstream changes: https://openwrt.org/releases/start
