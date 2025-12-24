FROM ubuntu:22.04

# Container metadata
LABEL org.opencontainers.image.title="V Rising ARM64"
LABEL org.opencontainers.image.version="1.0"
LABEL org.opencontainers.image.description="V Rising Dedicated Server for ARM64 using Box64/Wine"
LABEL org.opencontainers.image.source="https://github.com/your-repo/vrising-arm64"

# Build arguments for versioning
ARG BOX86_VERSION=generic-arm
ARG WINE_VERSION=9.22
ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV STEAMCMD_DIR="/usr/games/steamcmd" \
    PATH="$PATH:/usr/games/steamcmd:/opt/wine/bin" \
    # Box64 optimization for Wine compatibility
    BOX64_DYNAREC_SAFEFLAGS=1 \
    BOX64_DYNAREC_STRONGMEM=2 \
    BOX64_LOG=0 \
    BOX64_MAXCPU=64 \
    # Locale
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install dependencies, Box86, Box64, Wine, and SteamCMD in a single layer to reduce image size
RUN dpkg --add-architecture armhf \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wget curl gnupg software-properties-common xvfb xz-utils cabextract tar unzip \
        locales file ca-certificates gosu libcap2-bin \
        # ARM64 libraries for Box64 (Wine x86_64 emulation)
        libgl1 libx11-6 libfontconfig1 libxinerama1 libxrender1 libxcomposite1 \
        libxi6 libxcursor1 libxrandr2 libxxf86vm1 libfreetype6 libglu1-mesa \
        libosmesa6 libxext6 libxfixes3 libasound2 libpulse0 libdbus-1-3 libsm6 \
        libxslt1.1 libxml2 liblcms2-2 libgnutls30 libmpg123-0 libopenal1 \
        libncurses6 libvulkan1 libcups2 libavutil56 libavformat58 libavcodec58 \
        libswresample3 libv4l-0 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
        # Additional libraries for Wayland and XKB (needed by Wine/Box64)
        libwayland-client0 libwayland-egl1 libxkbcommon0 libxkbregistry0 \
        libxcb-xkb1 libxkbcommon-x11-0 libwayland-cursor0 \
        # armhf libraries for Box86 (SteamCMD i386 emulation)
        libc6:armhf libstdc++6:armhf libncurses6:armhf \
    # Unattended upgrades cleanup
    && rm -rf /var/lib/apt/lists/* \
    # Generate locales
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    # Install Box86 and Box64 repo
    && wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list \
    && wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg \
    && wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list \
    && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg \
    && apt-get update \
    && apt-get install -y box64 box86-generic-arm:armhf \
    # Cleanup apt again
    && rm -rf /var/lib/apt/lists/*

# Install Wine x86_64 (using Kron4ek's builds)
RUN mkdir -p /opt/wine \
    && wget -q https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-amd64.tar.xz -O /tmp/wine.tar.xz \
    && tar -xf /tmp/wine.tar.xz -C /opt/wine --strip-components=1 \
    && rm /tmp/wine.tar.xz \
    # Give Wine network capabilities for GetAdaptersAddresses to work
    && setcap cap_net_raw+epi /opt/wine/bin/wine-preloader || true \
    && setcap cap_net_raw+epi /opt/wine/bin/wine64-preloader || true

# Create Box64 wrappers for Wine binaries
RUN mkdir -p /usr/local/bin \
    && for bin in wine64 wine wineserver wineboot; do \
        echo '#!/bin/bash' > /usr/local/bin/$bin; \
        echo "exec box64 /opt/wine/bin/$bin \"\$@\"" >> /usr/local/bin/$bin; \
        chmod +x /usr/local/bin/$bin; \
    done

# Create user `vrising` (UID 1000)
RUN useradd -m -d /home/vrising -s /bin/bash -u 1000 vrising

# Prepare directory structure and permissions
RUN mkdir -p /data/server /data/save-data /data/wine-prefix $STEAMCMD_DIR \
    && chown -R vrising:vrising /data /home/vrising $STEAMCMD_DIR

# Install SteamCMD (as vrising user to ensure permissions are correct in that dir)
# Switching to root to install, then chowning is fine, but better to do it carefully.
# We'll install as root in the standard location but ensure vrising can run it.
RUN mkdir -p $STEAMCMD_DIR \
    && cd $STEAMCMD_DIR \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - \
    && chmod +x steamcmd.sh \
    && chown -R vrising:vrising $STEAMCMD_DIR

# Custom SteamCMD wrapper for Box86
RUN echo '#!/bin/bash' > /usr/bin/steamcmd \
    && echo 'cd /usr/games/steamcmd' >> /usr/bin/steamcmd \
    && echo 'exec box86 ./linux32/steamcmd "$@"' >> /usr/bin/steamcmd \
    && chmod +x /usr/bin/steamcmd

# Bootstrap SteamCMD (as vrising user!)
USER vrising
RUN cd /usr/games/steamcmd && box86 ./linux32/steamcmd +quit || echo "Bootstrap complete"

# Pre-initialize Wine prefix (as vrising user)
RUN mkdir -p /home/vrising/.wine /tmp/.X11-unix \
    && bash -c '\
        export WINEPREFIX=/home/vrising/.wine; \
        export WINEARCH=win64; \
        export WINEDEBUG=-all; \
        export BOX64_LOG=0; \
        Xvfb :99 -screen 0 1024x768x24 & \
        XVFB_PID=$!; \
        sleep 2; \
        export DISPLAY=:99; \
        timeout 60 box64 /opt/wine/bin/wineboot --init || true; \
        timeout 10 box64 /opt/wine/bin/wineserver --wait || true; \
        kill $XVFB_PID 2>/dev/null || true; \
    '

# Copy start script
COPY --chown=vrising:vrising start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Switch to root for init script and cleanup
USER root

# Copy init script (runs as root to fix permissions, then drops to vrising)
COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Give Wine network capabilities (needs to be done as root)
# This helps with Steam's GetAdaptersAddresses call
RUN setcap cap_net_raw+epi /opt/wine/bin/wine-preloader 2>/dev/null || true \
    && setcap cap_net_raw+epi /opt/wine/bin/wine64-preloader 2>/dev/null || true

# Cleanup /tmp just in case
RUN rm -rf /tmp/.X11-unix

WORKDIR /data
VOLUME /data

# Ports for V Rising
EXPOSE 9876/udp
EXPOSE 9877/udp

# Run init.sh as root - it will fix permissions then drop to vrising user
CMD ["/usr/local/bin/init.sh"]

