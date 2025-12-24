FROM ubuntu:22.04
LABEL maintainer="Tim Chaubet"
VOLUME ["/mnt/vrising/server", "/mnt/vrising/persistentdata"]

ARG DEBIAN_FRONTEND="noninteractive"

# Update and install base dependencies (ARM64 native)
RUN apt update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
    apt-utils \
    software-properties-common \
    tzdata \
    wget \
    curl \
    gnupg2 \
    ca-certificates \
    jq \
    xvfb \
    xserver-xorg-video-dummy \
    cabextract \
    git \
    cmake \
    ninja-build \
    build-essential \
    pkg-config \
    ccache \
    clang \
    llvm \
    lld \
    binfmt-support \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    python3 \
    python3-setuptools \
    python-is-python3 \
    squashfs-tools \
    squashfuse \
    fuse \
    libc-bin \
    sudo

# Install native X11 and graphics libraries
RUN apt install -y \
    libxinerama1 \
    libxrender1 \
    libxcomposite1 \
    libxi6 \
    libxcursor1 \
    libxrandr2 \
    libxfixes3 \
    libxext6 \
    libx11-6 \
    libcups2 \
    libfontconfig1 \
    libfreetype6 \
    libosmesa6 \
    mesa-utils \
    libpulse0 \
    libasound2 \
    libglib2.0-0 || true

# Install FEX-Emu from official PPA (better compatibility than Box86 for SteamCMD)
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt update -y && \
    apt install -y fex-emu-arm64ec fex-emu-binfmt32 fex-emu-binfmt64 || \
    apt install -y fex-emu || \
    (echo "FEX PPA failed, building from source..." && \
    cd /tmp && \
    git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DENABLE_LTO=True -DBUILD_TESTS=False -G Ninja .. && \
    ninja && \
    ninja install && \
    ninja binfmt_misc_32 && \
    ninja binfmt_misc_64 && \
    cd / && rm -rf /tmp/FEX)

# Setup FEX RootFS for x86/x86_64 support
RUN FEXRootFSFetcher -y -x || echo "RootFS fetch skipped or failed, will use thunk mode"

# Setup Steam user with proper permissions
RUN useradd -m -s /bin/bash steam && \
    echo "steam ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/steam/.steam && \
    mkdir -p /home/steam/.wine && \
    mkdir -p /home/steam/.fex-emu && \
    mkdir -p /mnt/vrising/server && \
    mkdir -p /mnt/vrising/persistentdata && \
    chown -R steam:steam /home/steam && \
    chown -R steam:steam /mnt/vrising

# Download and setup Wine for x86_64 (using FEX-Emu)
RUN mkdir -p /opt/wine && \
    cd /opt/wine && \
    wget -q https://github.com/Kron4ek/Wine-Builds/releases/download/9.0/wine-9.0-amd64.tar.xz && \
    tar -xf wine-9.0-amd64.tar.xz && \
    rm wine-9.0-amd64.tar.xz && \
    mv wine-9.0-amd64 wine

# Download SteamCMD (x86 Linux binary, will run via FEX-Emu)
USER steam
WORKDIR /home/steam

RUN mkdir -p /home/steam/steamcmd && \
    cd /home/steam/steamcmd && \
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz && \
    chmod +x /home/steam/steamcmd/steamcmd.sh && \
    chmod +x /home/steam/steamcmd/linux32/steamcmd

# Configure FEX for steam user
RUN mkdir -p /home/steam/.fex-emu && \
    echo '{"Config":{"RootFS":""}}' > /home/steam/.fex-emu/Config.json || true

# Switch back to root for final setup
USER root

# Create wrapper scripts
RUN echo '#!/bin/bash\nFEXBash /home/steam/steamcmd/steamcmd.sh "$@"' > /usr/local/bin/steamcmd && \
    chmod +x /usr/local/bin/steamcmd

RUN echo '#!/bin/bash\nFEXInterpreter /opt/wine/wine/bin/wine64 "$@"' > /usr/local/bin/wine64 && \
    chmod +x /usr/local/bin/wine64

# Add Wine environment variables
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine
ENV HOME=/home/steam
ENV USER=steam

# Cleanup
RUN rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    apt autoremove -y

COPY start.sh /start.sh
RUN chmod +x /start.sh

# Run as steam user
USER steam
CMD ["/start.sh"]
