# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image
# =============================================================================
# Este Dockerfile cria uma imagem ARM64 para rodar o servidor dedicado de 
# V Rising usando Box64/Box86 + Wine para emulação x86/x64.
#
# Testado em: Oracle Cloud ARM64 (Ampere A1) com Ubuntu 20.04
# =============================================================================

FROM arm64v8/debian:bullseye-slim

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
    # Box settings
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1"

# =============================================================================
# Instalação de dependências base e multiarch
# =============================================================================
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    # Utilitários básicos
    ca-certificates \
    curl \
    wget \
    gnupg2 \
    xz-utils \
    # Build tools para Box86/Box64
    cmake \
    git \
    build-essential \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    python3 \
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
    # Locale
    locales \
    # Bibliotecas armhf necessárias
    libc6:armhf \
    libstdc++6:armhf \
    libncurses6:armhf \
    libtinfo6:armhf \
    zlib1g:armhf \
    libsdl2-2.0-0:armhf \
    libatomic1:armhf \
    && rm -rf /var/lib/apt/lists/* \
    # Configurar locale
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# =============================================================================
# Compilar e instalar Box86 (para SteamCMD x86)
# =============================================================================
RUN cd /tmp && \
    git clone --depth 1 https://github.com/ptitSeb/box86.git && \
    cd box86 && \
    mkdir build && cd build && \
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/box86

# =============================================================================
# Compilar e instalar Box64 (para Wine x64)
# =============================================================================
RUN cd /tmp && \
    git clone --depth 1 https://github.com/ptitSeb/box64.git && \
    cd box64 && \
    mkdir build && cd build && \
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/box64

# =============================================================================
# Registrar Box86/Box64 com binfmt
# =============================================================================
RUN echo ':BOX64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/local/bin/box64:' > /usr/share/binfmts/box64 || true && \
    echo ':BOX86:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/local/bin/box86:' > /usr/share/binfmts/box86 || true

# =============================================================================
# Instalar Wine x64 (via Box64)
# =============================================================================
RUN mkdir -p /opt/wine && \
    cd /tmp && \
    # Baixar Wine x86_64 versão 8.0.2 (estável com Box64)
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/8.0.2/wine-8.0.2-amd64.tar.xz" -O wine.tar.xz && \
    tar -xf wine.tar.xz -C /opt/wine --strip-components=1 && \
    rm wine.tar.xz && \
    # Criar symlinks
    ln -sf /opt/wine/bin/wine64 /usr/local/bin/wine64 && \
    ln -sf /opt/wine/bin/wine /usr/local/bin/wine && \
    ln -sf /opt/wine/bin/wineboot /usr/local/bin/wineboot && \
    ln -sf /opt/wine/bin/wineserver /usr/local/bin/wineserver && \
    ln -sf /opt/wine/bin/winecfg /usr/local/bin/winecfg

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
