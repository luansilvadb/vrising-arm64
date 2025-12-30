#!/bin/bash
set -euo pipefail

# =============================================================================
# V Rising ARM64/FEX Server - Enhanced Diagnostics Edition
# =============================================================================

# Logging with timestamps and levels
log() { 
    local ts
    ts=$(date '+%H:%M:%S')
    printf '\033[0;90m[%s]\033[0m \033[1;%sm[%s]\033[0m %s\n' "$ts" "$1" "$2" "$3"
}
info()  { log 34 INFO "$1"; }
warn()  { log 33 WARN "$1"; }
fail()  { log 31 FAIL "$1"; exit 1; }
ok()    { log 32 OK "$1"; }
debug() { [[ "${DEBUG:-false}" == "true" ]] && log 35 DEBUG "$1" || true; }
section() { printf '\n\033[1;36m━━━ %s ━━━\033[0m\n' "$1"; }

# Environment Defaults (EasyPanel compatible)
: "${APP_ID:=1829350}"
: "${SERVER_DIR:=/data/server}"
: "${STEAMCMD_DIR:=/data/steamcmd}"
: "${STEAMCMD_ORIG:=/steamcmd}"
: "${UPDATE_ON_START:=true}"
: "${WINE_BIN:=/opt/wine/bin/wine64}"
: "${WINEPREFIX:=/data/wineprefix}"
: "${SERVER_NAME:=V Rising FEX Server}"
: "${SAVE_NAME:=world1}"
: "${GAME_PORT:=9876}"
: "${QUERY_PORT:=9877}"

: "${DEBUG:=false}"


export APP_ID SERVER_DIR STEAMCMD_DIR STEAMCMD_ORIG UPDATE_ON_START
export WINE_BIN WINEPREFIX WINEARCH=win64 DISPLAY=:0
export SERVER_NAME SAVE_NAME GAME_PORT QUERY_PORT DEBUG

# --- PERFORMANCE FLAGS (DEEP RESEARCH) ---
# 1. FEX TSO: Disable Total Store Ordering (Risk: Stability / Reward: +15-20% Perf)
# Recommended for V Rising as Unity is generally race-condition safe-ish.
export FEX_TSOENABLE=0 

# 2. Unity/Mono GC: Force Incremental GC to reduce freeze spikes
export GC_DONT_GC=0 # Ensure GC runs
export UNITY_GC_MODE=incremental

# 3. Network Buffer Support (Works with host sysctl)
export WINE_TCP_BUFFER_SIZE=65536

setup_wine() {
    section "Wine/FEX Configuration"
    
    # Verify FEX is available
    if command -v FEXInterpreter &>/dev/null; then
        ok "FEXInterpreter found: $(which FEXInterpreter)"
    else
        fail "FEXInterpreter not found in PATH"
    fi
    
    # Verify Wine binary
    if [ -x "$WINE_BIN" ]; then
        ok "Wine binary: $WINE_BIN"
    else
        fail "Wine binary not found or not executable: $WINE_BIN"
    fi
    
    # Start Xvfb
    info "Starting Xvfb virtual display..."
    rm -f /tmp/.X0-lock
    Xvfb :0 -screen 0 1024x768x16 &
    local xvfb_pid=$!
    
    for i in $(seq 1 50); do 
        [ -e /tmp/.X11-unix/X0 ] && break
        sleep 0.1
    done
    
    if [ -e /tmp/.X11-unix/X0 ]; then
        ok "Xvfb ready (PID: $xvfb_pid)"
    else
        warn "Xvfb socket not found after 5s - display may not work"
    fi
    
    # Wine DLL overrides - disable winemenubuilder to clean logs
    export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d;winhttp=n,b"
    
    # Wine debug level (configurable)
    if [[ "$DEBUG" == "true" ]]; then
        export WINEDEBUG="+loaddll,+module,+relay"
        info "Wine debug: VERBOSE (relay tracing enabled)"
    else
        export WINEDEBUG="$WINE_DEBUG_LEVEL"
        info "Wine debug: $WINE_DEBUG_LEVEL"
    fi
    

    
    # .NET diagnostics
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    if [[ "$DEBUG" == "true" ]]; then
        export COMPlus_LogEnable=1
        export COMPlus_LogLevel=10
        export COREHOST_TRACE=1
        info "CoreCLR tracing: ENABLED"
    fi
    

    
    # Initialize Wine prefix if needed
    if [ ! -d "$WINEPREFIX/drive_c" ]; then
        info "Initializing Wine prefix at $WINEPREFIX..."
        mkdir -p "$WINEPREFIX"
        if FEXInterpreter "$WINE_BIN" wineboot --init 2>&1 | head -20; then
            ok "Wine prefix initialized"
        else
            warn "Wine prefix init had warnings (usually harmless)"
        fi
    else
        ok "Wine prefix exists: $WINEPREFIX"
    fi
}

setup_steamcmd() {
    [ -d "$STEAMCMD_DIR" ] || { info "Copying SteamCMD..."; cp -r "$STEAMCMD_ORIG" "$STEAMCMD_DIR"; }
}

update_server() {
    [[ "$UPDATE_ON_START" != "true" && -f "$SERVER_DIR/VRisingServer.exe" ]] && { info "Skipping update"; return; }
    
    info "Updating V Rising (App: $APP_ID)..."
    [ -f "$STEAMCMD_DIR/steamcmd.sh" ] || fail "SteamCMD missing"
    command -v FEXInterpreter >/dev/null || fail "FEXInterpreter not found"
    
    local retries=10 i=0
    cd "$STEAMCMD_DIR"
    
    while (( i++ < retries )); do
        rm -rf appcache
        info "SteamCMD attempt $i/$retries..."
        
        if FEXInterpreter ./linux32/steamcmd \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "$SERVER_DIR" \
            +login anonymous \
            +app_update "$APP_ID" validate \
            +quit; then
            ok "Update complete"
            break
        fi
        
        (( i < retries )) && { warn "Retrying in 5s..."; sleep 5; }
    done
    
    
    if [ -f "$SERVER_DIR/VRisingServer.exe" ]; then
        ok "VRisingServer.exe found"
    else
        warn "VRisingServer.exe NOT FOUND in $SERVER_DIR"
        info "Directory listing:"
        ls -F "$SERVER_DIR" || true
        fail "Server binary missing"
    fi
}



remove_mod_artifacts() {
    section "Sanitizing Server (Vanilla Enforcement)"
    
    # Comprehensive list of mod loader artifacts to remove (including backups)
    local mod_artifacts=(
        "BepInEx"
        "doorstop_config.ini"
        "winhttp.dll"
        "winhttp.dll.bak"
        "winmm.dll"
        "winmm.dll.bak"
        "version.dll"
        "version.dll.bak"
        "doorstop_libs"
        ".doorstop_version"
        "MelonLoader"
        "Mods"
        "user_assemblies"
    )
    
    local found_any=false
    
    for artifact in "${mod_artifacts[@]}"; do
        if [ -e "$SERVER_DIR/$artifact" ]; then
            rm -rf "$SERVER_DIR/$artifact"
            ok "Removed mod artifact: $artifact"
            found_any=true
        fi
    done
    
    if [[ "$found_any" == "false" ]]; then
        ok "Verified clean: No mod artifacts found."
    fi
}

configure_settings() {
    info "Applying server settings..."
    local settings_dir="/data/save-data/Settings"
    local settings_file="$settings_dir/ServerHostSettings.json"
    local game_settings_file="$settings_dir/ServerGameSettings.json"
    
    mkdir -p "$settings_dir"
    [ -f "$settings_file" ] || echo '{}' > "$settings_file"
    
    # Check if custom ServerGameSettings.json exists (e.g., from EasyPanel File Mount)
    if [ -f "$game_settings_file" ]; then
        ok "Custom ServerGameSettings.json detected (File Mount)"
        info "Game settings will be loaded from: $game_settings_file"
        # Force empty GameSettingsPreset to use custom file
        if [ -z "${GAME_SETTINGS_PRESET:-}" ]; then
            info "GameSettingsPreset is empty - custom settings will be used"
        else
            warn "GameSettingsPreset='$GAME_SETTINGS_PRESET' is set - this may override your custom ServerGameSettings.json!"
        fi
    else
        info "No custom ServerGameSettings.json found - using defaults or preset"
    fi
    
    # Build jq command - remove GameSettingsPreset from JSON if not explicitly set
    # This ensures the custom ServerGameSettings.json file is used
    jq --arg desc "${SERVER_DESCRIPTION:-}" \
       --arg list "${LIST_ON_MASTER_SERVER:-}" \
       --arg maxUsers "${MAX_CONNECTED_USERS:-}" \
       --arg maxAdmins "${MAX_CONNECTED_ADMINS:-}" \
       --arg fps "${SERVER_FPS:-}" \
       --arg pass "${SERVER_PASSWORD:-}" \
       --arg secure "${SECURE:-}" \
       --arg autoSaveCount "${AUTO_SAVE_COUNT:-}" \
       --arg autoSaveInterval "${AUTO_SAVE_INTERVAL:-}" \
       --arg compressSave "${COMPRESS_SAVE_FILES:-}" \
       --arg gamePreset "${GAME_SETTINGS_PRESET:-}" \
       --arg diffPreset "${GAME_DIFFICULTY_PRESET:-}" \
       --arg adminDebug "${ADMIN_ONLY_DEBUG_EVENTS:-}" \
       --arg disableDebug "${DISABLE_DEBUG_EVENTS:-}" \
       --arg apiEnabled "${API_ENABLED:-}" \
       --arg rconEnabled "${RCON_ENABLED:-}" \
       --arg rconPort "${RCON_PORT:-}" \
       --arg rconPass "${RCON_PASSWORD:-}" '
        def update(k; v; fn): if v != "" then .[k] = fn else . end;
        def str(v): v;
        def num(v): v | tonumber;
        def bool(v): v == "true";
        
        update("Description"; $desc; str($desc)) |
        (if $list == "true" then .ListOnMasterServer = true | .ListOnSteam = true | .ListOnEOS = true
         elif $list == "false" then .ListOnMasterServer = false | .ListOnSteam = false | .ListOnEOS = false
         else . end) |
        update("MaxConnectedUsers"; $maxUsers; num($maxUsers)) |
        update("MaxConnectedAdmins"; $maxAdmins; num($maxAdmins)) |
        update("ServerFps"; $fps; num($fps)) |
        update("Password"; $pass; str($pass)) |
        update("Secure"; $secure; bool($secure)) |
        update("AutoSaveCount"; $autoSaveCount; num($autoSaveCount)) |
        update("AutoSaveInterval"; $autoSaveInterval; num($autoSaveInterval)) |
        update("CompressSaveFiles"; $compressSave; bool($compressSave)) |
        # Only set GameSettingsPreset if explicitly provided, otherwise remove it
        (if $gamePreset != "" then .GameSettingsPreset = $gamePreset else del(.GameSettingsPreset) end) |
        update("GameDifficultyPreset"; $diffPreset; str($diffPreset)) |
        update("AdminOnlyDebugEvents"; $adminDebug; bool($adminDebug)) |
        update("DisableDebugEvents"; $disableDebug; bool($disableDebug)) |
        update("API.Enabled"; $apiEnabled; bool($apiEnabled)) |
        update("Rcon.Enabled"; $rconEnabled; bool($rconEnabled)) |
        update("Rcon.Port"; $rconPort; num($rconPort)) |
        update("Rcon.Password"; $rconPass; str($rconPass))
    ' "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"
    
    ok "Settings applied"
}

# =============================================================================
# Diagnostic Functions
# =============================================================================



dump_environment() {
    section "Environment Summary"
    
    info "Server: $SERVER_NAME"
    info "Ports: Game=$GAME_PORT, Query=$QUERY_PORT"
    info "Save: $SAVE_NAME"

    info "Debug: $DEBUG"
    info "Wine prefix: $WINEPREFIX"
    info "Server dir: $SERVER_DIR"
    
    if [[ "$DEBUG" == "true" ]]; then
        info "--- Full Environment ---"
        env | grep -E '^(WINE|COMPlus|DOTNET|CORE|SERVER|GAME|QUERY|SAVE|ENABLE)' | sort || true
    fi
}

pre_launch_checks() {
    section "Pre-Launch Checks"
    
    # Verify VRisingServer.exe
    local exe="$SERVER_DIR/VRisingServer.exe"
    if [ -f "$exe" ]; then
        ok "VRisingServer.exe: $(stat -c%s "$exe") bytes"
    else
        fail "VRisingServer.exe not found!"
    fi
    
    # Check Unity dependencies
    local unitydeps=("GameAssembly.dll" "UnityPlayer.dll" "VRisingServer_Data")
    for dep in "${unitydeps[@]}"; do
        if [ -e "$SERVER_DIR/$dep" ]; then
            ok "Unity: $dep"
        else
            warn "Missing Unity component: $dep"
        fi
    done
    
    # Disk space check
    local avail
    avail=$(df -h "$SERVER_DIR" | awk 'NR==2 {print $4}')
    info "Available disk space: $avail"
    
    # Memory check
    local mem_total mem_avail
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_avail=$(free -h | awk '/^Mem:/ {print $7}')
    info "Memory: $mem_avail available / $mem_total total"
}

# =============================================================================
# Main Execution
# =============================================================================

fix_permissions() {
    section "Fixing Permissions"
    
    # Ensure /data and all subdirectories are owned by root (the user running the container)
    if [ -d "/data" ]; then
        local current_owner
        current_owner=$(stat -c '%U' /data 2>/dev/null || echo "unknown")
        
        if [ "$current_owner" != "root" ]; then
            info "Fixing ownership of /data (was: $current_owner)..."
            chown -R root:root /data
            ok "Permissions fixed"
        else
            ok "Permissions OK (owner: root)"
        fi
    fi
}

main() {
    printf '\n\033[1;35m╔═══════════════════════════════════════════════════════════════╗\033[0m\n'
    printf '\033[1;35m║     V Rising Dedicated Server (ARM64/FEX) - Diagnostics       ║\033[0m\n'
    printf '\033[1;35m╚═══════════════════════════════════════════════════════════════╝\033[0m\n\n'
    
    info "Started at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    info "Architecture: $(uname -m)"
    
    mkdir -p "$SERVER_DIR" "$WINEPREFIX"
    fix_permissions
    
    setup_wine
    setup_steamcmd
    update_server
    remove_mod_artifacts

    configure_settings
    dump_environment
    pre_launch_checks
    
    section "Launching Server"
    info "Command: FEXInterpreter $WINE_BIN VRisingServer.exe"
    info "Log file: NUL (Performance Mode)"
    info "Press Ctrl+C to stop the server"
    printf '\033[0;90m%s\033[0m\n' "────────────────────────────────────────────────────────────────"
    
    # 4. CPU Priority: Give High Priority to Server Process
    renice -n -10 -p $$ || warn "Failed to set high priority (renice)"

    cd "$SERVER_DIR"
    
    exec FEXInterpreter "$WINE_BIN" \
        VRisingServer.exe \
        -batchmode \
        -nographics \
        -persistentDataPath "Z:/data/save-data" \
        -serverName "$SERVER_NAME" \
        -saveName "$SAVE_NAME" \
        -logFile "NUL" \
        -gamePort "$GAME_PORT" \
        -queryPort "$QUERY_PORT" \
        -job-worker-count 4
}

# Run main
main "$@"

