#!/bin/bash
# =============================================================================
# BepInEx Setup Script for V Rising ARM64
# =============================================================================
# Este script configura o BepInEx no servidor V Rising.
# É chamado pelo entrypoint.sh quando ENABLE_PLUGINS=true
#
# Baseado na implementação do tsx-cloud/vrising-ntsync
# =============================================================================

# Nota: Não usamos 'set -e' pois este script é importado via source

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
BEPINEX_DEFAULTS="/scripts/bepinex"

# URLs dos arquivos BepInEx
# V Rising usa Unity IL2CPP, então precisamos da versão 6 (pre.2)
# Nota: BepInEx 5.x NÃO funciona com IL2CPP games
BEPINEX_VERSION="6.0.0-pre.2"
BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx-Unity.IL2CPP-win-x64-${BEPINEX_VERSION}.zip"

verify_bepinex_installation() {
    # Verificar TODOS os arquivos críticos, não apenas diretórios
    local missing_files=""
    
    if [ ! -f "${SERVER_DIR}/winhttp.dll" ]; then
        missing_files="${missing_files} winhttp.dll"
    fi
    
    if [ ! -f "${SERVER_DIR}/dotnet/coreclr.dll" ]; then
        missing_files="${missing_files} dotnet/coreclr.dll"
    fi
    
    if [ ! -f "${BEPINEX_DIR}/core/BepInEx.Unity.IL2CPP.dll" ]; then
        missing_files="${missing_files} BepInEx.Unity.IL2CPP.dll"
    fi
    
    if [ ! -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        missing_files="${missing_files} doorstop_config.ini"
    fi
    
    if [ -n "${missing_files}" ]; then
        log_warning "BepInEx incomplete! Missing:${missing_files}"
        return 1
    fi
    
    return 0
}

setup_bepinex() {
    log_bepinex "=============================================="
    log_bepinex "Setting up BepInEx for V Rising"
    log_bepinex "=============================================="
    
    # Verificar se instalação está COMPLETA (não apenas se diretório existe)
    if verify_bepinex_installation; then
        log_bepinex "BepInEx installation verified complete!"
        log_bepinex "Files present:"
        log_bepinex "  ✓ winhttp.dll"
        log_bepinex "  ✓ dotnet/coreclr.dll"
        log_bepinex "  ✓ BepInEx/core/BepInEx.Unity.IL2CPP.dll"
        log_bepinex "  ✓ doorstop_config.ini"
        return 0
    fi
    
    log_bepinex "BepInEx needs installation/repair..."
    
    log_bepinex "Installing BepInEx ${BEPINEX_VERSION}..."
    
    # Criar estrutura de diretórios
    mkdir -p "${BEPINEX_DIR}/core"
    mkdir -p "${BEPINEX_DIR}/config"
    mkdir -p "${BEPINEX_DIR}/plugins"
    mkdir -p "${BEPINEX_DIR}/patchers"
    mkdir -p "${SERVER_DIR}/dotnet"
    
    # Copiar doorstop_config.ini do template
    if [ -f "${BEPINEX_DEFAULTS}/doorstop_config.ini" ]; then
        log_bepinex "Copying doorstop_config.ini..."
        cp "${BEPINEX_DEFAULTS}/doorstop_config.ini" "${SERVER_DIR}/doorstop_config.ini"
    fi
    
    # Baixar BepInEx se não existir
    if [ ! -f "${BEPINEX_DIR}/core/BepInEx.Unity.IL2CPP.dll" ]; then
        log_bepinex "Downloading BepInEx ${BEPINEX_VERSION}..."
        
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
        
        log_success "BepInEx files extracted!"
    fi
    
    # Verificação pós-instalação
    log_bepinex "Verifying installation..."
    
    local install_ok=true
    
    if [ -f "${SERVER_DIR}/winhttp.dll" ]; then
        log_bepinex "  ✓ winhttp.dll ($(stat -c%s "${SERVER_DIR}/winhttp.dll") bytes)"
    else
        log_error "  ✗ winhttp.dll MISSING!"
        install_ok=false
    fi
    
    if [ -f "${SERVER_DIR}/dotnet/coreclr.dll" ]; then
        log_bepinex "  ✓ dotnet/coreclr.dll"
    else
        log_error "  ✗ dotnet/coreclr.dll MISSING!"
        install_ok=false
    fi
    
    if [ -f "${BEPINEX_DIR}/core/BepInEx.Unity.IL2CPP.dll" ]; then
        log_bepinex "  ✓ BepInEx.Unity.IL2CPP.dll"
    else
        log_error "  ✗ BepInEx.Unity.IL2CPP.dll MISSING!"
        install_ok=false
    fi
    
    if [ -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        log_bepinex "  ✓ doorstop_config.ini"
    else
        log_error "  ✗ doorstop_config.ini MISSING!"
        install_ok=false
    fi
    
    if [ "$install_ok" = true ]; then
        log_success "BepInEx installation complete and verified!"
    else
        log_error "BepInEx installation INCOMPLETE! Check logs above."
        return 1
    fi
    
    log_bepinex "=============================================="
}

enable_plugins() {
    log_bepinex "Enabling BepInEx plugins..."
    
    # Atualizar doorstop_config.ini
    if [ -f "${SERVER_DIR}/doorstop_config.ini" ]; then
        sed -i "s/^enabled *=.*/enabled = true/" "${SERVER_DIR}/doorstop_config.ini"
        log_success "Plugins ENABLED in doorstop_config.ini"
    else
        log_warning "doorstop_config.ini not found!"
    fi
    
    # Configurar Wine DLL override para carregar winhttp.dll nativo
    # Formato limpo para evitar problemas de parsing
    if [ -n "${WINEDLLOVERRIDES}" ]; then
        # Remover override antigo de winhttp se existir
        WINEDLLOVERRIDES=$(echo "${WINEDLLOVERRIDES}" | sed 's/;*winhttp=[^;]*//g')
        export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};winhttp=n,b"
    else
        export WINEDLLOVERRIDES="winhttp=n,b"
    fi
    log_bepinex "WINEDLLOVERRIDES=${WINEDLLOVERRIDES}"
    
    # Também configurar via Wine registry para garantir (mais confiável)
    if [ -d "${WINEPREFIX}" ]; then
        log_bepinex "Setting winhttp override in Wine registry..."
        mkdir -p "${WINEPREFIX}/drive_c/windows/system32"
        
        # Adicionar override no user.reg
        if [ -f "${WINEPREFIX}/user.reg" ]; then
            # Verificar se seção DllOverrides existe
            if grep -q '\[Software\\\\Wine\\\\DllOverrides\]' "${WINEPREFIX}/user.reg" 2>/dev/null; then
                # Adicionar winhttp se não existir
                if ! grep -q '"winhttp"' "${WINEPREFIX}/user.reg" 2>/dev/null; then
                    sed -i '/\[Software\\\\Wine\\\\DllOverrides\]/a "winhttp"="native,builtin"' "${WINEPREFIX}/user.reg"
                    log_bepinex "Added winhttp override to Wine registry"
                else
                    log_bepinex "winhttp override already in Wine registry"
                fi
            fi
        fi
    fi
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
