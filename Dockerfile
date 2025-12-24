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
    libfreetype6 \
    libfontconfig1 \
    git \
    cmake \
    build-essential \
    python3 \
    sudo

# Add Box86 and Box64 repositories
RUN wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list && \
    wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg && \
    wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list && \
    wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg

# Enable armhf architecture for Box86 dependencies
RUN dpkg --add-architecture armhf && \
    apt update -y

# Install Box64 and Box86
RUN apt install -y box64-generic-arm box86-generic-arm:armhf || \
    apt install -y box64-rpi4arm64 box86-rpi4arm64:armhf || \
    apt install -y box64 box86:armhf || \
    (echo "Trying alternative box install" && apt install -y box64 box86)

# Install armhf libraries needed by Box86
RUN apt install -y \
    libc6:armhf \
    libstdc++6:armhf \
    libncurses5:armhf \
    libncurses6:armhf \
    libtinfo6:armhf || true

# Setup Steam user with proper permissions
RUN useradd -m -s /bin/bash steam && \
    echo "steam ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/steam/.steam && \
    mkdir -p /home/steam/.wine && \
    mkdir -p /mnt/vrising/server && \
    mkdir -p /mnt/vrising/persistentdata && \
    chown -R steam:steam /home/steam && \
    chown -R steam:steam /mnt/vrising

# Download and setup Wine for ARM64 (using box64)
RUN mkdir -p /opt/wine && \
    cd /opt/wine && \
    wget -q https://github.com/Kron4ek/Wine-Builds/releases/download/9.0/wine-9.0-amd64.tar.xz && \
    tar -xf wine-9.0-amd64.tar.xz && \
    rm wine-9.0-amd64.tar.xz && \
    mv wine-9.0-amd64 wine && \
    ln -sf /opt/wine/wine/bin/wine64 /usr/local/bin/wine64 && \
    ln -sf /opt/wine/wine/bin/wine /usr/local/bin/wine && \
    ln -sf /opt/wine/wine/bin/wineserver /usr/local/bin/wineserver && \
    ln -sf /opt/wine/wine/bin/winecfg /usr/local/bin/winecfg

# Download SteamCMD (x86 Linux binary, will run via box86)
USER steam
WORKDIR /home/steam

RUN mkdir -p /home/steam/steamcmd && \
    cd /home/steam/steamcmd && \
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz && \
    chmod +x /home/steam/steamcmd/steamcmd.sh && \
    chmod +x /home/steam/steamcmd/linux32/steamcmd

# Switch back to root for final setup
USER root

# Create wrapper script for steamcmd using box86 (pointing to the actual binary)
RUN echo '#!/bin/bash\nexec box86 /home/steam/steamcmd/linux32/steamcmd "$@"' > /usr/local/bin/steamcmd && \
    chmod +x /usr/local/bin/steamcmd

# Add Wine environment variables
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine
ENV BOX64_LOG=0
ENV BOX86_LOG=0
ENV BOX64_LD_LIBRARY_PATH=/opt/wine/wine/lib/wine/x86_64-unix:/lib/x86_64-linux-gnu
ENV BOX86_LD_LIBRARY_PATH=/opt/wine/wine/lib/wine/i386-unix:/lib/i386-linux-gnu
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
