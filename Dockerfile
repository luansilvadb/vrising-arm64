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

# 4. Baixa RootFS via FEXRootFSFetcher com respostas automáticas
USER vrising
# Respostas: y (baixar), 0 (primeira opção), y (extrair), y (usar como default)
RUN printf 'y\n0\ny\ny\n' | FEXRootFSFetcher && \
    echo "=== RootFS download complete ==="

# 5. Verifica RootFS e lista conteúdo
RUN echo "=== Checking RootFS ==="  && \
    ls -la $HOME/.fex-emu/ && \
    ls -la $HOME/.fex-emu/RootFS/ 2>/dev/null || echo "RootFS folder not found"

# 6. Instala Wine64 dentro do RootFS extraído
RUN echo "=== Installing Wine via FEXBash ==="  && \
    FEXBash -c "apt-get update && apt-get install -y wine64 && rm -rf /var/lib/apt/lists/*" && \
    echo "=== Wine installation complete ==="

# 7. Verifica Wine instalado
RUN echo "=== Verifying Wine ==="  && \
    ls -la $HOME/.fex-emu/RootFS/usr/bin/wine* 2>/dev/null || echo "Wine binaries not found" && \
    FEXBash -c "which wine64" || echo "Wine not in PATH"

# 8. Copia scripts (volta para root temporariamente)
USER root
COPY --chown=vrising:vrising entrypoint.sh /app/
COPY --chown=vrising:vrising wine-wrapper.sh /app/
RUN chmod +x /app/*.sh

WORKDIR /app
USER vrising

EXPOSE 27015/udp 27016/udp

ENTRYPOINT ["/app/entrypoint.sh"]
