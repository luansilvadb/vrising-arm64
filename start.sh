#!/bin/bash
set -e

################################################################===============
# V RISING SERVER - DOCKER STARTUP SCRIPT
# Optimized for EasyPanel & Clean Architecture
# 
# This script handles:
# 1. Environment Setup & Defaults
# 2. Wine/FEX Initialization
# 3. SteamCMD Updates
# 4. JSON Configuration Injection
# 5. Server Launch
################################################################===============

# ==============================================================================
# 1. LOGGING & HELPERS
# ==============================================================================
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }

# ==============================================================================
# 2. ENVIRONMENT CONFIGURATION
# ==============================================================================
# Define defaults for EasyPanel integration. 
# Users can override these via Docker Environment Variables.

export APP_ID="${APP_ID:-1829350}"
export SERVER_DIR="${SERVER_DIR:-/data/server}"
export STEAMCMD_DIR="${STEAMCMD_DIR:-/data/steamcmd}"
export STEAMCMD_ORIG="${STEAMCMD_ORIG:-/steamcmd}" # Source inside image

# Wine / FEX
export WINE_BIN="${WINE_BIN:-/opt/wine/bin/wine64}"
export WINEPREFIX="${WINEPREFIX:-/data/wineprefix}"
export WINEARCH="win64"
export DISPLAY=":0"

# Game Settings Defaults
export SERVER_NAME="${SERVER_NAME:-V Rising FEX Server}"
export SAVE_NAME="${SAVE_NAME:-world1}"
export GAME_PORT="${GAME_PORT:-9876}"
export QUERY_PORT="${QUERY_PORT:-9877}"
export ENABLE_MODS="${ENABLE_MODS:-false}"

# ==============================================================================
# 3. CORE FUNCTIONS
# ==============================================================================

setup_wine() {
    log_info "Configuring Wine Environment..."
    
    # 1. Clean Xvfb locks
    rm -f /tmp/.X0-lock
    
    # 2. Start Xvfb (Virtual Framebuffer)
    # Background process, required for Unity/Wine
    Xvfb :0 -screen 0 1024x768x16 &
    sleep 2
    
    # 3. Wine Overrides
    export WINEDLLOVERRIDES="mscoree,mshtml="
    
    # 4. Init Wine Prefix if needed
    if [ ! -d "$WINEPREFIX/drive_c" ]; then
        log_info "Initializing Wine Prefix (First Run)..."
        mkdir -p "$WINEPREFIX"
        # Temporarily disable exit-on-error for wineboot as it often emits harmless fixmes
        set +e
        FEXInterpreter "$WINE_BIN" wineboot --init
        set -e
    fi
}

setup_steamcmd() {
    log_info "Verifying SteamCMD..."
    if [ ! -d "$STEAMCMD_DIR" ]; then
        log_info "Initializing persistent SteamCMD..."
        cp -r "$STEAMCMD_ORIG" "$STEAMCMD_DIR"
    fi
}

update_server() {
    log_info "Checking for V Rising updates (App ID: $APP_ID)..."
    
    if [ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
        log_error "SteamCMD missing at $STEAMCMD_DIR"
        exit 1
    fi
    
    # Ensure FEX is available
    if ! command -v FEXInterpreter >/dev/null; then
        log_error "FEXInterpreter not found in PATH!"
        exit 1
    fi

    # Retry Loop for SteamCMD
    MAX_RETRIES=10
    local i=0
    local success=false
    
    pushd "$STEAMCMD_DIR" > /dev/null
    
    while [ $i -lt $MAX_RETRIES ]; do
        # Cleanup cache to avoid 'Missing configuration' errors
        rm -rf appcache
        
        log_info "SteamCMD Update Attempt $(($i + 1))..."
        
        set +e
        FEXInterpreter ./linux32/steamcmd \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "$SERVER_DIR" \
            +login anonymous \
            +app_update "$APP_ID" validate \
            +quit
        EXIT_CODE=$?
        set -e
        
        if [ $EXIT_CODE -eq 0 ]; then
            log_success "Update successful."
            success=true
            break
        elif [ $EXIT_CODE -eq 7 ]; then
             log_warn "SteamCMD is restarting..."
        elif [ $EXIT_CODE -eq 42 ]; then
             log_warn "SteamCMD needs to restart (self-update)..."
        else
             log_warn "SteamCMD exited with code $EXIT_CODE. Retrying in 5s..."
        fi
        
        i=$(($i + 1))
        sleep 5
    done
    
    popd > /dev/null
    
    if [ "$success" = false ]; then
        log_error "Failed to update server after $MAX_RETRIES attempts."
        exit 1
    fi
    
    if [ ! -f "$SERVER_DIR/VRisingServer.exe" ]; then
        log_error "VRisingServer.exe not found after update!"
        exit 1
    fi
}

cleanup_mods() {
    # If mods are disabled, ensure we remove BepInEx artifacts to prevent conflicts
    if [ "$ENABLE_MODS" != "true" ]; then
        if [ -f "$SERVER_DIR/winhttp.dll" ] || [ -d "$SERVER_DIR/BepInEx" ]; then
            log_warn "Mods disabled. Cleaning up BepInEx/WinHTTP..."
            rm -f "$SERVER_DIR/winhttp.dll"
            rm -f "$SERVER_DIR/doorstop_config.ini"
            rm -rf "$SERVER_DIR/BepInEx"
            rm -f "$SERVER_DIR/preloader_*.log"
            log_success "Cleanup complete."
        fi
    else
        log_info "Mods enabled. Skipping cleanup."
    fi
}

configure_settings() {
    log_info "Applying Server Host Settings via JSON..."
    
    SAVE_DATA_PATH="/data/save-data"
    SETTINGS_DIR="$SAVE_DATA_PATH/Settings"
    SETTINGS_FILE="$SETTINGS_DIR/ServerHostSettings.json"
    
    mkdir -p "$SETTINGS_DIR"
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "{}" > "$SETTINGS_FILE"
    fi
    
    # Use JQ to idempotently update configuration based on Envs
    TMP_SETTINGS=$(mktemp)
    
    jq --arg desc "${SERVER_DESCRIPTION}" \
       --arg list "${LIST_ON_MASTER_SERVER}" \
       --arg maxUsers "${MAX_CONNECTED_USERS}" \
       --arg maxAdmins "${MAX_CONNECTED_ADMINS}" \
       --arg fps "${SERVER_FPS}" \
       --arg pass "${SERVER_PASSWORD}" \
       --arg secure "${SECURE}" \
       --arg autoSaveCount "${AUTO_SAVE_COUNT}" \
       --arg autoSaveInterval "${AUTO_SAVE_INTERVAL}" \
       --arg compressSave "${COMPRESS_SAVE_FILES}" \
       --arg gamePreset "${GAME_SETTINGS_PRESET}" \
       --arg diffPreset "${GAME_DIFFICULTY_PRESET}" \
       --arg adminDebug "${ADMIN_ONLY_DEBUG_EVENTS}" \
       --arg disableDebug "${DISABLE_DEBUG_EVENTS}" \
       --arg apiEnabled "${API_ENABLED}" \
       --arg rconEnabled "${RCON_ENABLED}" \
       --arg rconPort "${RCON_PORT}" \
       --arg rconPass "${RCON_PASSWORD}" \
       '
      (if $desc != "" then .Description = $desc else . end) |
      (if $list == "true" then .ListOnMasterServer = true | .ListOnSteam = true | .ListOnEOS = true 
       elif $list == "false" then .ListOnMasterServer = false | .ListOnSteam = false | .ListOnEOS = false 
       else . end) |
      (if $maxUsers != "" then .MaxConnectedUsers = ($maxUsers | tonumber) else . end) |
      (if $maxAdmins != "" then .MaxConnectedAdmins = ($maxAdmins | tonumber) else . end) |
      (if $fps != "" then .ServerFps = ($fps | tonumber) else . end) |
      (if $pass != "" then .Password = $pass else . end) |
      (if $secure != "" then .Secure = ($secure == "true") else . end) |
      (if $autoSaveCount != "" then .AutoSaveCount = ($autoSaveCount | tonumber) else . end) |
      (if $autoSaveInterval != "" then .AutoSaveInterval = ($autoSaveInterval | tonumber) else . end) |
      (if $compressSave != "" then .CompressSaveFiles = ($compressSave == "true") else . end) |
      (if $gamePreset != "" then .GameSettingsPreset = $gamePreset else . end) |
      (if $diffPreset != "" then .GameDifficultyPreset = $diffPreset else . end) |
      (if $adminDebug != "" then .AdminOnlyDebugEvents = ($adminDebug == "true") else . end) |
      (if $disableDebug != "" then .DisableDebugEvents = ($disableDebug == "true") else . end) |
      (if $apiEnabled != "" then .API.Enabled = ($apiEnabled == "true") else . end) |
      (if $rconEnabled != "" then .Rcon.Enabled = ($rconEnabled == "true") else . end) |
      (if $rconPort != "" then .Rcon.Port = ($rconPort | tonumber) else . end) |
      (if $rconPass != "" then .Rcon.Password = $rconPass else . end)
    ' "$SETTINGS_FILE" > "$TMP_SETTINGS" && mv "$TMP_SETTINGS" "$SETTINGS_FILE"
    
    log_success "Server Host Settings applied."
}

# ==============================================================================
# 4. MAIN EXECUTION FLOW
# ==============================================================================
log_info ">>> Starting V Rising Server (ARM64/FEX) <<<"

# Create standard directories
mkdir -p "$SERVER_DIR"
mkdir -p "$WINEPREFIX"

# Setup Phases
setup_wine
setup_steamcmd
update_server
cleanup_mods
configure_settings

# Launch
log_info "Launching VRisingServer.exe..."
cd "$SERVER_DIR"

LAUNCH_ARGS=(
    "VRisingServer.exe"
    "-batchmode"
    "-nographics"
    "-persistentDataPath" "Z:/data/save-data"
    "-serverName" "$SERVER_NAME"
    "-saveName" "$SAVE_NAME"
    "-logFile" "Z:/data/VRisingServer.log"
    "-gamePort" "$GAME_PORT"
    "-queryPort" "$QUERY_PORT"
)

log_info "Command: FEXInterpreter $WINE_BIN ${LAUNCH_ARGS[*]}"

# Exec replaces the shell process with FEX/Wine
exec FEXInterpreter "$WINE_BIN" "${LAUNCH_ARGS[@]}"
