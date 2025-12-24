#!/bin/bash
# =============================================================================
# V Rising Dedicated Server - Entrypoint Script
# =============================================================================

# =============================================================================
# Cores para output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# Variáveis
# =============================================================================
STEAMCMD_DIR="/opt/steamcmd"
SERVER_DIR="${SERVER_DIR:-/data/server}"
SAVES_DIR="${SAVES_DIR:-/data/saves}"
SETTINGS_DIR="${SAVES_DIR}/Settings"
VRISING_APP_ID="${VRISING_APP_ID:-1829350}"

# Wine paths
export WINEPREFIX="${WINEPREFIX:-/data/wine}"
export WINEARCH="win64"
export WINEDEBUG="-all"
export DISPLAY=":0"

# Box settings
export BOX86_LOG=0
export BOX64_LOG=0
export BOX86_NOBANNER=1
export BOX64_NOBANNER=1
export BOX64_LD_LIBRARY_PATH="/opt/wine/lib64:/opt/wine/lib"

# Configurações do servidor
SERVER_NAME="${SERVER_NAME:-V Rising Server}"
WORLD_NAME="${WORLD_NAME:-world1}"
PASSWORD="${PASSWORD:-}"
MAX_USERS="${MAX_USERS:-40}"
GAME_PORT="${GAME_PORT:-9876}"
QUERY_PORT="${QUERY_PORT:-9877}"
LIST_ON_MASTER_SERVER="${LIST_ON_MASTER_SERVER:-false}"
LIST_ON_EOS="${LIST_ON_EOS:-false}"
GAME_MODE_TYPE="${GAME_MODE_TYPE:-PvP}"

# =============================================================================
# Funções
# =============================================================================

init_display() {
    log_info "Iniciando display virtual (Xvfb)..."
    
    pkill -9 Xvfb 2>/dev/null || true
    sleep 1
    
    Xvfb :0 -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 3
    
    if kill -0 ${XVFB_PID} 2>/dev/null; then
        log_success "Display virtual iniciado (PID: ${XVFB_PID})"
        return 0
    else
        log_error "Falha ao iniciar Xvfb!"
        return 1
    fi
}

init_wine() {
    log_info "Inicializando Wine prefix..."
    
    mkdir -p "${WINEPREFIX}"
    
    if [ -f "${WINEPREFIX}/system.reg" ]; then
        log_info "Wine prefix já existe em ${WINEPREFIX}"
        return 0
    fi
    
    log_info "Criando novo Wine prefix (isso pode demorar alguns minutos)..."
    
    # Usar box64 explicitamente para rodar wineboot
    if box64 /opt/wine/bin/wineboot --init 2>&1; then
        log_success "Wine prefix inicializado!"
        box64 /opt/wine/bin/wineserver -w 2>/dev/null || true
        sleep 3
        return 0
    else
        log_warning "Wineboot retornou com warnings..."
        sleep 10
        box64 /opt/wine/bin/wineserver -w 2>/dev/null || true
        
        if [ -f "${WINEPREFIX}/system.reg" ]; then
            log_success "Wine prefix funcional!"
            return 0
        else
            log_warning "Tentando criar prefix mínimo..."
            mkdir -p "${WINEPREFIX}/drive_c/windows/system32"
            mkdir -p "${WINEPREFIX}/drive_c/users/root"
            return 0
        fi
    fi
}

install_or_update_server() {
    log_info "Verificando instalação do servidor V Rising..."
    
    if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        log_info "Servidor encontrado. Verificando atualizações..."
    else
        log_info "Servidor não encontrado. Iniciando instalação..."
    fi
    
    log_info "Executando SteamCMD via Box86..."
    log_info "Baixando V Rising Dedicated Server (AppID: ${VRISING_APP_ID})..."
    log_info "Isso pode demorar de 5 a 15 minutos (~2GB)..."
    
    cd "${STEAMCMD_DIR}"
    
    local attempt=1
    local max_attempts=3
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Tentativa ${attempt} de ${max_attempts}..."
        
        # Executar SteamCMD via Box86 explicitamente
        box86 /opt/steamcmd/linux32/steamcmd \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "${SERVER_DIR}" \
            +login anonymous \
            +app_update ${VRISING_APP_ID} validate \
            +quit || true
        
        if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
            log_success "Servidor V Rising instalado/atualizado!"
            return 0
        fi
        
        log_warning "Tentativa ${attempt} não completou, aguardando..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        log_success "Servidor V Rising encontrado!"
        return 0
    else
        log_error "Não foi possível instalar o servidor."
        return 1
    fi
}

configure_server() {
    log_info "Configurando servidor..."
    
    mkdir -p "${SETTINGS_DIR}"
    
    HOST_SETTINGS_FILE="${SETTINGS_DIR}/ServerHostSettings.json"
    
    if [ ! -f "${HOST_SETTINGS_FILE}" ]; then
        log_info "Criando ServerHostSettings.json..."
        
        cat > "${HOST_SETTINGS_FILE}" << EOF
{
  "Name": "${SERVER_NAME}",
  "Description": "V Rising Dedicated Server on ARM64",
  "Port": ${GAME_PORT},
  "QueryPort": ${QUERY_PORT},
  "MaxConnectedUsers": ${MAX_USERS},
  "MaxConnectedAdmins": 4,
  "ServerFps": 30,
  "SaveName": "${WORLD_NAME}",
  "Password": "${PASSWORD}",
  "Secure": true,
  "ListOnMasterServer": ${LIST_ON_MASTER_SERVER},
  "ListOnEOS": ${LIST_ON_EOS},
  "AutoSaveCount": 25,
  "AutoSaveInterval": 120,
  "CompressSaveFiles": true,
  "GameSettingsPreset": "",
  "AdminOnlyDebugEvents": true,
  "DisableDebugEvents": false,
  "API": { "Enabled": false },
  "Rcon": { "Enabled": false, "Port": 25575, "Password": "" }
}
EOF
        log_success "ServerHostSettings.json criado!"
    else
        log_info "ServerHostSettings.json já existe."
    fi
    
    GAME_SETTINGS_FILE="${SETTINGS_DIR}/ServerGameSettings.json"
    
    if [ ! -f "${GAME_SETTINGS_FILE}" ]; then
        log_info "Criando ServerGameSettings.json..."
        
        cat > "${GAME_SETTINGS_FILE}" << EOF
{
  "GameModeType": "${GAME_MODE_TYPE}",
  "CastleDamageMode": "TimeRestricted",
  "SiegeWeaponHealth": "Normal",
  "PlayerDamageMode": "Always",
  "CastleHeartDamageMode": "CanBeDestroyedByPlayers",
  "PvPProtectionMode": "Medium",
  "DeathContainerPermission": "Anyone",
  "RelicSpawnType": "Unique",
  "CanLootEnemyContainers": true,
  "BloodBoundEquipment": true,
  "TeleportBoundItems": true,
  "AllowGlobalChat": true,
  "AllWaypointsUnlocked": false,
  "FreeCastleClaim": false,
  "FreeCastleDestroy": false,
  "InactivityKillEnabled": true,
  "InactivityKillTimeMin": 3600,
  "InactivityKillTimeMax": 604800,
  "InactivityKillSafeTimeAddition": 172800,
  "InactivityKillTimerMaxItemLevel": 84,
  "DisableDisconnectedDeadEnabled": true,
  "DisableDisconnectedDeadTimer": 60,
  "InventoryStacksModifier": 1.0,
  "DropTableModifier_General": 1.0,
  "DropTableModifier_Missions": 1.0,
  "MaterialYieldModifier_Global": 1.0,
  "BloodEssenceYieldModifier": 1.0,
  "JournalVBloodSourceUnitMaxDistance": 25.0,
  "PvPVampireRespawnModifier": 1.0,
  "CastleMinimumDistanceInFloors": 2,
  "ClanSize": 4,
  "BloodDrainModifier": 1.0,
  "DurabilityDrainModifier": 1.0,
  "GarlicAreaStrengthModifier": 1.0,
  "HolyAreaStrengthModifier": 1.0,
  "SilverStrengthModifier": 1.0,
  "SunDamageModifier": 1.0,
  "CastleDecayRateModifier": 1.0,
  "CastleBloodEssenceDrainModifier": 1.0,
  "CastleSiegeTimer": 420.0,
  "CastleUnderAttackTimer": 60.0,
  "AnnounceSiegeWeaponSpawn": true,
  "ShowSiegeWeaponMapIcon": false,
  "BuildCostModifier": 1.0,
  "RecipeCostModifier": 1.0,
  "CraftRateModifier": 1.0,
  "ResearchCostModifier": 1.0,
  "RefinementCostModifier": 1.0,
  "RefinementRateModifier": 1.0,
  "ResearchTimeModifier": 1.0,
  "DismantleResourceModifier": 0.75,
  "ServantConvertRateModifier": 1.0,
  "RepairCostModifier": 1.0,
  "Death_DurabilityFactorLoss": 0.25,
  "Death_DurabilityLossFactorAsResources": 1.0,
  "StarterEquipmentId": 0,
  "StarterResourcesId": 0
}
EOF
        log_success "ServerGameSettings.json criado!"
    else
        log_info "ServerGameSettings.json já existe."
    fi
}

start_server() {
    log_info "=============================================="
    log_info "Iniciando servidor V Rising..."
    log_info "=============================================="
    log_info "Server Name: ${SERVER_NAME}"
    log_info "World Name: ${WORLD_NAME}"
    log_info "Game Port: ${GAME_PORT}"
    log_info "Query Port: ${QUERY_PORT}"
    log_info "Max Users: ${MAX_USERS}"
    log_info "Game Mode: ${GAME_MODE_TYPE}"
    log_info "=============================================="
    
    cd "${SERVER_DIR}"
    
    log_info "Executando VRisingServer.exe via Box64 + Wine..."
    
    # Executar via box64 explicitamente
    exec box64 /opt/wine/bin/wine64 "${SERVER_DIR}/VRisingServer.exe" \
        -persistentDataPath "${SAVES_DIR}" \
        -serverName "${SERVER_NAME}" \
        -saveName "${WORLD_NAME}" \
        -logFile "/data/logs/VRisingServer.log"
}

# =============================================================================
# Tratamento de sinais
# =============================================================================
shutdown_server() {
    log_warning "Recebido sinal de shutdown..."
    box64 /opt/wine/bin/wineserver -k 2>/dev/null || true
    pkill -9 Xvfb 2>/dev/null || true
    log_success "Servidor finalizado!"
    exit 0
}

trap shutdown_server SIGTERM SIGINT SIGHUP

# =============================================================================
# Main
# =============================================================================

log_info "=============================================="
log_info " V Rising Dedicated Server - ARM64"
log_info "=============================================="
log_info "Timezone: ${TZ}"
log_info "Server Directory: ${SERVER_DIR}"
log_info "Saves Directory: ${SAVES_DIR}"
log_info "=============================================="

ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime 2>/dev/null || true

mkdir -p "${SERVER_DIR}" "${SAVES_DIR}" "${WINEPREFIX}" /data/logs

init_display || exit 1

init_wine || log_warning "Continuando..."

install_or_update_server || exit 1

configure_server

start_server
