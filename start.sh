#!/bin/bash
set -e

echo "--- V Rising ARM64 Server Startup ---"

# Ensure directories exist
mkdir -p /data/server /data/save-data /data/wine-prefix

# Export Wine Environment
export WINEPREFIX="/data/wine-prefix"
export WINEDEBUG="-all"
export WINEARCH="win64"

# Install/Update V Rising via SteamCMD (Windows version)
# We use the Windows SteamCMD running via Box86/Wine or just native Linux SteamCMD via Box86?
# SteamCMD Linux is 32-bit. Box86 is perfect for it.
# But we need to download WINDOWS app.
echo "--- Updating V Rising (AppID: 1829350) ---"
# +platform override is crucial to force downloading Windows binaries on Linux
steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /data/server +login anonymous +app_update 1829350 validate +quit

echo "--- Starting Xvfb ---"
Xvfb :0 -screen 0 1024x768x24 &
export DISPLAY=:0

echo "--- Launching V Rising Server ---"
cd /data/server

# Check for settings match
# (Optional: Scripting to copy env vars to JSON settings could go here)

# Launch via Box64 -> Wine64
# We use 'wine64' which should be in the path, wrapping box64 automatically if configured, 
# or we invoke 'box64 wine64'.
box64 wine64 ./VRisingServer.exe \
    -persistentDataPath "Z:\\data\\save-data" \
    -serverName "$SERVER_NAME" \
    -saveName "$SAVE_NAME" \
    -logFile "Z:\\data\\server.log" \
    $EXTRA_ARGS
