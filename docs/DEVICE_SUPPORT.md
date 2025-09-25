# Device Support Documentation

## Currently Supported Devices

### Netgear Nighthawk X4S R7800

**Specifications:**
- **SoC**: Qualcomm IPQ8065 (Dual-core ARM Cortex-A15 @ 1.7GHz)
- **RAM**: 512MB DDR3
- **Flash**: 128MB NAND
- **Wireless**: 
  - 2.4GHz: 4×4 802.11n (up to 800 Mbps)
  - 5GHz: 4×4 802.11ac (up to 1733 Mbps)
- **Ethernet**: 1× WAN + 4× LAN (Gigabit)
- **USB**: 1× USB 3.0 + 1× eSATA/USB 2.0 combo

**OpenWrt Target**: `ipq806x/generic`
**Device Profile**: `DEVICE_netgear_r7800`

**Features Supported:**
- ✅ Wireless (2.4GHz + 5GHz)
- ✅ Ethernet switching
- ✅ USB 3.0 storage
- ✅ Hardware crypto acceleration
- ✅ LED control
- ✅ Button functionality
- ✅ Hardware NAT offloading

### Netgear Nighthawk AC1900 R6900v2

**Specifications:**
- **SoC**: Broadcom BCM4709C0 (Dual-core ARM Cortex-A9 @ 1.4GHz)
- **RAM**: 256MB DDR3
- **Flash**: 128MB NAND
- **Wireless**:
  - 2.4GHz: 3×3 802.11n (up to 600 Mbps)
  - 5GHz: 3×3 802.11ac (up to 1300 Mbps)
- **Ethernet**: 1× WAN + 4× LAN (Gigabit)
- **USB**: 1× USB 3.0 + 1× USB 2.0

**OpenWrt Target**: `bcm53xx/generic`
**Device Profile**: `DEVICE_netgear_r6900-v2`

**Features Supported:**
- ✅ Wireless (2.4GHz + 5GHz)
- ✅ Ethernet switching
- ✅ USB storage
- ✅ LED control
- ✅ Button functionality
- ⚠️ Limited hardware acceleration

## Installation Notes

### R7800 Specific

**Factory Installation:**
1. Use the web interface firmware upgrade
2. Flash the `*-factory.bin` image
3. Wait for automatic reboot

**Recovery Mode:**
- Hold reset button while powering on
- Device enters TFTP recovery mode
- Upload firmware via TFTP to 192.168.1.1

**Serial Console:**
- Connector: J1 (near RAM)
- Settings: 115200 8N1
- Pinout: GND-TX-RX-VCC (3.3V)

### R6900v2 Specific

**Factory Installation:**
1. Use Netgear web interface
2. Navigate to Administration → Router Update
3. Upload `*-factory.bin` image
4. Wait for installation and reboot

**Recovery Mode:**
- Hold reset button for 30 seconds while powered
- Device enters recovery mode
- Access via web browser at 192.168.1.1

**Serial Console:**
- Connector: J252 (4-pin header)
- Settings: 115200 8N1
- Pinout: VCC-TX-RX-GND (3.3V)

## Performance Expectations

### R7800 Performance
- **CPU Performance**: Excellent for routing and NAT
- **Wireless Performance**: 
  - 2.4GHz: ~400-500 Mbps real-world
  - 5GHz: ~800-1000 Mbps real-world
- **Wired Performance**: Line-rate gigabit
- **USB Performance**: ~80-100 MB/s USB 3.0

### R6900v2 Performance
- **CPU Performance**: Good for most home uses
- **Wireless Performance**:
  - 2.4GHz: ~300-400 Mbps real-world
  - 5GHz: ~600-800 Mbps real-world
- **Wired Performance**: Line-rate gigabit
- **USB Performance**: ~30-40 MB/s USB 3.0

## Known Limitations

### R7800 Limitations
- Factory firmware may need TFTP installation on some units
- 5GHz radio may need manual country code setting
- eSATA functionality not supported

### R6900v2 Limitations
- Broadcom wireless drivers are proprietary
- Some wireless features may be limited
- Hardware flow offloading not available
- 2.4GHz range may be slightly reduced compared to stock

## Troubleshooting

### Common Issues

**Device won't boot after flashing:**
1. Verify correct image type was used
2. Try recovery mode installation
3. Check power supply (ensure adequate amperage)

**Wireless not working:**
1. Check country code: `iw reg get`
2. Set country code: `iw reg set US`
3. Restart wireless: `wifi reload`

**USB not detected:**
1. Install USB support packages
2. Check kernel modules: `lsmod | grep usb`
3. Check dmesg for USB events

**Poor wireless performance:**
1. Check channel utilization
2. Verify antenna connections
3. Update wireless drivers
4. Check interference sources

### Getting Support

For device-specific issues:
1. Check OpenWrt device pages
2. Search OpenWrt forum
3. Review device-specific documentation
4. Create issue with hardware details

## Adding New Devices

To add support for a new device:

1. **Research compatibility**:
   - Check OpenWrt Table of Hardware
   - Verify device is supported in target OpenWrt version
   - Identify target/subtarget

2. **Create device configuration**:
   ```bash
   # Create new device config
   cp configs/devices/netgear-r7800.config configs/devices/new-device.config
   # Edit target and device-specific settings
   ```

3. **Update build script**:
   - Add device to validation list
   - Update help text and examples

4. **Test thoroughly**:
   - Build firmware
   - Test installation
   - Verify all features
   - Test both profiles

5. **Update documentation**:
   - Add device to README
   - Update this document
   - Create installation notes

6. **Submit pull request**:
   - Include all configuration files
   - Provide test results
   - Update relevant documentation