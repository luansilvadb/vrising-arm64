FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV STEAMCMD_DIR="/usr/games/steamcmd"
ENV PATH="$PATH:$STEAMCMD_DIR:/opt/wine/bin"

# Install basics
RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

# Install Box86 (for SteamCMD) and Box64 (for V Rising / Wine)
RUN wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list \
    && wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg \
    && wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list \
    && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg \
    && apt-get update && apt-get install -y box86 box64 \
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
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

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
