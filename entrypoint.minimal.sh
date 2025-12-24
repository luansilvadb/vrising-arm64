#!/bin/bash
set -e

echo "==========================================="
echo " VRising ARM64 - MÍNIMO"
echo " $(date)"
echo "==========================================="

STEAM_DIR="/steam"
DATA_DIR="/data"
APP_ID=1829350

# Cleanup
cleanup() {
    [ -n "$XVFB_PID" ] && kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT

# 1. Xvfb
echo "[1/3] Iniciando Xvfb..."
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &>/dev/null &
XVFB_PID=$!
sleep 1

# 2. Wine prefix
export WINEPREFIX="$DATA_DIR/wine-prefix"
export WINEARCH=win64
export WINEDEBUG=-all
export WINEDLLOVERRIDES="crypt32=n;winemenubuilder.exe=d"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "[2/3] Criando Wine prefix..."
    /app/wine-wrapper.sh wineboot --init
fi

# 3. Download via SteamCMD (Windows)
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "[3/3] Baixando VRising..."
    
    # Baixa SteamCMD Windows
    if [ ! -f "$STEAM_DIR/steamcmd/steamcmd.exe" ]; then
        mkdir -p "$STEAM_DIR/steamcmd"
        curl -sL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -o /tmp/steamcmd.zip
        cd "$STEAM_DIR/steamcmd"
        unzip -q /tmp/steamcmd.zip
        rm /tmp/steamcmd.zip
        cd /app
    fi
    
    # Executa via Wine
    /app/wine-wrapper.sh "$STEAM_DIR/steamcmd/steamcmd.exe" \
        -overrideminos \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$STEAM_DIR" \
        +login anonymous \
        +app_update $APP_ID validate \
        +quit || echo "SteamCMD exit code: $?"
fi

# Verifica
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "ERRO: VRisingServer.exe não encontrado!"
    echo "Tentando listar conteúdo de $STEAM_DIR:"
    ls -la "$STEAM_DIR"
    exit 1
fi

echo "[✓] Servidor encontrado!"
echo ""
echo "Iniciando VRising Server..."

# Inicia
exec /app/wine-wrapper.sh "$STEAM_DIR/VRisingServer.exe" \
    -persistentDataPath "$DATA_DIR" \
    -serverName "${VR_SERVER_NAME:-VRising-ARM64}" \
    -saveName "${VR_SAVE_NAME:-world1}" \
    -gamePort "${VR_GAME_PORT:-27015}" \
    -queryPort "${VR_QUERY_PORT:-27016}" \
    -logFile "$DATA_DIR/Server.log"
