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
export WINEDLLOVERRIDES="mscoree=d;mshtml=d"
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
    
    if [ -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        log_success "Servidor já instalado!"
        return 0
    fi
    
    log_info "Servidor não encontrado. Iniciando download..."
    log_info "Executando SteamCMD via Box86..."
    log_info "Download de ~2GB - isso pode demorar 5-15 minutos..."
    
    cd "${STEAMCMD_DIR}"
    
    local attempt=1
    local max_attempts=5
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Tentativa ${attempt} de ${max_attempts}..."
        
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
        
        log_warning "Tentativa ${attempt} falhou, aguardando..."
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
    
    if [ ! -f "${SETTINGS_DIR}/ServerHostSettings.json" ]; then
        log_info "Criando ServerHostSettings.json..."
        cat > "${SETTINGS_DIR}/ServerHostSettings.json" << EOF
{
  "Name": "${SERVER_NAME}",
  "Description": "V Rising Server on ARM64",
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
    fi
    
    if [ ! -f "${SETTINGS_DIR}/ServerGameSettings.json" ]; then
        log_info "Criando ServerGameSettings.json..."
        cat > "${SETTINGS_DIR}/ServerGameSettings.json" << EOF
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
    fi
}

start_server() {
    log_info "=============================================="
    log_info "Iniciando servidor V Rising..."
    log_info "=============================================="
    log_info "Server Name: ${SERVER_NAME}"
    log_info "Game Port: ${GAME_PORT} | Query Port: ${QUERY_PORT}"
    log_info "Max Users: ${MAX_USERS} | Game Mode: ${GAME_MODE_TYPE}"
    log_info "=============================================="
    
    cd "${SERVER_DIR}"
    
    # Verificar se os arquivos existem
    if [ ! -f "${SERVER_DIR}/VRisingServer.exe" ]; then
        log_error "VRisingServer.exe não encontrado!"
        exit 1
    fi
    
    if [ ! -f "/opt/wine/bin/wine64" ]; then
        log_error "wine64 não encontrado em /opt/wine/bin/"
        ls -la /opt/wine/bin/ 2>/dev/null || log_error "Diretório /opt/wine/bin/ não existe"
        exit 1
    fi
    
    log_info "Executando VRisingServer.exe via Box64 + Wine..."
    log_info "Wine: /opt/wine/bin/wine64"
    log_info "Server: ${SERVER_DIR}/VRisingServer.exe"
    
    # Adicionar /opt/wine/bin ao PATH para Box64 encontrar
    export PATH="/opt/wine/bin:${PATH}"
    export BOX64_PATH="/opt/wine/bin:/usr/local/bin:/usr/bin"
    
    # Executar via box64 com caminho completo
    exec /usr/local/bin/box64 /opt/wine/bin/wine64 "${SERVER_DIR}/VRisingServer.exe" \
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
start_server
