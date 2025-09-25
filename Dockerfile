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
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /workspace

# Install gosu for safe user switching
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Create entrypoint script to handle dynamic user creation
RUN cat > /usr/local/bin/entrypoint.sh << 'EOF'
#!/bin/bash
if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then
    # Create group if it doesn't exist
    if ! getent group "$HOST_GID" >/dev/null 2>&1; then
        groupadd -g "$HOST_GID" builder
    fi
    
    # Create user if it doesn't exist
    if ! getent passwd "$HOST_UID" >/dev/null 2>&1; then
        useradd -u "$HOST_UID" -g "$HOST_GID" -m -s /bin/bash builder
        echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
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

# Set environment variables
ENV PATH="/workspace/build/openwrt/staging_dir/host/bin:$PATH"
ENV FORCE_UNSAFE_CONFIGURE=1

# Set entrypoint to handle user creation dynamically
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]