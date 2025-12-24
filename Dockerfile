# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image
# =============================================================================
# Este Dockerfile cria uma imagem ARM64 para rodar o servidor dedicado de 
# V Rising usando Box64 + Wine WOW64 para emulação x86/x64.
#
# Testado em: Oracle Cloud ARM64 (Ampere A1) com Ubuntu 20.04
# =============================================================================

# Usar imagem que já tem Box86/Box64 pré-compilados
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
    WINEPREFIX="/data/wine" \
    WINEARCH="win64" \
    WINEDEBUG="-all" \
    # Display virtual
    DISPLAY=":0" \
    # Box settings - habilitar WOW64
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1" \
    BOX64_WINE_PRELOADED="1" \
    BOX64_LD_LIBRARY_PATH="/opt/wine/lib/wine/x86_64-unix:/opt/wine/lib"

# =============================================================================
# Instalação de dependências adicionais
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    xz-utils \
    xvfb \
    jq \
    tzdata \
    netcat-openbsd \
    procps \
    locales \
    # Bibliotecas adicionais para Wine
    libfreetype6 \
    libfontconfig1 \
    libxext6 \
    libxrender1 \
    libsm6 \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true \
    && locale-gen 2>/dev/null || true

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# =============================================================================
# Instalar Wine 9.x com WOW64 (versão que funciona melhor com Box64)
# =============================================================================
RUN mkdir -p /opt/wine && \
    cd /tmp && \
    # Usar Wine 11.0-rc3 com WOW64
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/11.0-rc3/wine-11.0-rc3-amd64-wow64.tar.xz" -O wine.tar.xz && \
    tar -xf wine.tar.xz -C /opt/wine --strip-components=1 && \
    rm wine.tar.xz && \
    # Verificar arquivos
    ls -la /opt/wine/bin/

# =============================================================================
# Instalar SteamCMD (versão Linux x86)
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
RUN mkdir -p /data/server /data/saves /data/logs /data/wine /scripts

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
VOLUME ["/data"]

# =============================================================================
# Healthcheck
# =============================================================================
HEALTHCHECK --interval=60s --timeout=10s --start-period=900s --retries=3 \
    CMD nc -zu localhost 9876 || exit 1

# =============================================================================
# Entrypoint
# =============================================================================
WORKDIR /data
ENTRYPOINT ["/scripts/entrypoint.sh"]
