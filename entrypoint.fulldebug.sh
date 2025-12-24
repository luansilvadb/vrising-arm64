#!/bin/bash
set -e

echo "==========================================="
echo " VRising ARM64 - FULL DEBUG"
echo " $(date)"
echo "==========================================="

STEAM_DIR="/steam"
DATA_DIR="/data"
APP_ID=1829350

cleanup() {
    echo "=== Cleanup triggered ==="
    [ -n "$XVFB_PID" ] && kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT

# 1. Xvfb
echo "[1/5] Iniciando Xvfb..."
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &>/dev/null &
XVFB_PID=$!
sleep 1

# 2. Download via SteamCMD
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "[2/5] Baixando VRising via SteamCMD Linux..."
    cd /steamcmd
    FEXBash -c "./steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir '$STEAM_DIR' \
        +login anonymous \
        +app_update $APP_ID validate \
        +quit"
    echo "Download completo!"
else
    echo "[2/5] VRising já instalado."
fi

# 3. Verifica
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ]; then
    echo "ERRO: VRisingServer.exe não encontrado!"
    ls -la "$STEAM_DIR"
    exit 1
fi
echo "[3/5] VRisingServer.exe OK!"

# 4. Copia configs se existirem
echo "[4/5] Configurando Settings..."
mkdir -p "$DATA_DIR/Settings"

# Copia configs se houver no /app
if [ -f "/app/ServerHostSettings.json" ]; then
    cp /app/ServerHostSettings.json "$DATA_DIR/Settings/"
    echo "  ServerHostSettings.json copiado"
fi
if [ -f "/app/ServerGameSettings.json" ]; then
    cp /app/ServerGameSettings.json "$DATA_DIR/Settings/"
    echo "  ServerGameSettings.json copiado"
fi

# Mostra configs atuais
echo "  Configs em $DATA_DIR/Settings:"
ls -la "$DATA_DIR/Settings/" 2>/dev/null || echo "  (vazio)"

# 5. Wine prefix
export WINEPREFIX="$DATA_DIR/wine-prefix"
export WINEARCH=win64
export WINEDEBUG=warn+all

if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "[5/5] Criando Wine prefix..."
    /app/wine-wrapper.sh wineboot --init
else
    echo "[5/5] Wine prefix OK!"
fi

echo ""
echo "==========================================="
echo "DEBUG: Configurações do servidor"
echo "==========================================="
echo "STEAM_DIR: $STEAM_DIR"
echo "DATA_DIR: $DATA_DIR"
echo "WINEPREFIX: $WINEPREFIX"
echo "DISPLAY: $DISPLAY"
echo ""
echo "Arquivos do servidor:"
ls -la "$STEAM_DIR"/*.exe 2>/dev/null | head -5
echo ""
echo "Settings:"
cat "$DATA_DIR/Settings/ServerHostSettings.json" 2>/dev/null | head -10 || echo "(não encontrado)"
echo ""

echo "==========================================="
echo "Iniciando VRising Server..."
echo "  -persistentDataPath $DATA_DIR"
echo "  -logFile $DATA_DIR/Server.log"
echo "==========================================="
echo ""

# Executa servidor - MINIMAL flags primeiro
# VRising espera -persistentDataPath e lê configs de Settings/
exec /app/wine-wrapper.sh "$STEAM_DIR/VRisingServer.exe" \
    -persistentDataPath "$DATA_DIR" \
    -logFile "$DATA_DIR/Server.log" \
    2>&1 | tee -a "$DATA_DIR/console.log"
