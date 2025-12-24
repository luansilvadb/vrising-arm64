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
    # SquashFS extraction (não precisa fuse para extrair!)
    squashfs-tools \
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
    mkdir -p /app /data /steam /home/vrising/.fex-emu && \
    chown -R vrising:vrising /app /data /steam /home/vrising

# 4. Baixa e EXTRAI RootFS Ubuntu 22.04 (evita necessidade de FUSE)
USER root
ENV ROOTFS_DIR="/opt/fex-rootfs"
ENV ROOTFS_URL="https://rootfs.fex-emu.gg/Ubuntu_22_04/2025-01-08/Ubuntu_22_04.sqsh"

RUN echo "=== Downloading FEX RootFS ===" && \
    wget -q --show-progress -O /tmp/rootfs.sqsh "${ROOTFS_URL}" && \
    echo "=== Extracting RootFS (this takes a while) ===" && \
    unsquashfs -d "${ROOTFS_DIR}" /tmp/rootfs.sqsh && \
    rm /tmp/rootfs.sqsh && \
    echo "=== RootFS extracted ===" && \
    ls -la "${ROOTFS_DIR}/usr/bin/" | grep -i wine | head -10

# 5. Cria symlinks:
#    - FEX RootFS no local padrão
#    - Wine dirs no HOST para que Wine encontre wine.inf
RUN ln -sf "${ROOTFS_DIR}" /home/vrising/.fex-emu/RootFS && \
    mkdir -p /root/.fex-emu && \
    ln -sf "${ROOTFS_DIR}" /root/.fex-emu/RootFS && \
    # Symlinks para Wine encontrar seus arquivos no host
    ln -sf "${ROOTFS_DIR}/usr/share/wine" /usr/share/wine && \
    ln -sf "${ROOTFS_DIR}/usr/lib/wine" /usr/lib/wine && \
    ln -sf "${ROOTFS_DIR}/etc/alternatives" /etc/alternatives 2>/dev/null || true && \
    chown -R vrising:vrising /home/vrising/.fex-emu && \
    echo "=== Symlinks created ===" && \
    ls -la /usr/share/wine /usr/lib/wine 2>/dev/null || echo "Wine symlinks check" && \
    ls -la "${ROOTFS_DIR}/usr/share/wine/wine/" | head -5

# 6. Copia scripts
COPY --chown=vrising:vrising entrypoint.sh /app/
COPY --chown=vrising:vrising wine-wrapper.sh /app/
RUN chmod +x /app/*.sh

WORKDIR /app
USER vrising

# Variáveis de ambiente - FEX_ROOTFS é lida pelo FEX
# Usamos path hardcoded para garantir que funcione
ENV FEX_ROOTFS="/opt/fex-rootfs"
ENV HOME="/home/vrising"

EXPOSE 27015/udp 27016/udp

ENTRYPOINT ["/app/entrypoint.sh"]
