# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image
# =============================================================================
# Este Dockerfile cria uma imagem ARM64 para rodar o servidor dedicado de 
# V Rising usando Box64/Box86 + Wine para emulação x86/x64.
#
# Testado em: Oracle Cloud ARM64 (Ampere A1) com Ubuntu 22.04
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
    DISPLAY=":0"

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
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Adicionar arquitetura armhf (necessário para Box86)
# =============================================================================
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    libc6:armhf \
    libstdc++6:armhf \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Instalar Box64 (emulador x86_64 para ARM64)
# =============================================================================
RUN wget -qO- https://pi-apps-coders.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /usr/share/keyrings/box64-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/box64-archive-keyring.gpg] https://Pi-Apps-Coders.github.io/box64-debs/debian ./" | tee /etc/apt/sources.list.d/box64.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends box64-generic-arm && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Instalar Box86 (emulador x86 para ARM - necessário para SteamCMD)
# =============================================================================
RUN wget -qO- https://pi-apps-coders.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /usr/share/keyrings/box86-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/box86-archive-keyring.gpg] https://Pi-Apps-Coders.github.io/box86-debs/debian ./" | tee /etc/apt/sources.list.d/box86.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends box86-generic-arm:armhf && \
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
RUN xvfb-run -a wineboot --init && \
    wineserver -w || true

# =============================================================================
# Instalar SteamCMD
# =============================================================================
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz && \
    rm steamcmd.tar.gz && \
    chmod +x steamcmd.sh

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
EXPOSE ${GAME_PORT}/udp ${QUERY_PORT}/udp

# =============================================================================
# Volumes para persistência
# =============================================================================
VOLUME ["${SERVER_DIR}", "${SAVES_DIR}"]

# =============================================================================
# Healthcheck
# =============================================================================
HEALTHCHECK --interval=60s --timeout=10s --start-period=300s --retries=3 \
    CMD nc -zu localhost ${GAME_PORT} || exit 1

# =============================================================================
# Entrypoint
# =============================================================================
WORKDIR /data
ENTRYPOINT ["/scripts/entrypoint.sh"]
