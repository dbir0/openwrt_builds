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
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'set -e' >> /usr/local/bin/entrypoint.sh && \
    echo '' >> /usr/local/bin/entrypoint.sh && \
    echo '# Ensure proper environment' >> /usr/local/bin/entrypoint.sh && \
    echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /usr/local/bin/entrypoint.sh && \
    echo 'export SHELL="/bin/bash"' >> /usr/local/bin/entrypoint.sh && \
    echo 'export CONFIG_SHELL="/bin/bash"' >> /usr/local/bin/entrypoint.sh && \
    echo 'export FORCE=1' >> /usr/local/bin/entrypoint.sh && \
    echo '' >> /usr/local/bin/entrypoint.sh && \
    echo '# Debug: Test common interpreters' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "Testing interpreters..."' >> /usr/local/bin/entrypoint.sh && \
    echo 'which bash && bash --version | head -1' >> /usr/local/bin/entrypoint.sh && \
    echo 'which perl && perl --version | head -1' >> /usr/local/bin/entrypoint.sh && \
    echo 'which python3 && python3 --version' >> /usr/local/bin/entrypoint.sh && \
    echo '' >> /usr/local/bin/entrypoint.sh && \
    echo 'if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then' >> /usr/local/bin/entrypoint.sh && \
    echo '    # Create group if it does not exist' >> /usr/local/bin/entrypoint.sh && \
    echo '    if ! getent group "$HOST_GID" >/dev/null 2>&1; then' >> /usr/local/bin/entrypoint.sh && \
    echo '        groupadd -g "$HOST_GID" builder' >> /usr/local/bin/entrypoint.sh && \
    echo '    fi' >> /usr/local/bin/entrypoint.sh && \
    echo '    ' >> /usr/local/bin/entrypoint.sh && \
    echo '    # Create user if it does not exist' >> /usr/local/bin/entrypoint.sh && \
    echo '    if ! getent passwd "$HOST_UID" >/dev/null 2>&1; then' >> /usr/local/bin/entrypoint.sh && \
    echo '        useradd -u "$HOST_UID" -g "$HOST_GID" -m -s /bin/bash builder' >> /usr/local/bin/entrypoint.sh && \
    echo '        echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers' >> /usr/local/bin/entrypoint.sh && \
    echo '        ' >> /usr/local/bin/entrypoint.sh && \
    echo '        # Set up user environment' >> /usr/local/bin/entrypoint.sh && \
    echo '        echo '\''export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"'\'' >> /home/builder/.bashrc' >> /usr/local/bin/entrypoint.sh && \
    echo '        echo '\''export SHELL="/bin/bash"'\'' >> /home/builder/.bashrc' >> /usr/local/bin/entrypoint.sh && \
    echo '        echo '\''export CONFIG_SHELL="/bin/bash"'\'' >> /home/builder/.bashrc' >> /usr/local/bin/entrypoint.sh && \
    echo '        echo '\''export FORCE=1'\'' >> /home/builder/.bashrc' >> /usr/local/bin/entrypoint.sh && \
    echo '    fi' >> /usr/local/bin/entrypoint.sh && \
    echo '    ' >> /usr/local/bin/entrypoint.sh && \
    echo '    # Ensure workspace permissions' >> /usr/local/bin/entrypoint.sh && \
    echo '    chown -R "$HOST_UID:$HOST_GID" /workspace 2>/dev/null || true' >> /usr/local/bin/entrypoint.sh && \
    echo '    ' >> /usr/local/bin/entrypoint.sh && \
    echo '    # Switch to the created user' >> /usr/local/bin/entrypoint.sh && \
    echo '    exec gosu "$HOST_UID:$HOST_GID" "$@"' >> /usr/local/bin/entrypoint.sh && \
    echo 'else' >> /usr/local/bin/entrypoint.sh && \
    echo '    # Fallback: run as root with warning' >> /usr/local/bin/entrypoint.sh && \
    echo '    echo "WARNING: Running as root. Set HOST_UID and HOST_GID for better security."' >> /usr/local/bin/entrypoint.sh && \
    echo '    exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    echo 'fi' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables for OpenWrt build
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV FORCE=1
ENV SHELL="/bin/bash"
ENV CONFIG_SHELL="/bin/bash"

# Set entrypoint to handle user creation dynamically
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]