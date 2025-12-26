#!/bin/bash
set -euo pipefail

# Logging: log <level> <message> | Levels: INFO(34), WARN(33), ERROR(31), OK(32)
log() { printf '\033[1;%sm[%s]\033[0m %s\n' "$1" "$2" "$3"; }
info() { log 34 INFO "$1"; }
warn() { log 33 WARN "$1"; }
fail() { log 31 FAIL "$1"; exit 1; }
ok()   { log 32 OK "$1"; }

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

export APP_ID SERVER_DIR STEAMCMD_DIR STEAMCMD_ORIG UPDATE_ON_START
export WINE_BIN WINEPREFIX WINEARCH=win64 DISPLAY=:0
export SERVER_NAME SAVE_NAME GAME_PORT QUERY_PORT ENABLE_MODS

setup_wine() {
    info "Configuring Wine..."
    rm -f /tmp/.X0-lock
    Xvfb :0 -screen 0 1024x768x16 &
    
    for _ in $(seq 1 50); do [ -e /tmp/.X11-unix/X0 ] && break; sleep 0.1; done
    [ -e /tmp/.X11-unix/X0 ] && ok "Xvfb ready" || warn "Xvfb socket not found"
    
    export WINEDLLOVERRIDES="mscoree,mshtml=;winhttp=n,b"
    export DOORSTOP_ENABLE=TRUE
    export DOORSTOP_TARGET_ASSEMBLY="BepInEx/core/BepInEx.Unity.IL2CPP.dll"
    
    # Debug: Enable verbose logging
    export WINEDEBUG="+loaddll,+module"
    export DOORSTOP_DEBUG=1
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export COMPlus_LogEnable=1
    export COMPlus_LogLevel=10
    
    # Force lowercase for critical dlls to ensure Wine overrides work
    # We use a temporary name to avoid "same file" error
    if [ -f "$SERVER_DIR/winhttp.dll" ]; then 
        mv "$SERVER_DIR/winhttp.dll" "$SERVER_DIR/winhttp.dll.tmp" && mv "$SERVER_DIR/winhttp.dll.tmp" "$SERVER_DIR/winhttp.dll"
    elif [ -f "$SERVER_DIR/WinHttp.dll" ]; then
        mv "$SERVER_DIR/WinHttp.dll" "$SERVER_DIR/winhttp.dll"
    fi
    
    if [ ! -d "$WINEPREFIX/drive_c" ]; then
        info "Initializing Wine prefix..."
        mkdir -p "$WINEPREFIX"
        FEXInterpreter "$WINE_BIN" wineboot --init 2>/dev/null || true
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

# Main
info ">>> V Rising Server (ARM64/FEX) <<<"

mkdir -p "$SERVER_DIR" "$WINEPREFIX"

setup_wine
setup_steamcmd
update_server
install_mods
cleanup_mods
configure_settings

info "Launching VRisingServer.exe..."
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
