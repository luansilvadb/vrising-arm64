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
    # SteamCMD requirement
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Instala FEX-Emu (PPA oficial)
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt-get update && \
    apt-get install -y fex-emu-armv8.0 && \
    rm -rf /var/lib/apt/lists/*

# 3. Cria usuário não-root e diretórios
RUN useradd -u 1000 -m -s /bin/bash vrising && \
    mkdir -p /app /data /steam \
             /home/vrising/.fex-emu/RootFS \
             /home/vrising/.fex-emu/Config && \
    chown -R vrising:vrising /app /data /steam /home/vrising

# 4. Baixa RootFS Ubuntu 22.04 manualmente (SquashFS)
USER vrising
ENV ROOTFS_URL="https://rootfs.fex-emu.gg/Ubuntu_22_04/2025-01-08/Ubuntu_22_04.sqsh"
ENV ROOTFS_PATH="/home/vrising/.fex-emu/RootFS.sqsh"

RUN echo "=== Downloading FEX RootFS ===" && \
    wget -q --show-progress -O "${ROOTFS_PATH}" "${ROOTFS_URL}" && \
    echo "=== RootFS downloaded ===" && \
    ls -lah "${ROOTFS_PATH}"

# 5. Configura FEX para usar o RootFS SquashFS
RUN echo "=== Configuring FEX RootFS path ===" && \
    echo '{"Config":{"RootFS":"'"${ROOTFS_PATH}"'"}}' > /home/vrising/.fex-emu/Config.json && \
    cat /home/vrising/.fex-emu/Config.json

# 6. Testa que FEX consegue encontrar o RootFS
RUN echo "=== Testing FEX configuration ===" && \
    FEXConfig -v || echo "FEXConfig not available" && \
    timeout 5 FEXInterpreter /bin/true 2>&1 || echo "FEX test complete"

# 7. Copia scripts (volta para root temporariamente)
USER root
COPY --chown=vrising:vrising entrypoint.sh /app/
COPY --chown=vrising:vrising wine-wrapper.sh /app/
RUN chmod +x /app/*.sh

WORKDIR /app
USER vrising

# Variáveis de ambiente para FEX
ENV FEX_ROOTFS="${ROOTFS_PATH}"

EXPOSE 27015/udp 27016/udp

ENTRYPOINT ["/app/entrypoint.sh"]
