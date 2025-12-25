#!/bin/bash
# =============================================================================
# V Rising ARM64 - Download de Mods do Thunderstore
# =============================================================================
# Uso: ./download-mod.sh <autor>/<nome>
# Exemplo: ./download-mod.sh odjit/KindredLogistics
#          ./download-mod.sh deca/VampireCommandFramework
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

MODS_DIR="$(dirname "$0")/../mods"
TEMP_DIR="/tmp/vrising-mods"

# =============================================================================
# Função principal
# =============================================================================

download_mod() {
    local mod_path="$1"
    
    if [ -z "$mod_path" ]; then
        echo ""
        echo "🧛 V Rising ARM64 - Download de Mods"
        echo "======================================"
        echo ""
        echo "Uso: $0 <autor>/<nome>"
        echo ""
        echo "Exemplos:"
        echo "  $0 odjit/KindredLogistics"
        echo "  $0 deca/VampireCommandFramework"
        echo "  $0 deca/Bloodstone"
        echo ""
        echo "Mods Populares:"
        echo "  - odjit/KindredLogistics     # Automação de inventário"
        echo "  - deca/VampireCommandFramework # Framework de comandos"
        echo "  - deca/Bloodstone            # API base para mods"
        echo "  - odjit/KindredSchematics    # Blueprints de construção"
        echo "  - odjit/KindredCommands      # Comandos administrativos"
        echo ""
        exit 1
    fi
    
    # Separar autor e nome
    local author=$(echo "$mod_path" | cut -d'/' -f1)
    local name=$(echo "$mod_path" | cut -d'/' -f2)
    
    if [ -z "$author" ] || [ -z "$name" ]; then
        log_error "Formato inválido. Use: autor/nome"
        exit 1
    fi
    
    log_info "Buscando mod: $author/$name"
    
    # Criar diretórios
    mkdir -p "$MODS_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Buscar versão mais recente via API do Thunderstore
    local api_url="https://thunderstore.io/api/experimental/package/${author}/${name}/"
    log_info "Consultando API: $api_url"
    
    # Tentar obter informações do mod
    local mod_info
    mod_info=$(curl -sf "$api_url" 2>/dev/null) || {
        log_error "Mod não encontrado: $author/$name"
        log_info "Verifique o nome em: https://thunderstore.io/c/v-rising/"
        exit 1
    }
    
    # Extrair versão e URL de download
    local version=$(echo "$mod_info" | grep -o '"version_number":"[^"]*"' | head -1 | cut -d'"' -f4)
    local download_url="https://thunderstore.io/package/download/${author}/${name}/${version}/"
    
    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão do mod"
        exit 1
    fi
    
    log_info "Versão: $version"
    log_info "Download URL: $download_url"
    
    # Baixar o mod
    local zip_file="${TEMP_DIR}/${name}.zip"
    log_info "Baixando..."
    
    curl -sL "$download_url" -o "$zip_file" || {
        log_error "Falha no download"
        exit 1
    }
    
    # Extrair
    local extract_dir="${TEMP_DIR}/${name}"
    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"
    
    log_info "Extraindo..."
    unzip -q "$zip_file" -d "$extract_dir" 2>/dev/null || {
        log_error "Falha ao extrair arquivo"
        exit 1
    }
    
    # Encontrar arquivos .dll
    local dll_count=0
    while IFS= read -r dll; do
        local dll_name=$(basename "$dll")
        
        # Ignorar DLLs do BepInEx core (já temos)
        if [[ "$dll_name" == "0Harmony"* ]] || \
           [[ "$dll_name" == "BepInEx"* ]] || \
           [[ "$dll_name" == "Mono"* ]] || \
           [[ "$dll_name" == "System"* ]] || \
           [[ "$dll_name" == "Microsoft"* ]] || \
           [[ "$dll_name" == "netstandard"* ]]; then
            continue
        fi
        
        log_info "Copiando: $dll_name"
        cp "$dll" "$MODS_DIR/"
        ((dll_count++))
    done < <(find "$extract_dir" -name "*.dll" -type f 2>/dev/null)
    
    # Limpar
    rm -rf "$zip_file" "$extract_dir"
    
    if [ $dll_count -eq 0 ]; then
        log_warning "Nenhum arquivo .dll encontrado no mod"
    else
        log_success "Mod instalado: $name v$version ($dll_count arquivos)"
        log_info "Arquivos em: $MODS_DIR/"
    fi
    
    echo ""
    log_info "Próximos passos:"
    echo "  1. Reinicie o servidor: docker compose restart vrising"
    echo "  2. Verifique os logs: docker logs vrising-server | grep -i '$name'"
}

# =============================================================================
# Instalar pack completo de QoL
# =============================================================================

install_qol_pack() {
    log_info "Instalando pack de Quality of Life..."
    echo ""
    
    local mods=(
        "deca/VampireCommandFramework"
        "odjit/KindredLogistics"
    )
    
    for mod in "${mods[@]}"; do
        log_info "=========================================="
        download_mod "$mod"
        echo ""
    done
    
    log_success "Pack QoL instalado!"
    log_info "Mods instalados:"
    ls -la "$MODS_DIR/"*.dll 2>/dev/null || echo "  (nenhum)"
}

# =============================================================================
# Listar mods instalados
# =============================================================================

list_installed() {
    log_info "Mods instalados em $MODS_DIR:"
    echo ""
    
    if ls "$MODS_DIR/"*.dll 1>/dev/null 2>&1; then
        for dll in "$MODS_DIR/"*.dll; do
            echo "  ✅ $(basename "$dll")"
        done
    else
        echo "  (nenhum mod instalado)"
    fi
    echo ""
}

# =============================================================================
# Main
# =============================================================================

case "$1" in
    --qol|--pack)
        install_qol_pack
        ;;
    --list|-l)
        list_installed
        ;;
    --help|-h)
        download_mod ""
        ;;
    *)
        download_mod "$1"
        ;;
esac
