# OpenWrt Custom Build System

[![Build Status](https://github.com/dbir0/opernwrt_builds/workflows/OpenWrt%20Build%20System/badge.svg)](https://github.com/dbir0/opernwrt_builds/actions)
[![License](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-24.10.3-orange.svg)](https://openwrt.org/)


## Build Options

```bash
# All available options
./scripts/build.sh --help

# Parallel build with specific job count
./scripts/build.sh --device netgear-r6850 --profile home --jobs 8

# Force rebuild
./scripts/build.sh --device netgear-r6850 --profile home --force
```


## Adding New Devices

1. Create device config in `configs/devices/`
2. Update build script device validation
3. Test build process
4. Update documentation


## License

This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

**⚠️ Disclaimer**: Flashing custom firmware may void your warranty and can brick your device if done incorrectly. Proceed at your own risk and ensure you understand the process before beginning.
