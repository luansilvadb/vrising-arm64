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
: "${ENABLE_MODS:=false}"
: "${DEBUG:=false}"
: "${WINE_DEBUG_LEVEL:=fixme-all}"

export APP_ID SERVER_DIR STEAMCMD_DIR STEAMCMD_ORIG UPDATE_ON_START
export WINE_BIN WINEPREFIX WINEARCH=win64 DISPLAY=:0
export SERVER_NAME SAVE_NAME GAME_PORT QUERY_PORT ENABLE_MODS DEBUG

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
    
    # BepInEx/Doorstop configuration (only if mods enabled)
    if [[ "$ENABLE_MODS" == "true" ]]; then
        export DOORSTOP_ENABLE=TRUE
        export DOORSTOP_TARGET_ASSEMBLY="BepInEx/core/BepInEx.Unity.IL2CPP.dll"
        export DOORSTOP_DEBUG=1
        info "Doorstop: ENABLED (target: BepInEx.Unity.IL2CPP.dll)"
    else
        export DOORSTOP_ENABLE=FALSE
        info "Doorstop: DISABLED (ENABLE_MODS=false)"
    fi
    
    # .NET diagnostics
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    if [[ "$DEBUG" == "true" ]]; then
        export COMPlus_LogEnable=1
        export COMPlus_LogLevel=10
        export COREHOST_TRACE=1
        info "CoreCLR tracing: ENABLED"
    fi
    
    # Ensure winhttp.dll is lowercase (Wine DLL override requirement)
    if [ -f "$SERVER_DIR/WinHttp.dll" ]; then
        mv "$SERVER_DIR/WinHttp.dll" "$SERVER_DIR/winhttp.dll"
        ok "Renamed WinHttp.dll -> winhttp.dll"
    elif [ -f "$SERVER_DIR/winhttp.dll" ]; then
        debug "winhttp.dll already lowercase"
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

cleanup_mods() {
    info "Checking for mod artifacts to clean..."
    [[ "$ENABLE_MODS" == "true" ]] && return
    
    if [[ -f "$SERVER_DIR/winhttp.dll" || -d "$SERVER_DIR/BepInEx" ]]; then
        warn "Cleaning BepInEx artifacts..."
        rm -f "$SERVER_DIR/winhttp.dll"
        rm -f "$SERVER_DIR/doorstop_config.ini"
        rm -rf "$SERVER_DIR/BepInEx"
        find "$SERVER_DIR" -maxdepth 1 -name "preloader_*.log" -delete || true
        ok "Cleanup done"
    fi
}

install_mods() {
    if [[ "$ENABLE_MODS" == "true" && -d "/mnt/custom_mods" ]]; then
        info "Installing/Updating mods from /mnt/custom_mods..."
        # Copy everything from mount to server dir
        # We use force copy to ensure we have the latest version from host
        cp -rf /mnt/custom_mods/* "$SERVER_DIR/" || warn "Some files could not be copied"
        ok "Mods installed to $SERVER_DIR"
    fi
}

configure_settings() {
    info "Applying server settings..."
    local settings_dir="/data/save-data/Settings"
    local settings_file="$settings_dir/ServerHostSettings.json"
    
    mkdir -p "$settings_dir"
    [ -f "$settings_file" ] || echo '{}' > "$settings_file"
    
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
        update("GameSettingsPreset"; $gamePreset; str($gamePreset)) |
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

verify_bepinex() {
    section "BepInEx Verification"
    
    if [[ "$ENABLE_MODS" != "true" ]]; then
        info "Mods disabled - skipping BepInEx verification"
        return
    fi
    
    local bepinex_dir="$SERVER_DIR/BepInEx"
    local issues=0
    
    # Check core files
    info "Checking BepInEx installation..."
    
    if [ ! -d "$bepinex_dir" ]; then
        warn "BepInEx directory not found: $bepinex_dir"
        ((issues++))
    else
        ok "BepInEx directory exists"
        
        # Core DLL check
        local core_dll="$bepinex_dir/core/BepInEx.Unity.IL2CPP.dll"
        if [ -f "$core_dll" ]; then
            ok "Core DLL: $(basename "$core_dll") ($(stat -c%s "$core_dll") bytes)"
        else
            warn "Missing core DLL: $core_dll"
            ((issues++))
        fi
        
        # Doorstop proxy (winhttp.dll)
        if [ -f "$SERVER_DIR/winhttp.dll" ]; then
            ok "Doorstop proxy: winhttp.dll ($(stat -c%s "$SERVER_DIR/winhttp.dll") bytes)"
        else
            warn "Missing doorstop proxy: winhttp.dll"
            ((issues++))
        fi
        
        # doorstop_config.ini
        if [ -f "$SERVER_DIR/doorstop_config.ini" ]; then
            ok "Doorstop config: doorstop_config.ini"
            debug "$(head -10 "$SERVER_DIR/doorstop_config.ini")"
        else
            warn "Missing doorstop config: doorstop_config.ini"
            ((issues++))
        fi
        
        # CoreCLR (dotnet folder)
        local dotnet_dir="$SERVER_DIR/dotnet"
        if [ -d "$dotnet_dir" ]; then
            local coreclr="$dotnet_dir/coreclr.dll"
            if [ -f "$coreclr" ]; then
                ok "CoreCLR runtime: coreclr.dll ($(stat -c%s "$coreclr") bytes)"
            else
                warn "Missing CoreCLR: $coreclr"
                ((issues++))
            fi
        else
            warn "Missing dotnet directory: $dotnet_dir"
            ((issues++))
        fi
        
        # Interop assemblies (pre-generated for ARM64 compat)
        local interop_count
        interop_count=$(find "$bepinex_dir/interop" -name "*.dll" 2>/dev/null | wc -l)
        if [ "$interop_count" -gt 0 ]; then
            ok "Interop assemblies: $interop_count DLLs pre-generated"
        else
            warn "No interop assemblies found - first run may be slow/fail on ARM64"
        fi
        
        # Plugins
        local plugin_count
        plugin_count=$(find "$bepinex_dir/plugins" -name "*.dll" 2>/dev/null | wc -l)
        info "Plugins installed: $plugin_count"
    fi
    
    if [ $issues -gt 0 ]; then
        warn "BepInEx verification found $issues issue(s)"
    else
        ok "BepInEx verification passed"
    fi
}

dump_environment() {
    section "Environment Summary"
    
    info "Server: $SERVER_NAME"
    info "Ports: Game=$GAME_PORT, Query=$QUERY_PORT"
    info "Save: $SAVE_NAME"
    info "Mods: $ENABLE_MODS"
    info "Debug: $DEBUG"
    info "Wine prefix: $WINEPREFIX"
    info "Server dir: $SERVER_DIR"
    
    if [[ "$DEBUG" == "true" ]]; then
        info "--- Full Environment ---"
        env | grep -E '^(WINE|DOORSTOP|BEPINEX|COMPlus|DOTNET|CORE|SERVER|GAME|QUERY|SAVE|ENABLE)' | sort || true
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

main() {
    printf '\n\033[1;35m╔═══════════════════════════════════════════════════════════════╗\033[0m\n'
    printf '\033[1;35m║     V Rising Dedicated Server (ARM64/FEX) - Diagnostics       ║\033[0m\n'
    printf '\033[1;35m╚═══════════════════════════════════════════════════════════════╝\033[0m\n\n'
    
    info "Started at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    info "Architecture: $(uname -m)"
    
    mkdir -p "$SERVER_DIR" "$WINEPREFIX"
    
    setup_wine
    setup_steamcmd
    update_server
    install_mods
    cleanup_mods
    verify_bepinex
    configure_settings
    dump_environment
    pre_launch_checks
    
    section "Launching Server"
    info "Command: FEXInterpreter $WINE_BIN VRisingServer.exe"
    info "Log file: /data/VRisingServer.log"
    info "Press Ctrl+C to stop the server"
    printf '\033[0;90m%s\033[0m\n' "────────────────────────────────────────────────────────────────"
    
    cd "$SERVER_DIR"
    
    exec FEXInterpreter "$WINE_BIN" \
        VRisingServer.exe \
        -batchmode \
        -nographics \
        -persistentDataPath "Z:/data/save-data" \
        -serverName "$SERVER_NAME" \
        -saveName "$SAVE_NAME" \
        -logFile "Z:/data/VRisingServer.log" \
        -gamePort "$GAME_PORT" \
        -queryPort "$QUERY_PORT"
}

# Run main
main "$@"

