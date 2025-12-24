# syntax=docker/dockerfile:1.4
# =====================================================
# MVP: VRising ARM64 com FEX-Emu (single-stage runtime)
# =====================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Dependências base + FEX-Emu pré-compilado
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg software-properties-common \
    # FEX dependencies
    libtalloc2 libglfw3 libvulkan1 libwayland-client0 \
    libxkbcommon0 libxcb1 libx11-6 xvfb \
    # SquashFS mount support
    squashfuse fuse3 \
    # Network tools
    netcat-openbsd socat procps \
    # For automating interactive prompts
    expect \
    # SteamCMD requirement
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Instala FEX-Emu (PPA oficial)
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt-get update && \
    apt-get install -y fex-emu-armv8.0 && \
    rm -rf /var/lib/apt/lists/*

# 3. Cria usuário não-root
RUN useradd -u 1000 -m -s /bin/bash vrising && \
    mkdir -p /app /data /steam /home/vrising/.fex-emu && \
    chown -R vrising:vrising /app /data /steam /home/vrising/.fex-emu

# 4. Baixa RootFS via FEXRootFSFetcher usando expect para automação
USER vrising
RUN expect -c ' \
    set timeout 1800; \
    spawn FEXRootFSFetcher; \
    expect "Enter selection:" { send "1\r" }; \
    expect "Would you like to extract" { send "n\r" }; \
    expect "Extract as default" { send "n\r" }; \
    expect "Set as default" { send "y\r" }; \
    expect eof \
    ' || echo "Warning: FEXRootFSFetcher may have issues, continuing..."

# 5. Copia scripts (volta para root temporariamente)
USER root
COPY --chown=vrising:vrising entrypoint.sh /app/
COPY --chown=vrising:vrising wine-wrapper.sh /app/
RUN chmod +x /app/*.sh

WORKDIR /app
USER vrising

EXPOSE 27015/udp 27016/udp

ENTRYPOINT ["/app/entrypoint.sh"]
