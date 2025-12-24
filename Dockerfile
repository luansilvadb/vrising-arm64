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
    python3

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
    apt install -y box64 box86:armhf

# Install armhf libraries needed by Box86
RUN apt install -y \
    libc6:armhf \
    libstdc++6:armhf \
    libasound2:armhf \
    libglib2.0-0:armhf \
    libgphoto2-6:armhf \
    libgphoto2-port12:armhf \
    libgstreamer-plugins-base1.0-0:armhf \
    libgstreamer1.0-0:armhf \
    libldap-2.5-0:armhf \
    libopenal1:armhf \
    libpcap0.8:armhf \
    libpulse0:armhf \
    libsane1:armhf \
    libudev1:armhf \
    libusb-1.0-0:armhf \
    libvkd3d1:armhf \
    libx11-6:armhf \
    libxext6:armhf \
    libfreetype6:armhf \
    libfontconfig1:armhf \
    libjpeg62:armhf || true

# Download and setup Wine for ARM64 (using box64/box86)
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

# Setup Steam user
RUN useradd -m steam && \
    mkdir -p /home/steam/.steam && \
    chown -R steam:steam /home/steam

# Download SteamCMD (x86 Linux binary, will run via box86)
RUN mkdir -p /home/steam/steamcmd && \
    cd /home/steam/steamcmd && \
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz && \
    chown -R steam:steam /home/steam/steamcmd

# Create wrapper script for steamcmd using box86
RUN echo '#!/bin/bash\nexec box86 /home/steam/steamcmd/steamcmd.sh "$@"' > /usr/local/bin/steamcmd && \
    chmod +x /usr/local/bin/steamcmd

# Add Wine environment variables
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine
ENV BOX64_LOG=0
ENV BOX86_LOG=0
ENV BOX64_LD_LIBRARY_PATH=/opt/wine/wine/lib/wine/x86_64-unix:/lib/x86_64-linux-gnu
ENV BOX86_LD_LIBRARY_PATH=/opt/wine/wine/lib/wine/i386-unix:/lib/i386-linux-gnu

# Cleanup
RUN rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    apt autoremove -y

COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
