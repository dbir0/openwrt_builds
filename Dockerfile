FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenWrt build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    flex \
    bison \
    g++ \
    gawk \
    gcc-multilib \
    g++-multilib \
    gettext \
    git \
    libncurses5-dev \
    libssl-dev \
    python3-setuptools \
    rsync \
    swig \
    unzip \
    zlib1g-dev \
    file \
    wget \
    sudo \
    python3 \
    python3-dev \
    python3-distutils-extra \
    libpython3-dev \
    libc6-dev \
    libz-dev \
    ccache \
    time \
    binutils \
    patch \
    bash \
    perl \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Fix common symbolic link issues in containers and verify binaries
RUN ln -sf /bin/bash /usr/bin/bash && \
    # Verify perl installation and fix PATH issues \
    which perl && \
    ls -la /usr/bin/perl && \
    # Test perl execution \
    perl --version && \
    # Ensure common interpreters are in expected locations \
    ln -sf /usr/bin/python3 /usr/bin/python || true


# Set up working directory
WORKDIR /workspace

# Install gosu for safe user switching
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Create entrypoint script to handle dynamic user creation
RUN cat > /usr/local/bin/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Ensure proper environment
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export SHELL="/bin/bash"
export CONFIG_SHELL="/bin/bash"
export FORCE=1

# Debug: Test common interpreters
echo "Testing interpreters..."
which bash && bash --version | head -1
which perl && perl --version | head -1
which python3 && python3 --version

if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then
    # Create group if it doesn't exist
    if ! getent group "$HOST_GID" >/dev/null 2>&1; then
        groupadd -g "$HOST_GID" builder
    fi
    
    # Create user if it doesn't exist
    if ! getent passwd "$HOST_UID" >/dev/null 2>&1; then
        useradd -u "$HOST_UID" -g "$HOST_GID" -m -s /bin/bash builder
        echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        
        # Set up user environment
        echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /home/builder/.bashrc
        echo 'export SHELL="/bin/bash"' >> /home/builder/.bashrc
        echo 'export CONFIG_SHELL="/bin/bash"' >> /home/builder/.bashrc
        echo 'export FORCE=1' >> /home/builder/.bashrc
    fi
    
    # Ensure workspace permissions
    chown -R "$HOST_UID:$HOST_GID" /workspace 2>/dev/null || true
    
    # Switch to the created user
    exec gosu "$HOST_UID:$HOST_GID" "$@"
else
    # Fallback: run as root with warning
    echo "WARNING: Running as root. Set HOST_UID and HOST_GID for better security."
    exec "$@"
fi
EOF

# Make entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables for OpenWrt build
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/workspace/build/openwrt/staging_dir/host/bin"
ENV FORCE=1
ENV STAGING_DIR="/workspace/build/openwrt/staging_dir"
ENV TOPDIR="/workspace/build/openwrt"
ENV SHELL="/bin/bash"
ENV CONFIG_SHELL="/bin/bash"

# Set entrypoint to handle user creation dynamically
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]