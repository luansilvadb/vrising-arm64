#!/bin/bash
set -e

# Configuration
export WINEPREFIX=/data/wine-prefix
export STEAM_CMD_DIR=/data/steamcmd
export SERVER_DIR=/data/server
export SAVE_DIR=/data/saves
export DISPLAY=:0

# FEX/Wine environment
export WINEDEBUG=-all
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export FEX_JITBLOCKS=65536
export FEX_MULTIBLOCK=2
export FEX_FASTREP=1
export FEX_AOTIRCAPTURE=/data/fex-jit

# FEX Interpreter Path
FEX_BIN="/opt/fex/bin/FEXInterpreter"
WINE_BIN="/opt/fex-rootfs/usr/bin/wine"
WINE64_BIN="/opt/fex-rootfs/usr/bin/wine64"

# Ensure directories exist
mkdir -p "$WINEPREFIX" "$STEAM_CMD_DIR" "$SERVER_DIR" "$SAVE_DIR"

# 0. Start Xvfb (ARM64 native)
echo ">>> Starting Xvfb..."
Xvfb :0 -screen 0 1024x768x24 &
sleep 2

# 1. Initialize Wine Prefix
if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo ">>> Initializing Wine Prefix..."
    # We must run wineboot to create the prefix
    $FEX_BIN $WINE_BIN wineboot -u
fi

# 2. Install/Update SteamCMD (Windows Version)
if [ ! -f "$STEAM_CMD_DIR/steamcmd.exe" ]; then
    echo ">>> Downloading SteamCMD (Windows)..."
    curl -s -L "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -o /tmp/steamcmd.zip
    unzip -o /tmp/steamcmd.zip -d "$STEAM_CMD_DIR"
    rm /tmp/steamcmd.zip
fi

# 3. Update/Install VRising
echo ">>> Updating V Rising Dedicated Server..."
$FEX_BIN $WINE64_BIN "$STEAM_CMD_DIR/steamcmd.exe" \
    +force_install_dir "Z:\\data\\server" \
    +login anonymous \
    +app_update 1829350 validate \
    +quit

# Game is in /data/server (mapped to Z:\data\server)
GAME_EXECUTABLE="/data/server/VRisingServer.exe"

if [ ! -f "$GAME_EXECUTABLE" ]; then
    echo "ERROR: Game executable not found at $GAME_EXECUTABLE"
    exit 1
fi

# 4. Configure Server (Optional - Basic env var injection could go here using jq/sed on ServerHostSettings.json)
# For MVP, we pass arguments to the binary.

# 5. Launch Server
echo ">>> Launching V Rising Server..."
echo "    SaveName: $VR_SERVER_NAME"
echo "    SavePath: Z:\data\saves"

cd "/data/server"

$FEX_BIN $WINE64_BIN ./VRisingServer.exe \
    -persistentDataPath "Z:\\data\\saves" \
    -serverName "$VR_SERVER_NAME" \
    -saveName "world1" \
    -logFile "Z:\\data\\logs\\vrising.log" \
    "$@"
