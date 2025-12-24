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

# 3. Cria usuário não-root (antes de baixar RootFS)
RUN useradd -u 1000 -m -s /bin/bash vrising && \
    mkdir -p /app /data /steam /opt/fex-rootfs && \
    chown -R vrising:vrising /app /data /steam /opt/fex-rootfs

# 4. Baixa RootFS x86_64 usando FEXRootFSFetcher (como usuário vrising)
USER vrising
RUN mkdir -p /home/vrising/.fex-emu && \
    FEXRootFSFetcher --distro ubuntu --version 22.04 -x /opt/fex-rootfs

# 5. Configura FEX para usuário vrising
COPY --chown=vrising:vrising <<EOF /home/vrising/.fex-emu/Config.json
{
  "RootFS": "/opt/fex-rootfs",
  "ThunkHostLibs": "/usr/lib/aarch64-linux-gnu",
  "MaxJITBlockSize": 65536,
  "Multiblock": "2"
}
EOF

# 6. Copia scripts (volta para root temporariamente)
USER root
COPY --chown=vrising:vrising entrypoint.sh /app/
COPY --chown=vrising:vrising wine-wrapper.sh /app/
RUN chmod +x /app/*.sh

WORKDIR /app
USER vrising

EXPOSE 27015/udp 27016/udp

ENTRYPOINT ["/app/entrypoint.sh"]
