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
    log_bepinex "Setting up BepInEx for V Rising (tsx-cloud approach)"
    log_bepinex "=============================================="
    
    # Verificar se instalação está COMPLETA
    if verify_bepinex_installation; then
        log_bepinex "BepInEx installation verified complete!"
        return 0
    fi
    
    log_bepinex "BepInEx needs installation/repair..."
    
    # =========================================================================
    # MÉTODO 1: Copiar de defaults pré-packaged (como tsx-cloud)
    # =========================================================================
    if [ -d "${BEPINEX_DEFAULTS}" ] && [ -f "${BEPINEX_DEFAULTS}/winhttp.dll" ]; then
        log_bepinex "Copying BepInEx from pre-packaged defaults..."
        
        # Copiar tudo do defaults para o server
        cp -r "${BEPINEX_DEFAULTS}/." "${SERVER_DIR}/"
        
        log_success "BepInEx copied from defaults!"
        
    # =========================================================================
    # MÉTODO 2: Fallback - Baixar do GitHub (pode travar no ARM64 na primeira vez)
    # =========================================================================
    else
        log_warning "Pre-packaged BepInEx not found, downloading from GitHub..."
        log_warning "NOTE: This may hang on first run due to Il2CppInterop on ARM64"
        
        local BEPINEX_VERSION="6.0.0-pre.2"
        local BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx-Unity.IL2CPP-win-x64-${BEPINEX_VERSION}.zip"
        
        # Criar estrutura de diretórios
        mkdir -p "${BEPINEX_DIR}/core"
        mkdir -p "${BEPINEX_DIR}/config"
        mkdir -p "${BEPINEX_DIR}/plugins"
        mkdir -p "${BEPINEX_DIR}/patchers"
        mkdir -p "${SERVER_DIR}/dotnet"
        
        # Baixar BepInEx
        cd /tmp
        wget -q "${BEPINEX_URL}" -O bepinex.zip || {
            log_error "Failed to download BepInEx!"
            return 1
        }
        
        # Extrair
        unzip -q -o bepinex.zip -d bepinex_extract
        
        # Copiar arquivos
        if [ -d "bepinex_extract/BepInEx" ]; then
            cp -r bepinex_extract/BepInEx/* "${BEPINEX_DIR}/"
        fi
        
        # Copiar winhttp.dll (doorstop proxy)
        if [ -f "bepinex_extract/winhttp.dll" ]; then
            cp bepinex_extract/winhttp.dll "${SERVER_DIR}/"
        fi
        
        # Copiar dotnet runtime
        if [ -d "bepinex_extract/dotnet" ]; then
            cp -r bepinex_extract/dotnet/* "${SERVER_DIR}/dotnet/"
        fi
        
        # Limpar
        rm -rf bepinex.zip bepinex_extract
        
        log_success "BepInEx downloaded and extracted!"
    fi
    
    # =========================================================================
    # Copiar doorstop_config.ini do template se não existir
    # =========================================================================
    if [ ! -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        if [ -f "/scripts/bepinex/doorstop_config.ini" ]; then
            log_bepinex "Copying doorstop_config.ini from template..."
            cp "/scripts/bepinex/doorstop_config.ini" "${SERVER_DIR}/doorstop_config.ini"
        fi
    fi
    
    # =========================================================================
    # Verificação pós-instalação
    # =========================================================================
    log_bepinex "Verifying installation..."
    
    local install_ok=true
    
    if [ -f "${SERVER_DIR}/winhttp.dll" ]; then
        log_bepinex "  ✓ winhttp.dll ($(stat -c%s "${SERVER_DIR}/winhttp.dll" 2>/dev/null || echo "?") bytes)"
    else
        log_error "  ✗ winhttp.dll MISSING!"
        install_ok=false
    fi
    
    if [ -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        log_bepinex "  ✓ doorstop_config.ini"
    else
        log_error "  ✗ doorstop_config.ini MISSING!"
        install_ok=false
    fi
    
    if [ -f "${BEPINEX_DIR}/core/BepInEx.Unity.IL2CPP.dll" ]; then
        log_bepinex "  ✓ BepInEx.Unity.IL2CPP.dll"
    else
        log_error "  ✗ BepInEx.Unity.IL2CPP.dll MISSING!"
        install_ok=false
    fi
    
    # Verificar dotnet (pode estar em lugares diferentes)
    if [ -f "${SERVER_DIR}/dotnet/coreclr.dll" ]; then
        log_bepinex "  ✓ dotnet/coreclr.dll"
    elif [ -d "${SERVER_DIR}/dotnet" ]; then
        log_bepinex "  ✓ dotnet/ (directory exists)"
    else
        log_warning "  ? dotnet/ not found (may be bundled elsewhere)"
    fi
    
    # Verificar se interop pré-gerado existe (CRUCIAL para ARM64!)
    if [ -d "${BEPINEX_DIR}/interop" ] && [ "$(ls -A ${BEPINEX_DIR}/interop 2>/dev/null)" ]; then
        log_bepinex "  ✓ interop/ (pre-generated assemblies - ARM64 compatible!)"
    else
        log_warning "  ! interop/ not found - BepInEx will try to generate on first run"
        log_warning "    This may hang on ARM64/Box64. Consider using pre-generated interop."
    fi
    
    if [ "$install_ok" = true ]; then
        log_success "BepInEx installation complete!"
    else
        log_error "BepInEx installation INCOMPLETE!"
        return 1
    fi
    
    log_bepinex "=============================================="
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
