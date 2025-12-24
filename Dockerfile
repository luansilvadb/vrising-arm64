# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image
# =============================================================================
# Este Dockerfile cria uma imagem ARM64 para rodar o servidor dedicado de 
# V Rising usando Box64/Box86 + Wine para emulação x86/x64.
#
# Testado em: Oracle Cloud ARM64 (Ampere A1) com Ubuntu 20.04
# =============================================================================

# Usar imagem base que já tem Box86/Box64 pré-instalados
FROM weilbyte/box:debian-11

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
    # Box86/Box64 settings
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1"

# =============================================================================
# Instalação de dependências adicionais
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Utilitários básicos
    ca-certificates \
    curl \
    wget \
    xz-utils \
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
# Instalar Wine (via Box64)
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
RUN xvfb-run -a box64 /opt/wine/bin/wineboot --init && \
    box64 /opt/wine/bin/wineserver -w || true

# =============================================================================
# Instalar SteamCMD (versão Linux x86)
# =============================================================================
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz && \
    rm steamcmd.tar.gz && \
    chmod +x steamcmd.sh && \
    # Rodar SteamCMD uma vez para baixar as dependências iniciais
    box86 /opt/steamcmd/linux32/steamcmd +quit || true

# =============================================================================
# Criar diretórios necessários
# =============================================================================
RUN mkdir -p /data/server /data/saves /data/logs /scripts

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
