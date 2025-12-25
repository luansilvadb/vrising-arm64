#!/bin/bash
# =============================================================================
# BepInEx Setup Script for V Rising ARM64 (tsx-cloud approach)
# =============================================================================
# Este script configura o BepInEx no servidor V Rising.
# DIFERENÇA CHAVE: Usa arquivos BepInEx pré-packaged incluindo assemblies 
# interop pré-gerados, evitando o problema de Il2CppInterop no ARM64/Box64.
#
# Baseado em: https://github.com/tsx-cloud/vrising-ntsync
# =============================================================================

# Cores para logs
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_bepinex() { echo -e "${CYAN}[BEPINEX]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }

# Diretórios
SERVER_DIR="${SERVER_DIR:-/data/server}"
BEPINEX_DIR="${SERVER_DIR}/BepInEx"
BEPINEX_DEFAULTS="/scripts/bepinex/server"

# =============================================================================
# ABORDAGEM TSX-CLOUD:
# Os arquivos BepInEx (incluindo interop pré-gerado) são copiados do 
# /scripts/bepinex/server/ que foi incluído na imagem Docker durante o build.
# Isso evita completamente o problema de Il2CppInterop travando no ARM64.
# =============================================================================

verify_bepinex_installation() {
    # Verificar TODOS os arquivos críticos
    local missing_files=""
    
    if [ ! -f "${SERVER_DIR}/winhttp.dll" ]; then
        missing_files="${missing_files} winhttp.dll"
    fi
    
    if [ ! -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        missing_files="${missing_files} doorstop_config.ini"
    fi
    
    if [ ! -f "${BEPINEX_DIR}/core/BepInEx.Unity.IL2CPP.dll" ]; then
        missing_files="${missing_files} BepInEx.Unity.IL2CPP.dll"
    fi
    
    # Verificar se dotnet existe (pode estar em server/dotnet ou BepInEx/dotnet)
    if [ ! -d "${SERVER_DIR}/dotnet" ] && [ ! -f "${SERVER_DIR}/dotnet/coreclr.dll" ]; then
        if [ ! -d "${BEPINEX_DIR}/core/dotnet" ]; then
            missing_files="${missing_files} dotnet/"
        fi
    fi
    
    if [ -n "${missing_files}" ]; then
        log_warning "BepInEx incomplete! Missing:${missing_files}"
        return 1
    fi
    
    return 0
}

setup_bepinex() {
    log_bepinex "=============================================="
    log_bepinex "Setting up BepInEx for V Rising (Safe Generation Mode)"
    log_bepinex "=============================================="
    
    # Verificar se instalação está COMPLETA
    if verify_bepinex_installation; then
        log_bepinex "BepInEx installation verified complete!"
    else
        log_bepinex "BepInEx needs installation/repair..."
        
        # =========================================================================
        # PASSO 1: Instalar Arquivos Base (Core)
        # =========================================================================
        
        # Opção A: Copiar de defaults (se existirem na imagem)
        if [ -d "${BEPINEX_DEFAULTS}" ] && [ -f "${BEPINEX_DEFAULTS}/core/BepInEx.Unity.IL2CPP.dll" ]; then
            log_bepinex "Copying BepInEx from local defaults..."
            cp -r "${BEPINEX_DEFAULTS}/." "${SERVER_DIR}/"
            log_success "BepInEx core files installed from image."
            
        # Opção B: Baixar do GitHub (Fallback)
        else
            log_warning "Local BepInEx defaults not found. Downloading v6.0.0-pre.1..."
            
            local BEPINEX_VERSION="6.0.0-pre.1"
            # URL para BepInEx Unity IL2CPP Windows x64
            local BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx-Unity.IL2CPP-win-x64-${BEPINEX_VERSION}.zip"
            
            cd /tmp
            wget -q "${BEPINEX_URL}" -O bepinex.zip
            
            if [ -f "bepinex.zip" ]; then
                mkdir -p bepinex_extract
                unzip -q -o bepinex.zip -d bepinex_extract
                
                # Criar estrutura se não existir
                mkdir -p "${BEPINEX_DIR}"
                
                # Mover arquivos para o servidor
                cp -r bepinex_extract/BepInEx/* "${BEPINEX_DIR}/"
                cp bepinex_extract/winhttp.dll "${SERVER_DIR}/"
                cp bepinex_extract/doorstop_config.ini "${SERVER_DIR}/" || true
                
                # Copiar dotnet runtime se existir
                if [ -d "bepinex_extract/dotnet" ]; then
                    cp -r bepinex_extract/dotnet "${SERVER_DIR}/"
                fi
                
                # Limpeza
                rm -rf bepinex.zip bepinex_extract
                log_success "BepInEx downloaded and installed successfully."
            else
                log_error "Failed to download BepInEx!"
                return 1
            fi
        fi

        # Garantir doorstop_config correto
        if [ ! -f "${SERVER_DIR}/doorstop_config.ini" ] && [ -f "/scripts/bepinex/doorstop_config.ini" ]; then
            cp "/scripts/bepinex/doorstop_config.ini" "${SERVER_DIR}/doorstop_config.ini"
        fi
    fi
    # =========================================================================
    # O problema: Il2CppInterop trava no Box64 (JIT) ao gerar assemblies.
    # A solução: Detectamos se a pasta 'interop' está vazia. Se estiver,
    # forçamos uma execução temporária com o JIT DESLIGADO (BOX64_DYNAREC=0).
    # Isso é lento, mas 100% estável e não trava.
    # =========================================================================
    
    if [ ! -d "${BEPINEX_DIR}/interop" ] || [ -z "$(ls -A ${BEPINEX_DIR}/interop 2>/dev/null)" ]; then
        log_warning "BepInEx interop assemblies missing!"
        log_bepinex "initiating SAFE GENERATION MODE (Interpreter-only)..."
        log_bepinex "This will take 3-5 minutes. Please wait..."

        # Definir flags para desabilitar JIT completamente
        export BOX64_DYNAREC=0
        export BOX64_LOG=1 # Ver logs básicos
        
        # Executar servidor temporariamente (vai falhar/timeout mas vai gerar os arquivos)
        # Usamos timeout de 300s (5 min) para garantir que dê tempo
        cd "${SERVER_DIR}"
        
        # Iniciar servidor em background
        # Nota: Não precisamos do Xvfb completo aqui, só do Wine bootando BepInEx
        # Mas mantemos ambiente consistente
        if command -v wine64 &>/dev/null; then WINE_CMD="wine64"; else WINE_CMD="wine"; fi
        
        log_bepinex "Starting V Rising in INTERPRETER mode to generate assemblies..."
        timeout 300s ${WINE_CMD} "${SERVER_DIR}/VRisingServer.exe" \
            -serverName "BepInEx_Generation_Temp" \
            -saveName "generation_temp" \
            -logFile "${SERVER_DIR}/generation.log" &
            
        GEN_PID=$!
        
        # Monitorar geração
        log_bepinex "Monitoring generation (PID: ${GEN_PID})..."
        local generated=false
        
        for i in $(seq 1 60); do
            sleep 5
            if [ -d "${BEPINEX_DIR}/interop" ] && [ "$(ls -A ${BEPINEX_DIR}/interop | wc -l)" -gt 5 ]; then
                log_success "Interop assemblies detected! Generation seems successful."
                generated=true
                break
            fi
            echo -n "."
        done
        
        # Matar processo de geração
        log_bepinex "Stopping generation process..."
        kill -SIGTERM $GEN_PID 2>/dev/null || true
        kill -9 $GEN_PID 2>/dev/null || true
        wineserver -k 2>/dev/null || true
        
        # Limpar variaveis
        unset BOX64_DYNAREC
        export BOX64_DYNAREC=1
        
        if [ "$generated" = "true" ]; then
             log_success "Safe generation complete!"
        else
             log_error "Generation might have failed or verify on next boot."
        fi
    else
        log_bepinex "Interop assemblies already present. Skipping generation."
    fi
}


enable_plugins() {
    log_bepinex "Enabling BepInEx plugins..."
    
    # Atualizar doorstop_config.ini (como tsx-cloud faz)
    if [ -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        sed -i "s/^enabled *=.*/enabled = true/" "${SERVER_DIR}/doorstop_config.ini"
        log_success "Plugins ENABLED in doorstop_config.ini"
    else
        log_warning "doorstop_config.ini not found!"
    fi
    
    # Configurar Wine DLL override (EXATAMENTE como tsx-cloud faz)
    # tsx-cloud usa APENAS winhttp=n,b quando plugins estão habilitados
    export WINEDLLOVERRIDES="winhttp=n,b"
    log_bepinex "WINEDLLOVERRIDES=${WINEDLLOVERRIDES}"
}

disable_plugins() {
    log_bepinex "Disabling BepInEx plugins..."
    
    if [ -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        sed -i "s/^enabled *=.*/enabled = false/" "${SERVER_DIR}/doorstop_config.ini"
        log_bepinex "Plugins DISABLED in doorstop_config.ini"
    fi
}

# Função principal chamada pelo entrypoint
setup_bepinex_if_enabled() {
    ENABLE_PLUGINS="${ENABLE_PLUGINS:-false}"
    
    log_bepinex "ENABLE_PLUGINS=${ENABLE_PLUGINS}"
    
    if [ "${ENABLE_PLUGINS}" = "true" ]; then
        setup_bepinex
        enable_plugins
    else
        # Mesmo desabilitado, garantir que doorstop está disabled
        if [ -f "${SERVER_DIR}/doorstop_config.ini" ]; then
            disable_plugins
        fi
        log_bepinex "Plugins support is DISABLED"
    fi
}

# Exportar funções
export -f setup_bepinex
export -f enable_plugins
export -f disable_plugins
export -f setup_bepinex_if_enabled
