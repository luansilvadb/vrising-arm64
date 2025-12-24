#!/bin/bash

# V Rising ARM64 Server Startup Script
# Optimized for production usage

echo "--- V Rising ARM64 Server Startup ---"
echo "--- $(date) ---"

# Graceful shutdown handler
cleanup() {
    echo ""
    echo "--- Received shutdown signal ($(date)) ---"
    echo "--- Saving game and stopping Wine processes... ---"
    
    # Try to gracefully stop wineserver. 
    # V Rising server usually catches the signal too, but wineserver cleanup is good practice.
    wineserver -k 2>/dev/null || true
    
    echo "--- Cleanup complete, exiting ---"
    exit 0
}
trap cleanup SIGTERM SIGINT SIGHUP

# Default server configuration
SERVER_NAME="${SERVER_NAME:-"V Rising Server"}"
SAVE_NAME="${SAVE_NAME:-"world1"}"
SKIP_UPDATE="${SKIP_UPDATE:-0}"

echo "--- Server Configuration ---"
echo "SERVER_NAME: $SERVER_NAME"
echo "SAVE_NAME: $SAVE_NAME"
echo "USER: $(whoami)"

# Box64 Performance Optimization (Production Stable Settings)
export BOX64_DYNAREC="${BOX64_DYNAREC:-1}"
export BOX64_DYNAREC_BIGBLOCK="${BOX64_DYNAREC_BIGBLOCK:-0}"       # Critical for Unity games with JIT
export BOX64_DYNAREC_STRONGMEM="${BOX64_DYNAREC_STRONGMEM:-2}"    # Stricter memory ordering
export BOX64_DYNAREC_SAFEFLAGS="${BOX64_DYNAREC_SAFEFLAGS:-1}"    # Safer x86 flag handling
export BOX64_DYNAREC_FASTNAN="${BOX64_DYNAREC_FASTNAN:-1}"
export BOX64_DYNAREC_FASTROUND="${BOX64_DYNAREC_FASTROUND:-1}"
export BOX64_DYNAREC_X87DOUBLE="${BOX64_DYNAREC_X87DOUBLE:-1}"
export BOX64_DYNAREC_CALLRET="${BOX64_DYNAREC_CALLRET:-1}"        # Optimize CALL/RET instructions
export BOX64_DYNACACHE="${BOX64_DYNACACHE:-1}"                    # Enable dynarec cache
export BOX64_MAXCPU="${BOX64_MAXCPU:-4}"
export BOX64_LOG="${BOX64_LOG:-0}"

# Box86 Performance Optimization (for SteamCMD)
export BOX86_DYNAREC="${BOX86_DYNAREC:-1}"
export BOX86_DYNAREC_BIGBLOCK="${BOX86_DYNAREC_BIGBLOCK:-2}"
export BOX86_DYNAREC_STRONGMEM="${BOX86_DYNAREC_STRONGMEM:-1}"
export BOX86_LOG="${BOX86_LOG:-0}"

# Ensure directories exist (init.sh already fixed ownership as root)
mkdir -p /data/server /data/save-data /data/wine-prefix /data/backups

# Log rotation for server.log (prevent disk exhaustion)
if [ -f "/data/server.log" ]; then
    SIZE=$(stat -c%s "/data/server.log" 2>/dev/null || echo 0)
    # Rotate if exceeds 100MB
    if [ "$SIZE" -gt 104857600 ]; then
        echo "--- Rotating server.log (size: $SIZE bytes) ---"
        mv /data/server.log /data/server.log.1
    fi
fi

# Export Wine Environment
export WINEPREFIX="/data/wine-prefix"
export WINEDEBUG="-all"
export WINEARCH="win64"

# SteamCMD Update Section
if [ "$SKIP_UPDATE" -eq "1" ]; then
    echo "--- Skipping SteamCMD update (SKIP_UPDATE=1) ---"
else
    echo "--- Updating V Rising (AppID: 1829350) ---"
    echo "--- SteamCMD will download Windows version to /data/server ---"

    cd /usr/games/steamcmd

    echo "--- Step 1: Ensure SteamCMD is fully updated ---"
    box86 ./linux32/steamcmd +quit 2>&1 | tee /tmp/steamcmd_update.log
    
    echo "--- Step 2: Download V Rising server ---"
    # Added validation and robust retry logic
    MAX_RETRIES=3
    RETRY_COUNT=0
    SUCCESS=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo "--- Download attempt $(($RETRY_COUNT + 1)) of $MAX_RETRIES ---"
        box86 ./linux32/steamcmd \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir /data/server \
            +login anonymous \
            +app_info_update 1 \
            +app_update 1829350 validate \
            +quit 2>&1 | tee /tmp/steamcmd.log
        
        if [ -f "/data/server/VRisingServer.exe" ]; then
            echo "--- Verified VRisingServer.exe exists ---"
            SUCCESS=1
            break
        else
            echo "--- VRisingServer.exe not found. Retrying in 5 seconds... ---"
            sleep 5
            RETRY_COUNT=$(($RETRY_COUNT + 1))
        fi
    done

    if [ $SUCCESS -eq 0 ]; then
        echo "ERROR: Failed to download V Rising Server after $MAX_RETRIES attempts."
        exit 1
    fi
    echo "--- Download verified successfully ---"
fi

# Xvfb Setup
echo "--- Starting Xvfb ---"
# Check if Xvfb is already running (restarts)
if [ -f /tmp/.X0-lock ]; then
    rm -f /tmp/.X0-lock
fi
Xvfb :0 -screen 0 1024x768x24 &
export DISPLAY=:0
sleep 2

# Wine Prefix Setup
# We check if we need to copy the pre-baked prefix to the persistent volume
if [ ! -d "$WINEPREFIX/drive_c" ]; then
    echo "--- Initializing Wine Prefix in /data/wine-prefix ---"
    # If we have a pre-baked prefix in home, use it to speed up start
    if [ -d "/home/vrising/.wine" ]; then
        echo "--- Copying pre-initialized Wine prefix from image... ---"
        cp -a /home/vrising/.wine/* "$WINEPREFIX/" 2>/dev/null || true
    fi
    
    echo "--- Finalizing Wineboot ---"
    wineboot --init 2>&1
    wineserver --wait 2>&1 || true
fi

# Launch V Rising
echo "--- Launching V Rising Server ---"
cd /data/server

if [ ! -f "./VRisingServer.exe" ]; then
    echo "CRITICAL ERROR: VRisingServer.exe missing!"
    exit 1
fi

echo "--- Command: wine64 ./VRisingServer.exe -persistentDataPath Z:\\data\\save-data -serverName $SERVER_NAME -saveName $SAVE_NAME ---"

# Launch process in background to allow trap to catch signals
wine64 ./VRisingServer.exe \
    -batchmode \
    -nographics \
    -persistentDataPath "Z:\\data\\save-data" \
    -serverName "$SERVER_NAME" \
    -saveName "$SAVE_NAME" \
    -logFile "Z:\\data\\server.log" \
    ${EXTRA_ARGS:-} &

SERVER_PID=$!
echo "--- V Rising Server PID: $SERVER_PID ---"

wait $SERVER_PID
EXIT_CODE=$?

echo "--- V Rising Server exited with code: $EXIT_CODE ---"
exit $EXIT_CODE
