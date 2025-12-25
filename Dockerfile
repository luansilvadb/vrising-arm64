# =============================================================================
# V Rising Dedicated Server - ARM64 Docker Image (NTSync Edition)
# =============================================================================
# Este Dockerfile cria uma imagem ARM64 para rodar o servidor dedicado de 
# V Rising usando Box64 + Wine Staging-TKG WOW64 com suporte opcional a NTSync.
#
# Features:
# - Wine Staging-TKG: Melhor performance que Wine vanilla
# - NTSync: +50-100% FPS quando disponível (kernel 6.14+)
# - Configuração de emuladores via emulators.rc
# - winetricks para configuração de audio
#
# Requisitos para NTSync (opcional):
# - Host com kernel Linux 6.14+
# - Módulo ntsync carregado (modprobe ntsync)
# - Device /dev/ntsync mapeado no docker-compose.yml
#
# Testado em: Oracle Cloud ARM64 (Ampere A1) com Ubuntu 25.04
# =============================================================================

# -----------------------------------------------------------------------------
# OPÇÃO 1: Ubuntu 25.04 (Plucky) - RECOMENDADO para NTSync
# Ubuntu 25.04 vem com kernel 6.14+ que tem NTSync built-in
# -----------------------------------------------------------------------------
FROM ubuntu:25.04

# -----------------------------------------------------------------------------
# OPÇÃO 2: Debian 11 (se NTSync não for prioridade)
# Descomente esta linha e comente a linha acima para usar Debian
# NOTE: NTSync NÃO funcionará com Debian 11 (kernel muito antigo)
# -----------------------------------------------------------------------------
# FROM weilbyte/box:debian-11

LABEL maintainer="VRising ARM64 Server"
LABEL description="V Rising Dedicated Server for ARM64 using Box64/Wine with NTSync support"

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
    # Forçar dnsapi builtin para evitar __res_query crash
    WINEDLLOVERRIDES="mscoree=d;mshtml=d;dnsapi=b" \
    # Display virtual
    DISPLAY=":0" \
    # Box settings - habilitar WOW64
    BOX86_LOG="0" \
    BOX64_LOG="0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1" \
    BOX64_WINE_PRELOADED="1" \
    BOX64_LD_LIBRARY_PATH="/opt/wine/lib/wine/x86_64-unix:/opt/wine/lib" \
    # Locale
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# =============================================================================
# Instalação de dependências
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
    # Build tools para compilar Box64/Box86
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
    # winetricks e dependências
    cabextract \
    unzip \
    zenity \
    # NTSync userspace tools (para verificação)
    lsof \
    kmod \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true \
    && locale-gen 2>/dev/null || true

# =============================================================================
# Instalar Box86 v0.3.8 (para SteamCMD 32-bit)
# =============================================================================
RUN cd /tmp && \
    git clone --depth 1 --branch v0.3.8 https://github.com/ptitSeb/box86.git && \
    cd box86 && \
    mkdir build && cd build && \
    # Usar target genérico para ARM64 rodando binários 32-bit
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/box86 && \
    # Verificar instalação (ignorar erro se binário não for executável no host)
    box86 --version 2>/dev/null || echo "Box86 instalado (verificação skipped)"

# =============================================================================
# Instalar Box64 v0.3.8 (para Wine 64-bit)
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
# Instalar Wine staging-tkg com NTSync + WOW64
# =============================================================================
# Usamos Wine staging-tkg que inclui:
# - Patches de staging para melhor compatibilidade
# - Patches TkG para performance
# - Suporte a NTSync (quando disponível no kernel)
# - WOW64 para rodar apps 32-bit sem multilib
# =============================================================================
RUN mkdir -p /opt/wine && \
    cd /tmp && \
    # Wine 11.0-rc3 staging-tkg com WOW64
    # NOTA: O build 'staging-tkg' inclui NTSync quando o kernel suporta
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/11.0-rc3/wine-11.0-rc3-staging-tkg-amd64-wow64.tar.xz" -O wine.tar.xz && \
    tar -xf wine.tar.xz -C /opt/wine --strip-components=1 && \
    rm wine.tar.xz && \
    # CRITICAL FIX: Remove dnsapi.so to avoid __res_query symbol error
    # Isso força Wine a usar DNS handling builtin (sem libresolv)
    rm -f /opt/wine/lib/wine/x86_64-unix/dnsapi.so && \
    rm -f /opt/wine/lib64/wine/x86_64-unix/dnsapi.so && \
    # Verificar arquivos
    ls -la /opt/wine/bin/

# =============================================================================
# Instalar winetricks (para configuração adicional do Wine)
# =============================================================================
RUN cd /tmp && \
    wget -q "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" && \
    chmod +x winetricks && \
    mv winetricks /usr/local/bin/ && \
    winetricks --version || echo "winetricks instalado"

# =============================================================================
# Instalar SteamCMD (versão Linux x86) + pré-inicializar
# =============================================================================
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz && \
    rm steamcmd.tar.gz && \
    chmod +x steamcmd.sh && \
    # Criar script wrapper para SteamCMD
    echo '#!/bin/bash' > /usr/local/bin/steamcmd.sh && \
    echo 'exec box86 /opt/steamcmd/linux32/steamcmd "$@"' >> /usr/local/bin/steamcmd.sh && \
    chmod +x /usr/local/bin/steamcmd.sh && \
    # Pré-inicializar SteamCMD para que ele se atualize durante o build
    echo "Pré-inicializando SteamCMD (isso pode demorar)..." && \
    for i in 1 2 3; do \
    box86 /opt/steamcmd/linux32/steamcmd +quit 2>/dev/null || true; \
    sleep 2; \
    done && \
    echo "SteamCMD pré-inicializado!"

# =============================================================================
# Criar diretórios necessários
# =============================================================================
RUN mkdir -p /data/server /data/saves /data/logs /data/wine /scripts

# =============================================================================
# Copiar scripts e configurações
# =============================================================================
COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/load_emulators_env.sh /scripts/load_emulators_env.sh
COPY config/ /scripts/config/
RUN chmod +x /scripts/entrypoint.sh /scripts/load_emulators_env.sh

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
