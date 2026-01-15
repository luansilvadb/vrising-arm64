# ============================================================================
# V Rising Dedicated Server - ARM64 (Rust Edition)
# Based on luansilvadb/vrising-arm64 (develop branch)
# Using FEXInterpreter + Wine for x86-64 emulation on ARM64
# ============================================================================

# ============================================================================
# Stage 1: Builder (Compile Rust Launcher)
# ============================================================================
FROM rust:slim-bullseye AS builder

WORKDIR /usr/src/app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY Cargo.toml Cargo.lock ./
COPY src ./src

# Build release binary
RUN cargo build --release

# ============================================================================
# Stage 2: Runtime (Production Image)
# ============================================================================
FROM arm64v8/ubuntu:22.04

LABEL maintainer="V Rising ARM64 Server"
LABEL description="V Rising Dedicated Server for ARM64 using FEXInterpreter/Wine - Rust Launcher"

# ============================================================================
# Build Arguments
# ============================================================================
ARG WINE_VERSION=10.0

# ============================================================================
# Environment Variables - IDÊNTICAS ao start.sh original
# ============================================================================
ENV DEBIAN_FRONTEND=noninteractive \
    # Server Settings
    APP_ID=1829350 \
    SERVER_NAME="V Rising FEX Server" \
    SAVE_NAME="world1" \
    SERVER_DIR=/data/server \
    STEAMCMD_DIR=/data/steamcmd \
    STEAMCMD_ORIG=/steamcmd \
    UPDATE_ON_START=true \
    GAME_PORT=9876 \
    QUERY_PORT=9877 \
    # Host Settings
    MAX_CONNECTED_USERS=100 \
    MAX_CONNECTED_ADMINS=5 \
    SERVER_FPS=60 \
    SERVER_PASSWORD="" \
    SECURE=true \
    AUTO_SAVE_COUNT=25 \
    AUTO_SAVE_INTERVAL=120 \
    COMPRESS_SAVE_FILES=true \
    GAME_SETTINGS_PRESET="" \
    GAME_DIFFICULTY_PRESET="" \
    ADMIN_ONLY_DEBUG_EVENTS=true \
    DISABLE_DEBUG_EVENTS=true \
    API_ENABLED=false \
    RCON_ENABLED=true \
    RCON_PORT=25575 \
    RCON_PASSWORD="" \
    LIST_ON_MASTER_SERVER=true \
    # Wine Configuration
    WINE_BIN=/opt/wine/bin/wine64 \
    WINEPREFIX=/data/wineprefix \
    WINEARCH=win64 \
    DISPLAY=:0 \
    # FEX Configuration
    FEX_TSOENABLE=0 \
    # Unity GC Settings
    GC_DONT_GC=0 \
    UNITY_GC_MODE=incremental \
    WINE_TCP_BUFFER_SIZE=65536 \
    # Debug
    DEBUG=false \
    # Performance
    WINEESYNC=1 \
    WINEFSYNC=1 \
    STAGING_SHARED_MEMORY=1 \
    # Memory Allocator
    MALLOC_CONF=background_thread:true,metadata_thp:auto,dirty_decay_ms:30000,muzzy_decay_ms:30000 \
    TZ=America/Sao_Paulo

# ============================================================================
# Install Dependencies
# ============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    ca-certificates \
    curl \
    wget \
    xz-utils \
    # X11/Display
    xvfb \
    # System utilities
    jq \
    tzdata \
    netcat-openbsd \
    procps \
    locales \
    # Performance
    libjemalloc2 \
    # Wine dependencies
    libresolv-wrapper \
    libxinerama1 \
    libxrandr2 \
    libxcomposite1 \
    libxi6 \
    libxcursor1 \
    libcups2 \
    libegl1 \
    libfreetype6 \
    libfontconfig1 \
    libxext6 \
    libxrender1 \
    libsm6 \
    # Graphics/Display dependencies (Required for Unity/Wine) \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libvulkan1 \
    mesa-vulkan-drivers \
    libx11-6 \
    libxtst6 \
    dbus \
    cabextract \
    # Additional libs for FEX
    libepoxy0 \
    libsdl2-2.0-0 \
    squashfs-tools \
    erofs-utils \
    # For FEX PPA (Manual addition is more robust in Docker)
    gpg \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

# ============================================================================
# Install FEX-Emu from Official PPA (Ubuntu 22.04)
# ============================================================================
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xEDB98BFE8A2310DC9C4A376E76DBFEBEA206F5AC" | gpg --dearmor -o /etc/apt/keyrings/fex-emu.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/fex-emu.gpg] http://ppa.launchpad.net/fex-emu/fex/ubuntu jammy main" > /etc/apt/sources.list.d/fex-emu.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends fex-emu-armv8.2 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# Setup FEX RootFS (Ubuntu 22.04)
# ============================================================================
RUN mkdir -p /root/.fex-emu/RootFS \
    && curl -Lo rootfs.sqsh "https://rootfs.fex-emu.gg/Ubuntu_22_04/2025-01-08/Ubuntu_22_04.sqsh" \
    && unsquashfs -d /root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.sqsh \
    && rm rootfs.sqsh \
    && echo '{"Config":{"RootFS":"Ubuntu_22.04"}}' > /root/.fex-emu/Config.json

# ============================================================================
# Install Wine
# ============================================================================
RUN curl -Lo wine.tar.xz "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-amd64.tar.xz" \
    && tar -xf wine.tar.xz -C /opt \
    && mv "/opt/wine-${WINE_VERSION}-staging-amd64" /opt/wine \
    && rm wine.tar.xz

ENV PATH="/opt/wine/bin:$PATH"

# ============================================================================
# Install SteamCMD
# ============================================================================
RUN mkdir -p /steamcmd \
    && curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxf - -C /steamcmd

# ============================================================================
# Prepare directories
# ============================================================================
RUN mkdir -p /data/server /data/steamcmd /data/wineprefix /data/save-data/Settings /data/logs

# ============================================================================
# Copy Rust binary from builder
# ============================================================================
COPY --from=builder /usr/src/app/target/release/vrising-launcher /usr/local/bin/vrising-launcher
RUN chmod +x /usr/local/bin/vrising-launcher

# ============================================================================
# Optional: Copy custom ServerGameSettings.json if exists
# ============================================================================
COPY ServerGameSettings.json /ServerGameSettings.json

# ============================================================================
# Network
# ============================================================================
EXPOSE 9876/udp 9877/udp 9876/tcp 9877/tcp

# ============================================================================
# Volume
# ============================================================================
VOLUME ["/data"]

# ============================================================================
# Health Check - IDÊNTICO ao original
# ============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f VRisingServer.exe > /dev/null || exit 1

# ============================================================================
# Entrypoint - Rust Launcher substitui start.sh
# ============================================================================
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/vrising-launcher"]
