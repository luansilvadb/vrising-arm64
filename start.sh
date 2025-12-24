#!/bin/bash
# Removed set -e to allow debugging and show actual errors
# set -e

echo "--- V Rising ARM64 Server Startup ---"
echo "--- $(date) ---"

# Graceful shutdown handler
cleanup() {
    echo ""
    echo "--- Received shutdown signal ($(date)) ---"
    echo "--- Saving game and stopping Wine processes... ---"
    wineserver -k 2>/dev/null || true
    echo "--- Cleanup complete, exiting ---"
    exit 0
}
trap cleanup SIGTERM SIGINT SIGHUP

# Default server configuration (fallback if not set via environment)
SERVER_NAME="${SERVER_NAME:-"V Rising Server"}"
SAVE_NAME="${SAVE_NAME:-"world1"}"

echo "--- Server Configuration ---"
echo "SERVER_NAME: $SERVER_NAME"
echo "SAVE_NAME: $SAVE_NAME"

# Box64 Performance Optimization (4 cores ARM)
export BOX64_DYNAREC="${BOX64_DYNAREC:-1}"
export BOX64_DYNAREC_BIGBLOCK="${BOX64_DYNAREC_BIGBLOCK:-2}"
export BOX64_DYNAREC_STRONGMEM="${BOX64_DYNAREC_STRONGMEM:-1}"
export BOX64_DYNAREC_SAFEFLAGS="${BOX64_DYNAREC_SAFEFLAGS:-0}"
export BOX64_DYNAREC_FASTNAN="${BOX64_DYNAREC_FASTNAN:-1}"
export BOX64_DYNAREC_FASTROUND="${BOX64_DYNAREC_FASTROUND:-1}"
export BOX64_DYNAREC_X87DOUBLE="${BOX64_DYNAREC_X87DOUBLE:-1}"
export BOX64_MAXCPU="${BOX64_MAXCPU:-4}"
export BOX64_LOG="${BOX64_LOG:-0}"

# Box86 Performance Optimization (for SteamCMD)
export BOX86_DYNAREC="${BOX86_DYNAREC:-1}"
export BOX86_DYNAREC_BIGBLOCK="${BOX86_DYNAREC_BIGBLOCK:-2}"
export BOX86_DYNAREC_STRONGMEM="${BOX86_DYNAREC_STRONGMEM:-1}"
export BOX86_LOG="${BOX86_LOG:-0}"

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
# Command order is critical for SteamCMD:
# 1. Set platform type first
# 2. Set install directory 
# 3. Login
# 4. Download app
box86 ./linux32/steamcmd \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir /data/server \
    +login anonymous \
    +app_info_update 1 \
    +app_update 1829350 validate \
    +quit 2>&1 | tee /tmp/steamcmd.log

# If first attempt failed, retry (sometimes SteamCMD needs a second try)
if [ ! -f "/data/server/VRisingServer.exe" ]; then
    echo "--- First download attempt incomplete, retrying... ---"
    box86 ./linux32/steamcmd \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir /data/server \
        +login anonymous \
        +app_update 1829350 validate \
        +quit 2>&1 | tee -a /tmp/steamcmd.log
fi

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
    echo "--- Exiting with error to trigger restart policy ---"
    exit 1
fi

echo "--- Download verified successfully ---"

echo "--- Starting Xvfb ---"
Xvfb :0 -screen 0 1024x768x24 &
export DISPLAY=:0
sleep 1

echo "--- Launching V Rising Server ---"
cd /data/server

# Verify VRisingServer.exe exists
if [ ! -f "./VRisingServer.exe" ]; then
    echo "ERROR: VRisingServer.exe not found in /data/server!"
    echo "Contents of /data/server:"
    ls -la /data/server/
    echo "--- Exiting with error ---"
    exit 1
fi

echo "--- Files in server directory ---"
ls -la ./VRisingServer.exe

echo "--- Wine prefix info ---"
echo "WINEPREFIX=$WINEPREFIX"
echo "WINEARCH=$WINEARCH"

# Copy pre-initialized Wine prefix if local one does not exist
if [ ! -d "$WINEPREFIX/drive_c" ]; then
    echo "--- Copying pre-initialized Wine prefix ---"
    cp -r /root/.wine/* "$WINEPREFIX/" 2>/dev/null || true
fi

# Initialize Wine prefix with retry logic
echo "--- Initializing Wine prefix ---"
for attempt in 1 2 3; do
    echo "--- Wine initialization attempt $attempt ---"
    wineboot --init 2>&1
    WINEBOOT_EXIT=$?
    if [ $WINEBOOT_EXIT -eq 0 ]; then
        echo "--- Wineboot succeeded ---"
        break
    fi
    echo "--- Wineboot attempt $attempt returned: $WINEBOOT_EXIT ---"
    sleep 2
done

# Wait for wineserver to be ready
echo "--- Waiting for wineserver ---"
wineserver --wait 2>&1 || true

# Launch via wine64 wrapper (which uses box64)
echo "--- Executing VRisingServer.exe via wine64 ---"
echo "--- Command: wine64 ./VRisingServer.exe -persistentDataPath Z:\\data\\save-data -serverName $SERVER_NAME -saveName $SAVE_NAME ---"

wine64 ./VRisingServer.exe \
    -persistentDataPath "Z:\\data\\save-data" \
    -serverName "$SERVER_NAME" \
    -saveName "$SAVE_NAME" \
    -logFile "Z:\\data\\server.log" \
    ${EXTRA_ARGS:-}

EXIT_CODE=$?
echo "--- VRisingServer.exe exited with code: $EXIT_CODE ---"
echo "--- Server stopped. Sleeping to prevent restart loop ---"
sleep infinity
