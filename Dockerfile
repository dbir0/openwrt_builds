FROM ubuntu:22.04

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
    libncurses5 \
    libssl-dev \
    python3-distutils \
    rsync \
    unzip \
    wget \
    xsltproc \
    zlib1g-dev \
    file \
    curl \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-yaml \
    python3-dev \
    libc6-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    make \
    patch \
    tar \
    time \
    which \
    ccache \
    ecj \
    fastjar \
    java-propose-classpath \
    libelf-dev \
    subversion \
    && rm -rf /var/lib/apt/lists/*

# Create build user (non-root for security)
RUN useradd -m -u 1000 -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up working directory
WORKDIR /workspace
RUN chown -R builder:builder /workspace

# Switch to build user
USER builder

# Set up Git configuration (required for OpenWrt build)
RUN git config --global user.name "OpenWrt Builder" && \
    git config --global user.email "builder@localhost" && \
    git config --global init.defaultBranch main

# Create build directory
RUN mkdir -p /workspace/build

# Set environment variables
ENV PATH="/workspace/build/openwrt/staging_dir/host/bin:$PATH"
ENV FORCE_UNSAFE_CONFIGURE=1

# Default command
CMD ["/bin/bash"]