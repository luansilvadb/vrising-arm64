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
echo "--- Updating V Rising (AppID: 1829350) ---"
echo "--- SteamCMD will download Windows version to /data/server ---"

# Run SteamCMD with verbose output using explicit box86
# IMPORTANT: SteamCMD must be run TWICE!
# First run: SteamCMD updates itself and restarts, losing all command-line args
# Second run: Actual game download with commands
echo "--- Running SteamCMD via box86 ---"
cd /usr/games/steamcmd

echo "--- Step 1: Ensure SteamCMD is fully updated ---"
box86 ./linux32/steamcmd +quit 2>&1 | tee /tmp/steamcmd_update.log
echo "--- SteamCMD self-update exit code: $? ---"

echo "--- Step 2: Download V Rising server ---"
box86 ./linux32/steamcmd \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir /data/server \
    +login anonymous \
    +app_update 1829350 validate \
    +quit 2>&1 | tee /tmp/steamcmd.log

STEAM_EXIT=$?
echo "--- SteamCMD exit code: $STEAM_EXIT ---"

# Show what was downloaded
echo "--- Contents of /data/server after SteamCMD ---"
ls -la /data/server/ 2>&1 || echo "Directory does not exist or is empty"

# Check if executable exists
if [ ! -f "/data/server/VRisingServer.exe" ]; then
    echo ""
    echo "=========================================="
    echo "ERROR: Download failed!"
    echo "VRisingServer.exe not found after SteamCMD"
    echo "=========================================="
    echo ""
    echo "--- Last 50 lines of SteamCMD log ---"
    tail -50 /tmp/steamcmd.log
    echo ""
    echo "--- Checking SteamCMD installation ---"
    which steamcmd
    file $(which steamcmd)
    echo ""
    echo "--- Sleeping to allow log inspection ---"
    sleep infinity
fi

echo "--- Download verified successfully ---"

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
