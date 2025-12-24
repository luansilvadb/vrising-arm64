#!/bin/bash
set -e

echo "=========================================="
echo " VRising ARM64 MVP - FEX-Emu"
echo " $(date)"
echo "=========================================="

STEAM_DIR="/steam"
DATA_DIR="/data"
APP_ID=1829350

# Cleanup on exit
cleanup() {
    echo "Shutting down..."
    if [ -n "$XVFB_PID" ]; then
        kill "$XVFB_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Step 0: Start Xvfb virtual display (single instance)
echo "[0/4] Iniciando display virtual Xvfb..."
export DISPLAY=:99
if ! pgrep -f "Xvfb :99" > /dev/null; then
    Xvfb :99 -screen 0 1024x768x16 &>/dev/null &
    XVFB_PID=$!
    sleep 2
    echo "Xvfb iniciado (PID: $XVFB_PID)"
else
    echo "Xvfb já está rodando"
fi

# Step 1: Inicializa Wine prefix (se não existe)
export WINEPREFIX="$DATA_DIR/wine-prefix"
export WINEARCH=win64
export WINEDEBUG=-all
# Desabilita crypt32 para evitar falhas de certificado SSL (necessário para SteamCMD)
export WINEDLLOVERRIDES="crypt32=n;winemenubuilder.exe=d;mscoree=d;mshtml=d"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "[1/4] Inicializando Wine prefix..."
    /app/wine-wrapper.sh wineboot --init
    
    # Configura Wine para emular Windows 10 (fix para SteamCMD)
    echo "Configurando Wine como Windows 10..."
    /app/wine-wrapper.sh reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CurrentVersion /t REG_SZ /d "10.0" /f
    /app/wine-wrapper.sh reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CurrentBuildNumber /t REG_SZ /d "19041" /f
    /app/wine-wrapper.sh reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v ProductName /t REG_SZ /d "Windows 10 Pro" /f
    /app/wine-wrapper.sh reg add "HKCU\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    
    echo "Wine prefix criado e configurado para Windows 10."
else
    echo "[1/4] Wine prefix já existe, pulando inicialização."
fi

# Step 2: Atualiza/instala VRising via SteamCMD
if [ ! -f "$STEAM_DIR/VRisingServer.exe" ] || [ "${FORCE_UPDATE:-false}" == "true" ]; then
    echo "[2/4] Baixando VRising Server via SteamCMD..."
    
    # Baixa SteamCMD Windows se necessário
    if [ ! -f "$STEAM_DIR/steamcmd/steamcmd.exe" ]; then
        mkdir -p "$STEAM_DIR/steamcmd"
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -o /tmp/steamcmd.zip
        unzip -q /tmp/steamcmd.zip -d "$STEAM_DIR/steamcmd"
        rm /tmp/steamcmd.zip
    fi
    
    # Executa SteamCMD via Wine+FEX
    # -overrideminos: ignora verificação de versão do OS (necessário para Wine)
    /app/wine-wrapper.sh "$STEAM_DIR/steamcmd/steamcmd.exe" \
        -overrideminos \
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
