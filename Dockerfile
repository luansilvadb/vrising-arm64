# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image
# =============================================================================
# Este Dockerfile cria uma imagem ARM64 para rodar o servidor dedicado de 
# V Rising usando Box64/Box86 + Wine para emulação x86/x64.
#
# Testado em: Oracle Cloud ARM64 (Ampere A1) com Ubuntu 20.04
# =============================================================================

FROM debian:bookworm-slim

LABEL maintainer="VRising ARM64 Server"
LABEL description="V Rising Dedicated Server for ARM64 using Box64/Wine"

# =============================================================================
# Variáveis de ambiente padrão
# =============================================================================
ENV DEBIAN_FRONTEND=noninteractive \
    # Configurações do servidor
    SERVER_NAME="V Rising Server" \
    WORLD_NAME="world1" \
    PASSWORD="" \
    MAX_USERS="40" \
    GAME_PORT="9876" \
    QUERY_PORT="9877" \
    # Lista de servidores públicos
    LIST_ON_MASTER_SERVER="false" \
    LIST_ON_EOS="false" \
    # Modo de jogo (PvP ou PvE)
    GAME_MODE_TYPE="PvP" \
    # Timezone
    TZ="America/Sao_Paulo" \
    # Diretórios
    SERVER_DIR="/data/server" \
    SAVES_DIR="/data/saves" \
    # Steam App ID do V Rising Dedicated Server
    VRISING_APP_ID="1829350" \
    # Wine
    WINEPREFIX="/root/.wine" \
    WINEARCH="win64" \
    WINEDEBUG="-all" \
    # Display virtual
    DISPLAY=":0" \
    # Box86/Box64 paths
    BOX86_PATH="/usr/local/bin/box86" \
    BOX64_PATH="/usr/local/bin/box64" \
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    # Library paths para Box86
    LD_LIBRARY_PATH="/usr/lib/arm-linux-gnueabihf:/lib/arm-linux-gnueabihf"

# =============================================================================
# Instalação de dependências base
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Utilitários básicos
    ca-certificates \
    curl \
    wget \
    gnupg2 \
    xz-utils \
    # Bibliotecas necessárias
    libatomic1 \
    libc6 \
    libgcc-s1 \
    libstdc++6 \
    # Display virtual para Wine
    xvfb \
    # JSON processing
    jq \
    # Timezone
    tzdata \
    # Networking
    netcat-openbsd \
    # Procps para ps
    procps \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Adicionar arquitetura armhf (necessário para Box86 e SteamCMD)
# =============================================================================
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    # Bibliotecas essenciais armhf para SteamCMD
    libc6:armhf \
    libstdc++6:armhf \
    libncurses6:armhf \
    libtinfo6:armhf \
    libcurl4:armhf \
    libssl3:armhf \
    zlib1g:armhf \
    libsdl2-2.0-0:armhf \
    libatomic1:armhf \
    libpulse0:armhf \
    libopenal1:armhf \
    libgl1:armhf \
    libglu1-mesa:armhf \
    libasound2:armhf \
    libcap2:armhf \
    libdbus-1-3:armhf \
    libfontconfig1:armhf \
    libfreetype6:armhf \
    libglib2.0-0:armhf \
    libice6:armhf \
    libpng16-16:armhf \
    libsm6:armhf \
    libusb-1.0-0:armhf \
    libx11-6:armhf \
    libxau6:armhf \
    libxcb1:armhf \
    libxcursor1:armhf \
    libxdmcp6:armhf \
    libxext6:armhf \
    libxfixes3:armhf \
    libxi6:armhf \
    libxinerama1:armhf \
    libxrandr2:armhf \
    libxrender1:armhf \
    libxxf86vm1:armhf \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Instalar Box86 (emulador x86 para ARM - necessário para SteamCMD)
# =============================================================================
RUN wget -qO- https://pi-apps-coders.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /usr/share/keyrings/box86-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/box86-archive-keyring.gpg arch=armhf] https://Pi-Apps-Coders.github.io/box86-debs/debian bookworm main" | tee /etc/apt/sources.list.d/box86.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends box86-generic-arm:armhf && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Instalar Box64 (emulador x86_64 para ARM64)
# =============================================================================
RUN wget -qO- https://pi-apps-coders.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /usr/share/keyrings/box64-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/box64-archive-keyring.gpg] https://Pi-Apps-Coders.github.io/box64-debs/debian bookworm main" | tee /etc/apt/sources.list.d/box64.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends box64-generic-arm && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Instalar Wine (via Box64/Box86)
# =============================================================================
RUN mkdir -p /opt/wine && \
    # Baixar Wine x86_64
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/9.22/wine-9.22-amd64.tar.xz" -O /tmp/wine.tar.xz && \
    tar -xf /tmp/wine.tar.xz -C /opt/wine --strip-components=1 && \
    rm /tmp/wine.tar.xz && \
    # Criar links simbólicos
    ln -sf /opt/wine/bin/wine64 /usr/local/bin/wine64 && \
    ln -sf /opt/wine/bin/wine /usr/local/bin/wine && \
    ln -sf /opt/wine/bin/wineboot /usr/local/bin/wineboot && \
    ln -sf /opt/wine/bin/winecfg /usr/local/bin/winecfg && \
    ln -sf /opt/wine/bin/wineserver /usr/local/bin/wineserver

# =============================================================================
# Inicializar Wine prefix
# =============================================================================
RUN xvfb-run -a box64 wineboot --init && \
    box64 wineserver -w || true

# =============================================================================
# Instalar SteamCMD (versão Linux x86)
# =============================================================================
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz && \
    rm steamcmd.tar.gz && \
    chmod +x steamcmd.sh && \
    # Criar wrapper script para executar SteamCMD via Box86
    echo '#!/bin/bash' > /usr/local/bin/steamcmd && \
    echo 'cd /opt/steamcmd' >> /usr/local/bin/steamcmd && \
    echo 'exec box86 /opt/steamcmd/linux32/steamcmd "$@"' >> /usr/local/bin/steamcmd && \
    chmod +x /usr/local/bin/steamcmd && \
    # Rodar SteamCMD uma vez para baixar as dependências
    cd /opt/steamcmd && \
    box86 ./linux32/steamcmd +quit || true

# =============================================================================
# Criar diretórios necessários
# =============================================================================
RUN mkdir -p ${SERVER_DIR} ${SAVES_DIR} /data/logs /scripts

# =============================================================================
# Copiar scripts
# =============================================================================
COPY scripts/entrypoint.sh /scripts/entrypoint.sh
RUN chmod +x /scripts/entrypoint.sh

# =============================================================================
# Expor portas
# =============================================================================
EXPOSE 9876/udp 9877/udp

# =============================================================================
# Volumes para persistência
# =============================================================================
VOLUME ["/data/server", "/data/saves"]

# =============================================================================
# Healthcheck
# =============================================================================
HEALTHCHECK --interval=60s --timeout=10s --start-period=600s --retries=3 \
    CMD nc -zu localhost 9876 || exit 1

# =============================================================================
# Entrypoint
# =============================================================================
WORKDIR /data
ENTRYPOINT ["/scripts/entrypoint.sh"]
