# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image (Optimized & Independent)
# =============================================================================
# Este Dockerfile usa Debian Sid (Unstable) para obter Box64 dos repositórios
# oficiais, eliminando tempo de compilação sem depender de imagens de terceiros.
#
# Otimizações:
# - Box64: Instalado via apt (debian:sid) -> 0 min build time
# - Box86: Compilado do source (necessário para SteamCMD) -> ~5-8 min
# - Wine: Mantido Kron4ek (única opção viável para WOW64 atual)
# =============================================================================

# -----------------------------------------------------------------------------
# ARGs Globais
# -----------------------------------------------------------------------------
# Usamos 'sid-slim' pois contém box64 nos repositórios oficiais
ARG BUILDER_VERSION=bookworm-slim
ARG RUNTIME_VERSION=sid-slim
ARG BOX86_VERSION=v0.3.6
ARG WINE_VERSION=11.0-rc3

# =============================================================================
# STAGE 1: Compilação do Box86 (32-bit emulator)
# =============================================================================
# Box86 não está disponível em armhf no Sid, então compilamos.
# -----------------------------------------------------------------------------
# Usamos 'bookworm-slim' (Stable) para o builder para maximizar o cache do Docker.
# O cache só será invalidado se a versão do Box86 mudar, não quando o 'sid' atualizar.
FROM debian:${BUILDER_VERSION} AS box86-builder

ARG BOX86_VERSION

# Habilitar multiarch armhf para cross-compilação
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Compilar Box86
RUN cd /tmp && \
    git clone --depth 1 --branch ${BOX86_VERSION} https://github.com/ptitSeb/box86.git && \
    cd box86 && \
    mkdir build && cd build && \
    cmake .. \
    -DARM64=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-D_FILE_OFFSET_BITS=64" \
    -DNOGIT=1 && \
    make -j$(nproc) && \
    make install DESTDIR=/box86-install && \
    rm -rf /tmp/box86

# =============================================================================
# STAGE 2: Download e preparação do Wine
# =============================================================================
FROM debian:${BUILDER_VERSION} AS wine-prep

ARG WINE_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download Wine com WOW64
RUN mkdir -p /wine && \
    cd /tmp && \
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-amd64-wow64.tar.xz" -O wine.tar.xz && \
    tar -xf wine.tar.xz -C /wine --strip-components=1 && \
    rm wine.tar.xz && \
    # Fix dnsapi crash
    rm -f /wine/lib/wine/x86_64-unix/dnsapi.so && \
    rm -f /wine/lib64/wine/x86_64-unix/dnsapi.so

# =============================================================================
# STAGE 3: Imagem de Runtime (FINAL)
# =============================================================================
FROM debian:${RUNTIME_VERSION} AS runtime

LABEL maintainer="VRising ARM64 Server"
LABEL description="V Rising Dedicated Server for ARM64 using Box64 (Debian Sid) + Box86"

# -----------------------------------------------------------------------------
# Variáveis de ambiente
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    SERVER_NAME="V Rising Server" \
    WORLD_NAME="world1" \
    PASSWORD="" \
    MAX_USERS="40" \
    GAME_PORT="9876" \
    QUERY_PORT="9877" \
    LIST_ON_MASTER_SERVER="false" \
    LIST_ON_EOS="false" \
    GAME_MODE_TYPE="PvP" \
    TZ="America/Sao_Paulo" \
    SERVER_DIR="/data/server" \
    SAVES_DIR="/data/saves" \
    VRISING_APP_ID="1829350" \
    WINEPREFIX="/data/wine" \
    WINEARCH="win64" \
    WINEDEBUG="-all" \
    WINEDLLOVERRIDES="mscoree=d;mshtml=d;dnsapi=b" \
    DISPLAY=":0" \
    # Box settings
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1" \
    BOX64_WINE_PRELOADED="1" \
    BOX64_LD_LIBRARY_PATH="/opt/wine/lib/wine/x86_64-unix:/opt/wine/lib" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

# -----------------------------------------------------------------------------
# Instalar Dependências (Box64 do Repo Oficial + Runtime)
# -----------------------------------------------------------------------------
# Debian Sid contém box64 nos repositórios oficiais!
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    # Box64 Oficial
    box64 \
    # Utilitários
    ca-certificates \
    curl \
    wget \
    xz-utils \
    jq \
    tzdata \
    netcat-openbsd \
    procps \
    locales \
    xvfb \
    # Libs para Wine/Games
    libresolv-wrapper \
    libxinerama1 \
    libxrandr2 \
    libxcomposite1 \
    libxi6 \
    libxcursor1 \
    libcups2 \
    libegl1 \
    libfreetype6 \
    libfontconfig1 \
    libxext6 \
    libxrender1 \
    libsm6 \
    libopengl0 \
    libsdl2-2.0-0 \
    # Suporte 32-bit (Box86 needs this)
    libc6:armhf \
    libstdc++6:armhf \
    libncurses6:armhf \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true \
    && locale-gen 2>/dev/null || true

# -----------------------------------------------------------------------------
# Copiar Box86 compilado e Wine
# -----------------------------------------------------------------------------
COPY --from=box86-builder /box86-install/usr/local/bin/box86 /usr/local/bin/box86
COPY --from=wine-prep /wine /opt/wine

# Verificar instalações
RUN box64 --version && echo "Box64 OK"
RUN box86 --version && echo "Box86 OK"

# -----------------------------------------------------------------------------
# Instalar SteamCMD
# -----------------------------------------------------------------------------
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz && \
    rm steamcmd.tar.gz && \
    chmod +x steamcmd.sh

# -----------------------------------------------------------------------------
# Setup Final
# -----------------------------------------------------------------------------
RUN mkdir -p /data/server /data/saves /data/logs /data/wine /scripts

COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY config/ /scripts/config/
RUN chmod +x /scripts/entrypoint.sh

EXPOSE 9876/udp 9877/udp
VOLUME ["/data"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=900s --retries=3 \
    CMD nc -zu localhost 9876 || exit 1

WORKDIR /data
ENTRYPOINT ["/scripts/entrypoint.sh"]
