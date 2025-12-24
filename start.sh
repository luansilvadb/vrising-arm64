#!/bin/bash
# Removed set -e to allow debugging and show actual errors
# set -e

echo "--- V Rising ARM64 Server Startup ---"
echo "--- $(date) ---"

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

# Verify VRisingServer.exe exists
if [ ! -f "./VRisingServer.exe" ]; then
    echo "ERROR: VRisingServer.exe not found in /data/server!"
    echo "Contents of /data/server:"
    ls -la /data/server/
    echo "--- Sleeping to prevent restart loop ---"
    sleep infinity
fi

echo "--- Files in server directory ---"
ls -la ./VRisingServer.exe

echo "--- Wine prefix info ---"
echo "WINEPREFIX=$WINEPREFIX"
echo "WINEARCH=$WINEARCH"

# Initialize Wine prefix if needed
echo "--- Initializing Wine prefix (if needed) ---"
box64 /opt/wine/bin/wineboot --init 2>&1 || echo "Wineboot init returned: $?"

# Launch via Box64 -> Wine64
echo "--- Executing VRisingServer.exe via box64 wine64 ---"
box64 /opt/wine/bin/wine64 ./VRisingServer.exe \
    -persistentDataPath "Z:\\data\\save-data" \
    -serverName "$SERVER_NAME" \
    -saveName "$SAVE_NAME" \
    -logFile "Z:\\data\\server.log" \
    $EXTRA_ARGS

EXIT_CODE=$?
echo "--- VRisingServer.exe exited with code: $EXIT_CODE ---"
echo "--- Server stopped. Sleeping to prevent restart loop ---"
sleep infinity
