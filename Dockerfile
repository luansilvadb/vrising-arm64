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
    SERVER_DESCRIPTION="Servidor dedicado brasileiro" \
    WORLD_NAME="world1" \
    PASSWORD="" \
    MAX_USERS="40" \
    MAX_ADMINS="5" \
    SERVER_FPS="60" \
    GAME_DIFFICULTY_PRESET="Difficulty_Brutal" \
    GAME_PORT="9876" \
    QUERY_PORT="9877" \
    # Lista de servidores públicos
    LIST_ON_MASTER_SERVER="false" \
    LIST_ON_EOS="false" \
    # Auto Save
    AUTO_SAVE_COUNT="25" \
    AUTO_SAVE_INTERVAL="120" \
    COMPRESS_SAVE_FILES="true" \
    # RCON
    RCON_ENABLED="true" \
    RCON_PORT="25575" \
    RCON_PASSWORD="" \
    # Atualização automática
    AUTO_UPDATE="true" \
    # BepInEx (Suporte a Mods)
    BEPINEX_ENABLED="false" \
    BEPINEX_VERSION="1.733.2" \
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
    # Forçar dnsapi builtin para evitar __res_query crash
    # winhttp=n,b é necessário para BepInEx funcionar
    WINEDLLOVERRIDES="winhttp=n,b;mscoree=d;mshtml=d;dnsapi=b" \
    # Display virtual
    DISPLAY=":0" \
    # Box settings - habilitar WOW64
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1" \
    BOX64_WINE_PRELOADED="1" \
    BOX64_LD_LIBRARY_PATH="/opt/wine/lib/wine/x86_64-unix:/opt/wine/lib" \
    # Otimizações Box64 para BepInEx (melhora estabilidade com Il2CppInterop)
    BOX64_DYNAREC_STRONGMEM="2" \
    BOX64_DYNAREC_WAIT="1"

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
    # Bibliotecas para resolver __res_query symbol
    libresolv-wrapper \
    libc6-dev \
    # Build tools para compilar Box64 v0.3.8+
    git \
    cmake \
    build-essential \
    python3 \
    # Bibliotecas X11 que Wine precisa
    libxinerama1 \
    libxrandr2 \
    libxcomposite1 \
    libxi6 \
    libxcursor1 \
    libcups2 \
    libegl1 \
    # Bibliotecas adicionais para Wine
    libfreetype6 \
    libfontconfig1 \
    libxext6 \
    libxrender1 \
    libsm6 \
    # Utilitários para BepInEx
    unzip \
    nano \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true \
    && locale-gen 2>/dev/null || true

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# =============================================================================
# Atualizar Box64 para v0.3.8 (tem wrapping de __res_query)
# =============================================================================
RUN cd /tmp && \
    git clone --depth 1 --branch v0.3.8 https://github.com/ptitSeb/box64.git && \
    cd box64 && \
    mkdir build && cd build && \
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/box64 && \
    # Verificar versão instalada
    box64 --version

# =============================================================================
# Instalar Wine 9.x com WOW64 (versão que funciona melhor com Box64)
# =============================================================================
RUN mkdir -p /opt/wine && \
    cd /tmp && \
    # Usar Wine 11.0-rc3 com WOW64
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/11.0-rc3/wine-11.0-rc3-amd64-wow64.tar.xz" -O wine.tar.xz && \
    tar -xf wine.tar.xz -C /opt/wine --strip-components=1 && \
    rm wine.tar.xz && \
    # CRITICAL FIX: Remove dnsapi.so to avoid __res_query symbol error
    # This forces Wine to use builtin DNS handling (no libresolv needed)
    rm -f /opt/wine/lib/wine/x86_64-unix/dnsapi.so && \
    rm -f /opt/wine/lib64/wine/x86_64-unix/dnsapi.so && \
    # Verificar arquivos
    ls -la /opt/wine/bin/

# =============================================================================
# Instalar SteamCMD (versão Linux x86) + pré-inicializar
# =============================================================================
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz && \
    rm steamcmd.tar.gz && \
    chmod +x steamcmd.sh && \
    # Pré-inicializar SteamCMD para que ele se atualize durante o build
    # Isso evita os "warmup runs" durante a inicialização do container
    echo "Pré-inicializando SteamCMD (isso pode demorar)..." && \
    for i in 1 2 3; do \
    box86 /opt/steamcmd/linux32/steamcmd +quit || true; \
    sleep 2; \
    done && \
    echo "SteamCMD pré-inicializado!"

# =============================================================================
# Baixar BepInExPack para suporte a mods
# =============================================================================
RUN mkdir -p /opt/bepinex && \
    cd /opt/bepinex && \
    wget -q "https://thunderstore.io/package/download/BepInEx/BepInExPack_V_Rising/1.733.2/" \
    -O bepinex.zip && \
    unzip -q bepinex.zip && \
    rm bepinex.zip && \
    echo "BepInExPack V Rising instalado em /opt/bepinex"

# =============================================================================
# Criar diretórios necessários
# =============================================================================
RUN mkdir -p /data/server /data/saves /data/logs /data/wine /data/mods /scripts

# =============================================================================
# Copiar scripts e configurações
# =============================================================================
COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY config/ /scripts/config/
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
