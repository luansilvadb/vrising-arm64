# Base image: Ubuntu 24.04 (Noble) for ARM64
FROM ubuntu:24.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 1. Install Dependencies & Tools
# - curl/wget/jq: Downloading and processing
# - software-properties-common: For add-apt-repository
# - netcat-openbsd: For Healthchecks
# - Graphics/Wine deps: mesa, vulkan, x11, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    jq \
    nano \
    gnupg \
    software-properties-common \
    tar \
    xz-utils \
    unzip \
    cabextract \
    dbus \
    xvfb \
    netcat-openbsd \
    # Graphics & Audio Libs
    libgl1-mesa-dri \
    libglx-mesa0 \
    libvulkan1 \
    mesa-vulkan-drivers \
    libx11-6 \
    libxcomposite1 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    libxrandr2 \
    libfreetype6 \
    libfontconfig1 \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install FEX-Emu (Host)
# Using PPA for latest stable
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt-get update && \
    apt-get install -y fex-emu-armv8.2 && \
    rm -rf /var/lib/apt/lists/*

# 3. Setup FEX User and RootFS
WORKDIR /root

# Download and Extract FEX RootFS (Ubuntu 22.04 x86-64)
# Optimizing extraction logic
RUN echo "Fetching FEX RootFS..." && \
    ROOTFS_INFO=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json) && \
    ROOTFS_URL=$(echo "$ROOTFS_INFO" | jq -r '.v1 | to_entries[] | select(.value.DistroMatch == "ubuntu" and .value.DistroVersion == "22.04") | .value.URL' | head -n 1) && \
    echo "Downloading RootFS from $ROOTFS_URL..." && \
    curl -L -o rootfs.img "$ROOTFS_URL" && \
    mkdir -p /root/.fex-emu/RootFS/Ubuntu_22.04 && \
    if echo "$ROOTFS_URL" | grep -q ".ero$"; then \
    echo "Extracting EroFS..." && \
    fsck.erofs --extract=/root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.img; \
    else \
    echo "Extracting SquashFS..." && \
    unsquashfs -f -d /root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.img; \
    fi && \
    rm rootfs.img && \
    mkdir -p /root/.fex-emu && \
    echo '{"Config":{"RootFS":"Ubuntu_22.04"}}' > /root/.fex-emu/Config.json

# 4. Install Wine (x86-64) - Kron4ek Builds (Staging)
# Defined via ENV for easier version management
ENV WINE_VERSION="9.4"

RUN echo "Installing Wine (x86-64) v${WINE_VERSION}..." && \
    WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-amd64.tar.xz" && \
    curl -L -o wine.tar.xz "$WINE_URL" && \
    tar -xf wine.tar.xz -C /opt && \
    mv /opt/wine-${WINE_VERSION}-staging-amd64 /opt/wine && \
    rm wine.tar.xz

# Add Wine to PATH
ENV PATH="/opt/wine/bin:$PATH"

# 5. Setup SteamCMD (Linux x86)
RUN mkdir -p /steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /steamcmd

# 6. Environment Variables
# Persistence & Configs
ENV STEAMCMD_DIR="/data/steamcmd" \
    SERVER_DIR="/data/server" \
    WINEPREFIX="/data/wineprefix" \
    WINEARCH="win64" \
    DISPLAY=":0" 

# 7. Add Startup Script
COPY start.sh /
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

# 8. Expose Ports & Healthcheck
# V Rising Default: 9876, 9877 UDP
EXPOSE 9876/udp 9877/udp 9876/tcp 9877/tcp

# Healthcheck: Queries the Query Port (9877/udp)
# Requires 'netcat-openbsd' which we installed.
# We send a dummy packet or just check if port is open. 
# Since it's UDP, reliable check needs a specific payload, but for now we look for process/port existence via simple means or assume starting.
# Actually, netcat udp check with zero I/O is tricky.
# Simpler: Check if VRisingServer.exe process is running.
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f VRisingServer.exe > /dev/null || exit 1

# 9. Volume for persistence
VOLUME ["/data"]

# Entrypoint
ENTRYPOINT ["/start.sh"]
