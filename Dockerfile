FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV STEAMCMD_DIR="/usr/games/steamcmd"
ENV PATH="$PATH:$STEAMCMD_DIR:/opt/wine/bin"

# Box64 optimization for Wine compatibility
ENV BOX64_DYNAREC_SAFEFLAGS=1
ENV BOX64_DYNAREC_STRONGMEM=2
ENV BOX64_LOG=1
ENV BOX64_MAXCPU=64

# Enable armhf architecture (for Box86/SteamCMD)
RUN dpkg --add-architecture armhf \
    && apt-get update \
    && apt-get install -y \
    wget \
    curl \
    gnupg \
    software-properties-common \
    xvfb \
    xz-utils \
    cabextract \
    tar \
    unzip \
    locales \
    file \
    # ARM64 libraries for Box64 (Wine x86_64 emulation)
    libgl1 \
    libx11-6 \
    libfontconfig1 \
    libxinerama1 \
    libxrender1 \
    libxcomposite1 \
    libxi6 \
    libxcursor1 \
    libxrandr2 \
    libxxf86vm1 \
    libfreetype6 \
    libglu1-mesa \
    libosmesa6 \
    libxext6 \
    libxfixes3 \
    libasound2 \
    libpulse0 \
    libdbus-1-3 \
    libsm6 \
    libxslt1.1 \
    libxml2 \
    liblcms2-2 \
    libgnutls30 \
    libmpg123-0 \
    libopenal1 \
    libncurses6 \
    libvulkan1 \
    libcups2 \
    libavutil56 \
    libavformat58 \
    libavcodec58 \
    libswresample3 \
    libv4l-0 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    # armhf libraries for Box86 (SteamCMD i386 emulation)
    libc6:armhf \
    libstdc++6:armhf \
    libncurses6:armhf \
    && rm -rf /var/lib/apt/lists/*

# Install Box86 (using generic ARM build) and Box64
RUN wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list \
    && wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg \
    && wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list \
    && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg \
    && apt-get update \
    && apt-get install -y box64 box86-generic-arm:armhf \
    && rm -rf /var/lib/apt/lists/*

# Install Wine x86_64 (using Kron4ek's builds)
# Using staging build which has better game compatibility
RUN mkdir -p /opt/wine \
    && wget -q https://github.com/Kron4ek/Wine-Builds/releases/download/9.22/wine-9.22-staging-amd64.tar.xz -O /tmp/wine.tar.xz \
    && tar -xf /tmp/wine.tar.xz -C /opt/wine --strip-components=1 \
    && rm /tmp/wine.tar.xz

# Create Box64 wrappers for Wine binaries
# This ensures Wine binaries are always run through Box64
RUN mkdir -p /usr/local/bin \
    && echo '#!/bin/bash' > /usr/local/bin/wine64 \
    && echo 'export BOX64_LOG=1' >> /usr/local/bin/wine64 \
    && echo 'exec box64 /opt/wine/bin/wine64 "$@"' >> /usr/local/bin/wine64 \
    && chmod +x /usr/local/bin/wine64 \
    && echo '#!/bin/bash' > /usr/local/bin/wine \
    && echo 'exec box64 /opt/wine/bin/wine "$@"' >> /usr/local/bin/wine \
    && chmod +x /usr/local/bin/wine \
    && echo '#!/bin/bash' > /usr/local/bin/wineserver \
    && echo 'exec box64 /opt/wine/bin/wineserver "$@"' >> /usr/local/bin/wineserver \
    && chmod +x /usr/local/bin/wineserver \
    && echo '#!/bin/bash' > /usr/local/bin/wineboot \
    && echo 'exec box64 /opt/wine/bin/wineboot "$@"' >> /usr/local/bin/wineboot \
    && chmod +x /usr/local/bin/wineboot

# Pre-initialize Wine prefix during build (prevents kernel32.dll errors)
# Using Xvfb to provide a virtual display - simplified to avoid hanging
RUN mkdir -p /root/.wine /tmp/.X11-unix \
    && bash -c '\
        export WINEPREFIX=/root/.wine; \
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

# Install SteamCMD (Linux x86 32-bit, runs via box86)
RUN mkdir -p $STEAMCMD_DIR \
    && cd $STEAMCMD_DIR \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - \
    && chmod +x steamcmd.sh

# Generate locales
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Create wrapper for steamcmd
RUN echo '#!/bin/bash' > /usr/bin/steamcmd \
    && echo 'cd /usr/games/steamcmd' >> /usr/bin/steamcmd \
    && echo 'exec box86 ./linux32/steamcmd "$@"' >> /usr/bin/steamcmd \
    && chmod +x /usr/bin/steamcmd

# Bootstrap SteamCMD during build
RUN cd /usr/games/steamcmd && box86 ./linux32/steamcmd +quit || echo "Bootstrap complete"

# Setup directory structure
WORKDIR /data
VOLUME /data

# Copy start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Ports for V Rising
EXPOSE 9876/udp
EXPOSE 9877/udp

CMD ["/usr/local/bin/start.sh"]
