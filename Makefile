# OpenWrt Build System Makefile
# Provides convenient targets for common operations

.PHONY: help test clean build-all build-home build-business security-check version-check

# Default target
help:
	@echo "OpenWrt Build System - Available targets:"
	@echo ""
	@echo "  help          - Show this help message"
	@echo "  test          - Run all configuration tests"
	@echo "  clean         - Clean build artifacts"
	@echo "  version-check - Check for new OpenWrt versions"
	@echo "  security-check- Generate security configurations"
	@echo ""
	@echo "Build targets:"
	@echo "  build-all     - Build all device/profile combinations"
	@echo "  build-home    - Build home profile for all devices"
	@echo "  build-business- Build business profile for all devices"
	@echo ""
	@echo "Device-specific builds:"
	@echo "  r7800-home    - Build home profile for R7800"
	@echo "  r7800-business- Build business profile for R7800"
	@echo "  r6900v2-home  - Build home profile for R6900v2"
	@echo "  r6900v2-business - Build business profile for R6900v2"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make r7800-home"
	@echo "  make build-all"

# Test all configurations
test:
	@echo "Running configuration tests..."
	./scripts/test-config.sh --all

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/ artifacts/ *.log
	rm -f build-matrix.json release-notes.md .last_version

# Version check
version-check:
	@echo "Checking for new OpenWrt versions..."
	./scripts/version-check.sh --check

# Security configuration generation
security-check:
	@echo "Generating security configurations..."
	mkdir -p security/
	./scripts/security-hardening.sh --profile home --output security/
	./scripts/security-hardening.sh --profile business --output security/

# Build all combinations
build-all: r7800-home r7800-business r6900v2-home r6900v2-business

# Build home profile for all devices
build-home: r7800-home r6900v2-home

# Build business profile for all devices
build-business: r7800-business r6900v2-business

# Device-specific builds
r7800-home:
	@echo "Building R7800 with home profile..."
	./scripts/build.sh --device netgear-r7800 --profile home

r7800-business:
	@echo "Building R7800 with business profile..."
	./scripts/build.sh --device netgear-r7800 --profile business

r6900v2-home:
	@echo "Building R6900v2 with home profile..."
	./scripts/build.sh --device netgear-r6900v2 --profile home

r6900v2-business:
	@echo "Building R6900v2 with business profile..."
	./scripts/build.sh --device netgear-r6900v2 --profile business

# Development helpers
dev-setup:
	@echo "Setting up development environment..."
	sudo apt-get update
	sudo apt-get install -y build-essential git curl jq

# Validate repository structure
validate:
	@echo "Validating repository structure..."
	@for dir in configs/devices configs/profiles scripts .github/workflows; do \
		if [ ! -d "$$dir" ]; then \
			echo "Missing directory: $$dir"; \
			exit 1; \
		fi; \
	done
	@for file in scripts/build.sh scripts/version-check.sh scripts/security-hardening.sh; do \
		if [ ! -x "$$file" ]; then \
			echo "Missing or non-executable: $$file"; \
			exit 1; \
		fi; \
	done
	@echo "Repository structure is valid ✅"

# Show build status
status:
	@echo "Build System Status:"
	@echo "===================="
	@if [ -f .last_version ]; then \
		echo "Last tracked version: $$(cat .last_version)"; \
	else \
		echo "No version tracking data"; \
	fi
	@echo "Available devices: netgear-r7800, netgear-r6900v2"
	@echo "Available profiles: home, business"
	@if [ -d artifacts/ ]; then \
		echo "Build artifacts: $$(find artifacts/ -name "*.bin" -o -name "*.img" | wc -l) files"; \
	else \
		echo "No build artifacts found"; \
	fi