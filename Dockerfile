# ==========================================
# STAGE 1: Builder (Box64 & Box86 specific)
# ==========================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Enable armhf architecture for Box86 build deps
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y \
    git cmake python3 gcc g++ \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    build-essential

WORKDIR /src

# --- Build Box64 (For V Rising Server - x86_64) ---
# Cloning latest for best compatibility
RUN git clone https://github.com/ptitSeb/box64.git
WORKDIR /src/box64
RUN mkdir build && cd build && \
    cmake .. \
    -DARM_DYNAREC=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DNOGIT=1 && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

# --- Build Box86 (For SteamCMD - x86) ---
# Needed because Linux SteamCMD is 32-bit
WORKDIR /src
RUN git clone https://github.com/ptitSeb/box86.git
WORKDIR /src/box86
RUN mkdir build && cd build && \
    cmake .. \
    -DARM_DYNAREC=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DNOGIT=1 && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

# ==========================================
# STAGE 2: Runtime
# ==========================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PUID=10000
ENV PGID=10000

# 1. Install Runtime Dependencies
# We need armhf libs for Box86/SteamCMD and standard libs for Box64/Wine
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libc6:armhf libstdc++6:armhf \
    wget curl tar cabextract \
    xvfb xauth \
    libgl1 libx11-6 \
    libgl1 libx11-6 libfreetype6 \
    netcat \
    # Dependencies for portable Wine extraction
    xz-utils && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Install Portable Wine (x86_64) for V Rising
    mkdir -p /opt/wine && \
    wget -qO- https://github.com/Kron4ek/Wine-Builds/releases/download/9.4/wine-9.4-staging-amd64.tar.xz | tar xJ -C /opt/wine --strip-components=1

# 2. Copy Box64/Box86 from builder
COPY --from=builder /tmp/install/usr/local/bin/box64 /usr/local/bin/box64
COPY --from=builder /tmp/install/usr/local/lib/box64 /usr/local/lib/box64
COPY --from=builder /tmp/install/usr/local/bin/box86 /usr/local/bin/box86
COPY --from=builder /tmp/install/usr/local/lib/box86 /usr/local/lib/box86
COPY --from=builder /tmp/install/etc/binfmt.d /etc/binfmt.d

# 3. Setup User and Directories
RUN groupadd -g ${PGID} vrising && \
    useradd -u ${PUID} -g vrising -m -s /bin/bash vrising && \
    mkdir -p /app /data /steam /data/wine-prefix && \
    chown -R vrising:vrising /app /data /steam

# 4. Install SteamCMD
# We install it manually to /usr/local/bin/steamcmd and ensure it runs via box86
WORKDIR /tmp
RUN mkdir -p /usr/lib/games/steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /usr/lib/games/steamcmd && \
    chown -R vrising:vrising /usr/lib/games/steamcmd
    
# Create a wrapper for steamcmd to force box86 execution
# We point directly to the linux32 binary because box86 cannot run shell scripts (steamcmd.sh)
RUN echo '#!/bin/bash' > /usr/local/bin/steamcmd && \
    echo 'export LD_LIBRARY_PATH=/usr/lib/games/steamcmd/linux32:$LD_LIBRARY_PATH' >> /usr/local/bin/steamcmd && \
    echo 'exec box86 /usr/lib/games/steamcmd/linux32/steamcmd "$@"' >> /usr/local/bin/steamcmd && \
    chmod +x /usr/local/bin/steamcmd

# 5. Copy Scripts
COPY wine-preloader-wrapper /usr/local/bin/
COPY healthcheck.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wine-preloader-wrapper \
             /usr/local/bin/healthcheck.sh \
             /usr/local/bin/entrypoint.sh

# 6. Final Setup
USER vrising
WORKDIR /app
VOLUME ["/data", "/steam"]
EXPOSE 27015/udp 27016/udp


# Pre-configuration for Wine/Box64
ENV PATH="/opt/wine/bin:$PATH"
ENV WINEPREFIX="/data/wine-prefix"
ENV WINEARCH=win64
ENV BOX64_DYNAREC=1

HEALTHCHECK --interval=60s --timeout=5s --start-period=300s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
