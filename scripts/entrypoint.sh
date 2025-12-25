#!/bin/bash
# =============================================================================
# V Rising Dedicated Server - Entrypoint Script (FAST VERSION)
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }

# =============================================================================
# Variáveis
# =============================================================================
STEAMCMD_DIR="/opt/steamcmd"
SERVER_DIR="${SERVER_DIR:-/data/server}"
SAVES_DIR="${SAVES_DIR:-/data/saves}"
SETTINGS_DIR="${SAVES_DIR}/Settings"
VRISING_APP_ID="${VRISING_APP_ID:-1829350}"

# Wine - DESABILITAR MONO E GECKO para acelerar
export WINEPREFIX="${WINEPREFIX:-/data/wine}"
export WINEARCH="win64"
export WINEDEBUG="-all"
# dnsapi=b força uso de builtin para evitar erro __res_query
export WINEDLLOVERRIDES="mscoree=d;mshtml=d;dnsapi=b"
export DISPLAY=":0"

# Box settings
export BOX86_LOG=0
export BOX64_LOG=0
export BOX86_NOBANNER=1
export BOX64_NOBANNER=1
export BOX64_LD_LIBRARY_PATH="/opt/wine/lib64:/opt/wine/lib"

# Configurações do servidor
SERVER_NAME="${SERVER_NAME:-V Rising Server}"
SERVER_DESCRIPTION="${SERVER_DESCRIPTION:-Servidor dedicado brasileiro}"
WORLD_NAME="${WORLD_NAME:-world1}"
PASSWORD="${PASSWORD:-}"
MAX_USERS="${MAX_USERS:-40}"
MAX_ADMINS="${MAX_ADMINS:-5}"
SERVER_FPS="${SERVER_FPS:-60}"
GAME_DIFFICULTY_PRESET="${GAME_DIFFICULTY_PRESET:-Difficulty_Brutal}"
GAME_PORT="${GAME_PORT:-9876}"
QUERY_PORT="${QUERY_PORT:-9877}"
LIST_ON_MASTER_SERVER="${LIST_ON_MASTER_SERVER:-false}"
LIST_ON_EOS="${LIST_ON_EOS:-false}"
AUTO_SAVE_COUNT="${AUTO_SAVE_COUNT:-25}"
AUTO_SAVE_INTERVAL="${AUTO_SAVE_INTERVAL:-120}"
COMPRESS_SAVE_FILES="${COMPRESS_SAVE_FILES:-true}"
RCON_ENABLED="${RCON_ENABLED:-true}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-}"
AUTO_UPDATE="${AUTO_UPDATE:-true}"
TZ="${TZ:-America/Sao_Paulo}"

# BepInEx (Suporte a Mods)
BEPINEX_ENABLED="${BEPINEX_ENABLED:-false}"

# =============================================================================
# Funções
# =============================================================================

init_display() {
    log_info "Iniciando display virtual (Xvfb)..."
    pkill -9 Xvfb 2>/dev/null || true
    sleep 1
    Xvfb :0 -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 2
    if kill -0 ${XVFB_PID} 2>/dev/null; then
        log_success "Display virtual iniciado (PID: ${XVFB_PID})"
        return 0
    else
        log_error "Falha ao iniciar Xvfb!"
        return 1
    fi
}

init_wine_fast() {
    log_info "Inicializando Wine prefix (modo rápido)..."
    mkdir -p "${WINEPREFIX}"
    
    if [ -f "${WINEPREFIX}/system.reg" ]; then
        log_info "Wine prefix já existe"
        return 0
    fi
    
    log_info "Criando Wine prefix mínimo..."
    
    # Criar estrutura mínima do Wine prefix manualmente (MUITO mais rápido)
    mkdir -p "${WINEPREFIX}/drive_c/windows/system32"
    mkdir -p "${WINEPREFIX}/drive_c/windows/syswow64"
    mkdir -p "${WINEPREFIX}/drive_c/users/root/Temp"
    mkdir -p "${WINEPREFIX}/drive_c/Program Files"
    mkdir -p "${WINEPREFIX}/drive_c/Program Files (x86)"
    
    # Tentar inicializar Wine rapidamente (timeout de 30s)
    log_info "Executando wineboot (timeout 60s)..."
    timeout 60 box64 /opt/wine/bin/wineboot --init 2>&1 &
    WINEBOOT_PID=$!
    
    # Aguardar um pouco e depois matar se ainda estiver rodando
    sleep 10
    
    # Verificar se criou os arquivos básicos
    if [ -d "${WINEPREFIX}/drive_c/windows" ]; then
        log_success "Wine prefix básico criado!"
        # Matar processos Wine extras se ainda estiverem rodando
        box64 /opt/wine/bin/wineserver -k 2>/dev/null || true
        sleep 2
        return 0
    fi
    
    log_warning "Continuando sem Wine prefix completo..."
    return 0
}

install_or_update_server() {
    log_info "Verificando instalação do servidor V Rising..."
    
    local needs_download=false
    
    if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        if [ "${AUTO_UPDATE}" = "true" ]; then
            log_info "Servidor instalado. Verificando atualizações..."
        else
            log_success "Servidor já instalado! (AUTO_UPDATE=false, pulando verificação)"
            return 0
        fi
    else
        log_info "Servidor não encontrado. Iniciando download..."
        needs_download=true
    fi
    
    log_info "Executando SteamCMD via Box86..."
    if [ "$needs_download" = "true" ]; then
        log_info "Download de ~2GB - isso pode demorar 5-15 minutos..."
    fi
    
    cd "${STEAMCMD_DIR}"
    
    local attempt=1
    local max_attempts=3  # Reduzido: SteamCMD já está pré-inicializado no build
    
    while [ $attempt -le $max_attempts ]; do
        if [ $attempt -le 2 ]; then
            log_info "Inicializando SteamCMD (etapa ${attempt}/2)..."
        else
            log_info "Tentativa ${attempt} de ${max_attempts}..."
        fi
        
        # Mostrar toda a saída do SteamCMD para debug
        # Ordem correta: force_install_dir -> login -> app_update -> quit
        box86 /opt/steamcmd/linux32/steamcmd \
            +force_install_dir "${SERVER_DIR}" \
            +@sSteamCmdForcePlatformType windows \
            +login anonymous \
            +app_update ${VRISING_APP_ID} validate \
            +quit
        
        if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
            log_success "Servidor V Rising instalado!"
            return 0
        fi
        
        # Mensagens mais claras sobre o que está acontecendo
        if [ $attempt -le 2 ]; then
            log_info "SteamCMD atualizando-se, continuando..."
        else
            log_warning "Tentativa ${attempt} não completou download, retentando..."
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        log_success "Servidor V Rising encontrado!"
        return 0
    else
        log_error "Falha ao instalar servidor."
        return 1
    fi
}

configure_server() {
    log_info "Configurando servidor..."
    mkdir -p "${SETTINGS_DIR}"
    
    # Diretório com templates de configuração
    CONFIG_TEMPLATES="/scripts/config"
    
    # =========================================================================
    # ServerHostSettings.json - Sempre atualiza com variáveis de ambiente
    # =========================================================================
    log_info "Atualizando ServerHostSettings.json..."
    
    # Usar template como base e substituir valores com jq
    if [ -f "${CONFIG_TEMPLATES}/ServerHostSettings.json" ]; then
        jq --arg name "${SERVER_NAME}" \
           --arg desc "${SERVER_DESCRIPTION}" \
           --argjson port "${GAME_PORT}" \
           --argjson qport "${QUERY_PORT}" \
           --argjson maxusers "${MAX_USERS}" \
           --argjson maxadmins "${MAX_ADMINS}" \
           --argjson fps "${SERVER_FPS}" \
           --arg save "${WORLD_NAME}" \
           --arg pass "${PASSWORD}" \
           --argjson master "${LIST_ON_MASTER_SERVER}" \
           --argjson eos "${LIST_ON_EOS}" \
           --arg diff "${GAME_DIFFICULTY_PRESET}" \
           --argjson autosave_count "${AUTO_SAVE_COUNT}" \
           --argjson autosave_interval "${AUTO_SAVE_INTERVAL}" \
           --argjson compress_saves "${COMPRESS_SAVE_FILES}" \
           --argjson rcon_enabled "${RCON_ENABLED}" \
           --argjson rcon_port "${RCON_PORT}" \
           --arg rcon_pass "${RCON_PASSWORD}" \
           '.Name = $name |
            .Description = $desc |
            .Port = $port |
            .QueryPort = $qport |
            .MaxConnectedUsers = $maxusers |
            .MaxConnectedAdmins = $maxadmins |
            .ServerFps = $fps |
            .SaveName = $save |
            .Password = $pass |
            .ListOnMasterServer = $master |
            .ListOnEOS = $eos |
            .GameDifficultyPreset = $diff |
            .AutoSaveCount = $autosave_count |
            .AutoSaveInterval = $autosave_interval |
            .CompressSaveFiles = $compress_saves |
            .Rcon.Enabled = $rcon_enabled |
            .Rcon.Port = $rcon_port |
            .Rcon.Password = $rcon_pass' \
           "${CONFIG_TEMPLATES}/ServerHostSettings.json" > "${SETTINGS_DIR}/ServerHostSettings.json"
        log_success "ServerHostSettings.json atualizado (template + variáveis)!"
    else
        log_warning "Template ServerHostSettings.json não encontrado, criando básico..."
        cat > "${SETTINGS_DIR}/ServerHostSettings.json" << EOF
{
  "Name": "${SERVER_NAME}",
  "Description": "${SERVER_DESCRIPTION}",
  "Port": ${GAME_PORT},
  "QueryPort": ${QUERY_PORT},
  "MaxConnectedUsers": ${MAX_USERS},
  "MaxConnectedAdmins": ${MAX_ADMINS},
  "ServerFps": ${SERVER_FPS},
  "SaveName": "${WORLD_NAME}",
  "Password": "${PASSWORD}",
  "Secure": true,
  "ListOnMasterServer": ${LIST_ON_MASTER_SERVER},
  "ListOnEOS": ${LIST_ON_EOS},
  "AutoSaveCount": ${AUTO_SAVE_COUNT},
  "AutoSaveInterval": ${AUTO_SAVE_INTERVAL},
  "CompressSaveFiles": ${COMPRESS_SAVE_FILES},
  "GameSettingsPreset": "",
  "GameDifficultyPreset": "${GAME_DIFFICULTY_PRESET}",
  "AdminOnlyDebugEvents": true,
  "DisableDebugEvents": false,
  "API": { "Enabled": false },
  "Rcon": { "Enabled": ${RCON_ENABLED}, "Port": ${RCON_PORT}, "Password": "${RCON_PASSWORD}" }
}
EOF
    fi
    
    # =========================================================================
    # ServerGameSettings.json - Só copia se não existir (File Mount tem prioridade)
    # =========================================================================
    if [ -f "${SETTINGS_DIR}/ServerGameSettings.json" ]; then
        log_info "ServerGameSettings.json existente - usando configuração atual (File Mount)"
    else
        if [ -f "${CONFIG_TEMPLATES}/ServerGameSettings.json" ]; then
            log_info "Copiando ServerGameSettings.json do template..."
            cp "${CONFIG_TEMPLATES}/ServerGameSettings.json" "${SETTINGS_DIR}/ServerGameSettings.json"
            log_success "ServerGameSettings.json copiado do template!"
        else
            log_warning "Template ServerGameSettings.json não encontrado!"
        fi
    fi
}

# =============================================================================
# BepInEx - Suporte a Mods
# =============================================================================
install_bepinex() {
    if [ "${BEPINEX_ENABLED}" != "true" ]; then
        log_info "BepInEx desabilitado (BEPINEX_ENABLED=${BEPINEX_ENABLED})"
        return 0
    fi
    
    log_info "=============================================="
    log_info "Instalando/verificando BepInEx..."
    log_info "=============================================="
    
    BEPINEX_SOURCE="/opt/bepinex/BepInExPack_V_Rising"
    
    # Verificar se BepInExPack existe
    if [ ! -d "${BEPINEX_SOURCE}" ]; then
        log_error "BepInExPack não encontrado em ${BEPINEX_SOURCE}"
        log_error "Verifique se o Docker image foi construído corretamente"
        return 1
    fi
    
    # Copiar winhttp.dll (hook do Doorstop) - necessário para BepInEx injetar
    if [ ! -f "${SERVER_DIR}/winhttp.dll" ]; then
        log_info "Copiando winhttp.dll..."
        cp "${BEPINEX_SOURCE}/winhttp.dll" "${SERVER_DIR}/"
    fi
    
    # Copiar doorstop_config.ini
    if [ ! -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        log_info "Copiando doorstop_config.ini..."
        cp "${BEPINEX_SOURCE}/doorstop_config.ini" "${SERVER_DIR}/"
    fi
    
    # Copiar .doorstop_version
    if [ ! -f "${SERVER_DIR}/.doorstop_version" ]; then
        cp "${BEPINEX_SOURCE}/.doorstop_version" "${SERVER_DIR}/" 2>/dev/null || true
    fi
    
    # Copiar dotnet runtime (necessário para BepInEx 6.x)
    if [ ! -d "${SERVER_DIR}/dotnet" ]; then
        log_info "Copiando .NET runtime..."
        cp -r "${BEPINEX_SOURCE}/dotnet" "${SERVER_DIR}/"
    fi
    
    # Criar estrutura do BepInEx
    mkdir -p "${SERVER_DIR}/BepInEx/plugins"
    mkdir -p "${SERVER_DIR}/BepInEx/config"
    mkdir -p "${SERVER_DIR}/BepInEx/patchers"
    
    # Copiar BepInEx core (não sobrescrever se já existir)
    if [ ! -d "${SERVER_DIR}/BepInEx/core" ]; then
        log_info "Copiando BepInEx core..."
        cp -r "${BEPINEX_SOURCE}/BepInEx/core" "${SERVER_DIR}/BepInEx/"
    fi
    
    # Copiar config padrão se não existir
    if [ ! -f "${SERVER_DIR}/BepInEx/config/BepInEx.cfg" ]; then
        log_info "Copiando configuração padrão do BepInEx..."
        cp -r "${BEPINEX_SOURCE}/BepInEx/config/"* "${SERVER_DIR}/BepInEx/config/" 2>/dev/null || true
    fi
    
    # Copiar mods do diretório /data/mods para BepInEx/plugins
    mkdir -p /data/mods
    if [ "$(ls -A /data/mods 2>/dev/null)" ]; then
        log_info "Copiando mods de /data/mods para BepInEx/plugins..."
        cp -r /data/mods/* "${SERVER_DIR}/BepInEx/plugins/" 2>/dev/null || true
        
        # Listar mods instalados
        log_info "Mods instalados:"
        ls -la "${SERVER_DIR}/BepInEx/plugins/" | grep -E '\.dll$' | while read line; do
            log_info "  → $(echo $line | awk '{print $NF}')"
        done
    else
        log_info "Nenhum mod encontrado em /data/mods"
    fi
    
    log_success "BepInEx configurado!"
    log_warning "NOTA: A primeira inicialização com BepInEx pode demorar 5-10 min!"
    log_warning "      BepInEx precisa gerar cache de interoperabilidade."
}

start_server() {
    log_info "=============================================="
    log_info "Iniciando servidor V Rising..."
    log_info "=============================================="
    log_info "Server Name: ${SERVER_NAME}"
    log_info "Game Port: ${GAME_PORT} | Query Port: ${QUERY_PORT}"
    log_info "Max Users: ${MAX_USERS} | Max Admins: ${MAX_ADMINS}"
    log_info "Difficulty: ${GAME_DIFFICULTY_PRESET} 💀"
    log_info "=============================================="
    
    cd "${SERVER_DIR}"
    
    # Verificar se os arquivos existem
    if [ ! -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        log_error "VRisingServer.exe não encontrado!"
        exit 1
    fi
    
    if [ ! -f "/opt/wine/bin/wine" ]; then
        log_error "wine não encontrado em /opt/wine/bin/"
        ls -la /opt/wine/bin/ 2>/dev/null || log_error "Diretório /opt/wine/bin/ não existe"
        exit 1
    fi
    
    log_info "Executando VRisingServer.exe via Box64 + Wine..."
    log_info "Wine: /opt/wine/bin/wine"
    log_info "Server: ${SERVER_DIR}/VRisingServer.exe"
    
    # Adicionar /opt/wine/bin ao PATH para Box64 encontrar
    export PATH="/opt/wine/bin:${PATH}"
    export BOX64_PATH="/opt/wine/bin:/usr/local/bin:/usr/bin"
    
    # Executar via box64 com caminho completo (usar wine, não wine64 - WOW64 é unificado)
    exec /usr/local/bin/box64 /opt/wine/bin/wine "${SERVER_DIR}/VRisingServer.exe" \
        -persistentDataPath "${SAVES_DIR}" \
        -serverName "${SERVER_NAME}" \
        -saveName "${WORLD_NAME}" \
        -logFile "/data/logs/VRisingServer.log"
}

shutdown_server() {
    log_warning "Shutdown..."
    box64 /opt/wine/bin/wineserver -k 2>/dev/null || true
    pkill -9 Xvfb 2>/dev/null || true
    exit 0
}

trap shutdown_server SIGTERM SIGINT SIGHUP

# =============================================================================
# Main
# =============================================================================

log_info "=============================================="
log_info " V Rising Dedicated Server - ARM64 (FAST)"
log_info "=============================================="
log_info "Server: ${SERVER_DIR} | Saves: ${SAVES_DIR}"
log_info "=============================================="

ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime 2>/dev/null || true
mkdir -p "${SERVER_DIR}" "${SAVES_DIR}" "${WINEPREFIX}" /data/logs

init_display || exit 1
init_wine_fast
install_or_update_server || exit 1
configure_server
install_bepinex
start_server
