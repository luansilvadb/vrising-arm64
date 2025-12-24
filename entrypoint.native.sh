#!/bin/bash
set -e

echo "==========================================="
echo " VRising ARM64 - SteamCMD NATIVO"
echo " $(date)"
echo "==========================================="

STEAM_DIR="/steam"
DATA_DIR="/data"
APP_ID=1829350

cleanup() {
    [ -n "$XVFB_PID" ] && kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT

# 1. Xvfb
echo "[1/4] Iniciando Xvfb..."
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &>/dev/null &
XVFB_PID=$!
sleep 1

# 2. Download via SteamCMD LINUX (via FEX, SEM Wine!)
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "[2/4] Baixando VRising via SteamCMD Linux..."
    
    # Executa SteamCMD Linux 32-bit via FEX
    cd /steamcmd
    FEXBash -c "./steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir '$STEAM_DIR' \
        +login anonymous \
        +app_update $APP_ID validate \
        +quit"
    
    echo "Download completo!"
else
    echo "[2/4] VRising já instalado."
fi

# 3. Verifica
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "ERRO: VRisingServer.exe não encontrado!"
    ls -la "$STEAM_DIR"
    exit 1
fi
echo "[3/4] VRisingServer.exe OK!"

# 4. Wine prefix (só para EXECUTAR o servidor)
export WINEPREFIX="$DATA_DIR/wine-prefix"
export WINEARCH=win64
export WINEDEBUG=-all

if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "[4/4] Criando Wine prefix..."
    /app/wine-wrapper.sh wineboot --init
else
    echo "[4/4] Wine prefix OK!"
fi

echo ""
echo "Iniciando VRising Server..."
echo "  Porta:  ${VR_GAME_PORT:-27015}/UDP"
echo "  Nome:   ${VR_SERVER_NAME:-VRising-ARM64}"
echo ""

# Executa servidor via Wine
exec /app/wine-wrapper.sh "$STEAM_DIR/VRisingServer.exe" \
    -persistentDataPath "$DATA_DIR" \
    -serverName "${VR_SERVER_NAME:-VRising-ARM64}" \
    -saveName "${VR_SAVE_NAME:-world1}" \
    -gamePort "${VR_GAME_PORT:-27015}" \
    -queryPort "${VR_QUERY_PORT:-27016}" \
    -logFile "$DATA_DIR/Server.log"
