FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    WINE_VERSION=9.4

# All dependencies in single layer for minimal image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget jq gnupg software-properties-common \
    tar xz-utils unzip cabextract dbus xvfb netcat-openbsd \
    libgl1-mesa-dri libglx-mesa0 libvulkan1 mesa-vulkan-drivers \
    libx11-6 libxcomposite1 libxcursor1 libxi6 libxtst6 libxrandr2 \
    libfreetype6 libfontconfig1 libdbus-1-3 \
    && add-apt-repository -y ppa:fex-emu/fex \
    && apt-get update && apt-get install -y fex-emu-armv8.2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# FEX RootFS (Ubuntu 22.04 x86-64)
RUN ROOTFS_URL=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json | \
    jq -r '.v1 | to_entries[] | select(.value.DistroMatch == "ubuntu" and .value.DistroVersion == "22.04") | .value.URL' | head -1) \
    && curl -Lo rootfs.img "$ROOTFS_URL" \
    && mkdir -p /root/.fex-emu/RootFS/Ubuntu_22.04 \
    && if echo "$ROOTFS_URL" | grep -q '\.ero$'; then \
    fsck.erofs --extract=/root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.img; \
    else \
    unsquashfs -f -d /root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.img; \
    fi \
    && rm rootfs.img \
    && echo '{"Config":{"RootFS":"Ubuntu_22.04"}}' > /root/.fex-emu/Config.json

# Wine (x86-64 staging)
RUN curl -Lo wine.tar.xz "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-amd64.tar.xz" \
    && tar -xf wine.tar.xz -C /opt \
    && mv "/opt/wine-${WINE_VERSION}-staging-amd64" /opt/wine \
    && rm wine.tar.xz

# SteamCMD
RUN mkdir -p /steamcmd \
    && curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxf - -C /steamcmd

ENV PATH="/opt/wine/bin:$PATH" \
    STEAMCMD_DIR=/data/steamcmd \
    SERVER_DIR=/data/server \
    WINEPREFIX=/data/wineprefix \
    WINEARCH=win64 \
    DISPLAY=:0

COPY start.sh /
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 9876/udp 9877/udp 9876/tcp 9877/tcp

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f VRisingServer.exe > /dev/null || exit 1

VOLUME ["/data"]
ENTRYPOINT ["/start.sh"]
