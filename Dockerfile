FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV STEAMCMD_DIR="/usr/games/steamcmd"
ENV PATH="$PATH:$STEAMCMD_DIR:/opt/wine/bin"

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
    libgl1 \
    libx11-6 \
    cabextract \
    tar \
    unzip \
    locales \
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

# Install Wine x86_64 (using Kron4ek's builds for portable usage)
# We use a specific version known to be stable with V Rising if possible, but latest staging is usually good.
RUN mkdir -p /opt/wine \
    && wget -q https://github.com/Kron4ek/Wine-Builds/releases/download/9.0/wine-9.0-amd64.tar.xz -O /tmp/wine.tar.xz \
    && tar -xf /tmp/wine.tar.xz -C /opt/wine --strip-components=1 \
    && rm /tmp/wine.tar.xz

# Install SteamCMD (Linux x86 32-bit, runs via box86)
RUN mkdir -p $STEAMCMD_DIR \
    && cd $STEAMCMD_DIR \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - \
    && chmod +x steamcmd.sh

# Generate locales to silence steamcmd errors
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Setup Box86 as binfmt handler for i386 binaries
# This makes Linux kernel automatically use box86 for any 32-bit x86 ELF executable
RUN echo ':BOX86:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\x00\x00\x00\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/local/bin/box86:' > /usr/share/binfmts/box86

# Create wrapper that explicitly calls box86 (as fallback if binfmt doesn't work in container)
RUN echo '#!/bin/bash' > /usr/bin/steamcmd \
    && echo 'cd /usr/games/steamcmd' >> /usr/bin/steamcmd \
    && echo 'exec box86 ./linux32/steamcmd "$@"' >> /usr/bin/steamcmd \
    && chmod +x /usr/bin/steamcmd

# Bootstrap SteamCMD during build to download updates
# We do NOT rename/wrap the binary anymore - let it update naturally
# The /usr/bin/steamcmd wrapper always calls box86 explicitly
RUN cd /usr/games/steamcmd && box86 ./linux32/steamcmd +quit || echo "Bootstrap complete (exit ok)"

# Setup directory structure
WORKDIR /data
VOLUME /data

# Link start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Ports for V Rising
EXPOSE 9876/udp
EXPOSE 9877/udp

CMD ["/usr/local/bin/start.sh"]
