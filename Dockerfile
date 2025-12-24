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
    binfmt-support \
    squashfs-tools \
    squashfuse \
    fuse \
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

# Install FEX-Emu from official PPA
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt update -y && \
    apt install -y fex-emu

# Setup FEX RootFS for x86/x86_64 support (using Ubuntu image)
# Run as root first to fetch RootFS
RUN mkdir -p /root/.fex-emu && \
    FEXRootFSFetcher -y || echo "RootFS fetch completed or skipped"

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

# Copy FEX config to steam user (use same RootFS)
RUN cp -r /root/.fex-emu/* /home/steam/.fex-emu/ 2>/dev/null || true && \
    chown -R steam:steam /home/steam/.fex-emu

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
    FEXRootFSFetcher -y || true

# Switch back to root for final setup
USER root

# Create wrapper scripts
RUN echo '#!/bin/bash\nFEXBash "$@"' > /usr/local/bin/run-x86 && \
    chmod +x /usr/local/bin/run-x86

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
