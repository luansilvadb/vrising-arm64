# Blueprint MVP: VRising Server ARM64 + FEX-Emu

> **Objetivo único:** Servidor funcionando na Oracle Cloud ARM64.  
> **Filosofia:** Mínimo viável primeiro, otimizações depois.

---

## Arquitetura Mínima

```
┌─────────────────────────────────────────────────────┐
│                 Oracle Cloud ARM64                   │
│                (4 cores, 24GB RAM)                   │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │           Docker Container (único)           │    │
│  │                                              │    │
│  │   FEX-Emu → Wine → VRisingServer.exe        │    │
│  │                                              │    │
│  │   /data     → saves, configs                │    │
│  │   /steam    → server files                  │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  Portas: UDP 27015, 27016                           │
└─────────────────────────────────────────────────────┘
```

---

## Arquivo 1: `Dockerfile`

```dockerfile
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
    && rm -rf /var/lib/apt/lists/*

# 2. Instala FEX-Emu (PPA oficial - mais simples que compilar)
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt-get update && \
    apt-get install -y fex-emu-armv8.0 && \
    rm -rf /var/lib/apt/lists/*

# 3. Baixa RootFS x86_64 pré-montado (2.5GB)
RUN mkdir -p /opt/fex-rootfs && \
    curl -L https://www.dropbox.com/scl/fi/16mhn3jrwvzapdw20o3jj/Ubuntu_22_04.tar.gz?rlkey=CHANGEME \
    -o /tmp/rootfs.tar.gz && \
    tar -xzf /tmp/rootfs.tar.gz -C /opt/fex-rootfs && \
    rm /tmp/rootfs.tar.gz

# Alternativa: usar FEXRootFSFetcher (se dropbox não funcionar)
# RUN FEXRootFSFetcher --distro ubuntu --version 22.04

# 4. Configura FEX
RUN mkdir -p /root/.fex-emu
COPY <<EOF /root/.fex-emu/Config.json
{
  "RootFS": "/opt/fex-rootfs",
  "ThunkHostLibs": "/usr/lib/aarch64-linux-gnu",
  "MaxJITBlockSize": 65536,
  "Multiblock": "2"
}
EOF

# 5. Cria usuário não-root
RUN useradd -u 1000 -m -s /bin/bash vrising && \
    mkdir -p /app /data /steam && \
    chown -R vrising:vrising /app /data /steam /root/.fex-emu

# 6. Copia scripts
COPY --chown=vrising:vrising entrypoint.sh /app/
COPY --chown=vrising:vrising wine-wrapper.sh /app/
RUN chmod +x /app/*.sh

WORKDIR /app
USER vrising

EXPOSE 27015/udp 27016/udp

ENTRYPOINT ["/app/entrypoint.sh"]
```

---

## Arquivo 2: `entrypoint.sh`

```bash
#!/bin/bash
set -e

echo "=========================================="
echo " VRising ARM64 MVP - FEX-Emu"
echo " $(date)"
echo "=========================================="

STEAM_DIR="/steam"
DATA_DIR="/data"
APP_ID=1829350

# Step 1: Inicializa Wine prefix (se não existe)
export WINEPREFIX="$DATA_DIR/wine-prefix"
export WINEARCH=win64
export WINEDEBUG=-all

if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "[1/4] Inicializando Wine prefix..."
    /app/wine-wrapper.sh wineboot --init
    echo "Wine prefix criado."
fi

# Step 2: Atualiza/instala VRising via SteamCMD
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ] || [ "${FORCE_UPDATE:-false}" == "true" ]; then
    echo "[2/4] Baixando VRising Server via SteamCMD..."
    
    # Baixa SteamCMD se necessário
    if [ ! -f "$STEAM_DIR/steamcmd/steamcmd.exe" ]; then
        mkdir -p "$STEAM_DIR/steamcmd"
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -o /tmp/steamcmd.zip
        unzip -q /tmp/steamcmd.zip -d "$STEAM_DIR/steamcmd"
        rm /tmp/steamcmd.zip
    fi
    
    # Executa SteamCMD via Wine+FEX
    /app/wine-wrapper.sh "$STEAM_DIR/steamcmd/steamcmd.exe" \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$STEAM_DIR" \
        +login anonymous \
        +app_update $APP_ID validate \
        +quit
    
    echo "Download completo."
else
    echo "[2/4] VRising já instalado, pulando download."
fi

# Step 3: Valida instalação
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "ERRO: VRisingServer.exe não encontrado!"
    exit 1
fi
echo "[3/4] VRisingServer.exe encontrado ✓"

# Step 4: Inicia servidor
echo "[4/4] Iniciando VRising Server..."
echo "  Porta Game:  ${VR_GAME_PORT:-27015}/UDP"
echo "  Porta Query: ${VR_QUERY_PORT:-27016}/UDP"
echo "  Nome:        ${VR_SERVER_NAME:-VRising-ARM64}"
echo ""

exec /app/wine-wrapper.sh "$STEAM_DIR/VRisingServer.exe" \
    -persistentDataPath "$DATA_DIR" \
    -serverName "${VR_SERVER_NAME:-VRising-ARM64}" \
    -saveName "${VR_SAVE_NAME:-world1}" \
    -gamePort "${VR_GAME_PORT:-27015}" \
    -queryPort "${VR_QUERY_PORT:-27016}" \
    -logFile "$DATA_DIR/Server.log"
```

---

## Arquivo 3: `wine-wrapper.sh`

```bash
#!/bin/bash
# Wrapper que executa comandos via FEX-Emu + Wine

# Diretórios
export WINEPREFIX="${WINEPREFIX:-/data/wine-prefix}"
export WINEARCH=win64
export WINEDEBUG=-all

# Desabilita componentes gráficos desnecessários
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"

# Display virtual (headless)
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &>/dev/null &

# Executa via FEX-Emu
exec FEXInterpreter /opt/fex-rootfs/usr/bin/wine64 "$@"
```

---

## Arquivo 4: `docker-compose.yml`

```yaml
version: '3.8'

services:
  vrising:
    build: .
    container_name: vrising-arm64
    restart: unless-stopped
    
    # Recursos - ajuste conforme sua VM
    deploy:
      resources:
        limits:
          cpus: '3.5'
          memory: 20G
        reservations:
          memory: 16G
    
    # Portas UDP
    ports:
      - "27015:27015/udp"
      - "27016:27016/udp"
    
    # Volumes persistentes
    volumes:
      - vrising-data:/data
      - vrising-steam:/steam
    
    # Configuração do servidor
    environment:
      - VR_SERVER_NAME=VRising-FEX-ARM64
      - VR_SAVE_NAME=world1
      - VR_GAME_PORT=27015
      - VR_QUERY_PORT=27016
      - FORCE_UPDATE=false
    
    # Healthcheck básico
    healthcheck:
      test: ["CMD", "pgrep", "-f", "VRisingServer"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 300s

volumes:
  vrising-data:
  vrising-steam:
```

---

## Deploy: 3 Comandos

```bash
# 1. Setup inicial no host Oracle Cloud
sudo sysctl -w vm.max_map_count=1048576
sudo sysctl -w vm.overcommit_memory=1

# 2. Build e inicia
docker-compose build --no-cache

# 3. Roda servidor
docker-compose up -d && docker-compose logs -f
```

---

## Troubleshooting Rápido

| Problema | Causa Provável | Solução |
|----------|----------------|---------|
| `FEXInterpreter: command not found` | PPA não instalou | `apt install fex-emu-armv8.0` |
| `wine64: not found` | RootFS incompleto | Redownload RootFS ou use `FEXRootFSFetcher` |
| `VRisingServer.exe crash` | AVX instruction | Patch `lib_burst_generated.dll` ou use flag `--no-avx` |
| Porta não abre | Firewall OCI | Security List → adicionar regra UDP 27015-27016 |
| Performance ruim | JIT ainda warmup | Espera 5-10min, FEX cacheia instruções |

---
