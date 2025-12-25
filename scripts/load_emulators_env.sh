#!/bin/bash
# =============================================================================
# Load Emulators Environment Configuration
# =============================================================================
# Este script carrega configurações customizáveis para Box64/FEX-Emu
# As configurações são lidas de /data/saves/Settings/emulators.rc
# =============================================================================

# Cores para logs
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_emulator() { echo -e "${BLUE}[EMULATOR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }

# Diretório de configurações persistentes
SETTINGS_DIR="${SAVES_DIR:-/data/saves}/Settings"
EMULATORS_CONFIG="${SETTINGS_DIR}/emulators.rc"
DEFAULT_CONFIG="/scripts/config/emulators.rc"

# Criar diretório se não existir
mkdir -p "${SETTINGS_DIR}"

# Copiar config padrão se não existir a customizada
if [ ! -f "${EMULATORS_CONFIG}" ]; then
    if [ -f "${DEFAULT_CONFIG}" ]; then
        log_emulator "Copiando configuração padrão de emuladores..."
        cp "${DEFAULT_CONFIG}" "${EMULATORS_CONFIG}"
    else
        log_emulator "Aviso: Arquivo de configuração padrão não encontrado"
        return 0
    fi
fi

# Verificar se arquivo existe
if [ ! -f "${EMULATORS_CONFIG}" ]; then
    log_emulator "Aviso: Nenhuma configuração de emulador encontrada"
    return 0
fi

log_emulator "Carregando configurações de: ${EMULATORS_CONFIG}"

# Ler e processar cada linha
while IFS= read -r line || [ -n "$line" ]; do
    # Pular linhas vazias e comentários
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Remover espaços em branco
    line=$(echo "$line" | xargs)
    
    # Processar variáveis BOX64_*
    if [[ "$line" == BOX64_* ]]; then
        export "$line"
        log_emulator "→ $line"
    fi
    
    # Processar variáveis BOX86_*
    if [[ "$line" == BOX86_* ]]; then
        export "$line"
        log_emulator "→ $line"
    fi
    
    # Processar variáveis FEX_*
    if [[ "$line" == FEX_* ]]; then
        export "$line"
        log_emulator "→ $line"
    fi
    
    # Processar variáveis WINE_*
    if [[ "$line" == WINE_* ]]; then
        export "$line"
        log_emulator "→ $line"
    fi
done < "${EMULATORS_CONFIG}"

log_emulator "Configurações de emuladores carregadas!"
