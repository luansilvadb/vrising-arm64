#!/bin/bash
set -e

APP_ID=1829350
INSTALL_DIR="/app"
DATA_DIR="/data"
STEAM_USER="anonymous"

echo "--> V Rising Dedicated Server - ARM64 Container"
echo "--> Initializing..."

# 1. Setup Directories
mkdir -p "$DATA_DIR/Settings" "$DATA_DIR/Saves" "$WINEPREFIX"

# 2. Xvfb Setup (Headless Display)
# Clean up previous locks if container restarted
rm -f /tmp/.X99-lock
Xvfb :99 -screen 0 1024x768x16 &
export DISPLAY=:99

# 3. SteamCMD Update / Install
# We skip update if NO_UPDATE=1 is set (faster restarts for dev)
if [ -z "$NO_UPDATE" ]; then
    echo "--> Updating V Rising Server (App ID: $APP_ID)..."
    # Note: We need to run steamcmd with box85/box64 depending on its arch.
    # Assuming the image puts steamcmd in path and handles arch.
    # If the steamcmd binary is 32-bit (standard), we need box86.
    # The Dockerfile should alias 'steamcmd' to the right invocation.
    
    steamcmd +force_install_dir "$INSTALL_DIR" \
             +login "$STEAM_USER" \
             +app_update "$APP_ID" validate \
             +quit
else
    echo "--> Skipping SteamCMD update (NO_UPDATE env set)"
fi

# 4. Configuration Generation
SETTINGS_FILE="$DATA_DIR/Settings/ServerHostSettings.json"
GAME_SETTINGS_FILE="$DATA_DIR/Settings/GameSettings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "--> Generating default ServerHostSettings.json..."
    
    # Defaults
    NAME="${VR_SERVER_NAME:-V Rising ARM64}"
    DESC="${VR_SERVER_DESC:-Dedicated Server on Oracle Cloud}"
    PORT="${VR_GAME_PORT:-27015}"
    QUERY_PORT="${VR_QUERY_PORT:-27016}"
    MAX_USERS="${VR_MAX_PLAYERS:-10}"
    PASS="${VR_PASSWORD:-}"
    SECURE="${VR_SECURE:-true}"
    SAVE_NAME="${VR_WORLD_NAME:-world1}"
    
    cat > "$SETTINGS_FILE" <<EOF
{
  "Name": "$NAME",
  "Description": "$DESC",
  "Port": $PORT,
  "QueryPort": $QUERY_PORT,
  "MaxConnectedUsers": $MAX_USERS,
  "Password": "$PASS",
  "Secure": $SECURE,
  "SaveName": "$SAVE_NAME"
}
EOF
fi

# 5. Launch Server
# Using the wrapper to apply Box64 env vars
echo "--> Launching Server..."
cd "$INSTALL_DIR"

# Arguments for the server
SERVER_ARGS=(
    "-batchmode"
    "-nographics"
    "-server"
    "-persistentDataPath" "$DATA_DIR"
    "-logFile" "/dev/stdout"
)

exec /usr/local/bin/wine-preloader-wrapper ./VRisingServer.exe "${SERVER_ARGS[@]}"
