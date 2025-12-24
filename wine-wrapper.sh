#!/bin/bash
# Wrapper que executa Wine via FEX-Emu
# O RootFS é extraído em /opt/fex-rootfs durante o build

# CRÍTICO: Configura FEX para encontrar o RootFS
# FEX lê variáveis de ambiente com prefixo FEX_
export FEX_ROOTFS="/opt/fex-rootfs"
export HOME="/home/vrising"

# Diretórios Wine
export WINEPREFIX="${WINEPREFIX:-/data/wine-prefix}"
export WINEARCH=win64
export WINEDEBUG=-all

# Desabilita componentes gráficos desnecessários
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"

# Display virtual (Xvfb deve estar rodando via entrypoint)
export DISPLAY="${DISPLAY:-:99}"

# Debug: mostra configuração
echo "=== FEX Configuration ==="
echo "FEX_ROOTFS: ${FEX_ROOTFS}"
echo "HOME: ${HOME}"
echo "WINEPREFIX: ${WINEPREFIX}"
echo "Checking RootFS..."
ls -la "${FEX_ROOTFS}/usr/share/wine/wine/" 2>/dev/null | head -3 || echo "wine.inf check failed"
echo "========================="

# Executa wine64 via FEXBash
# FEXBash configura o overlay do RootFS corretamente
echo "Executando: wine64 $*"
exec FEXBash -c "wine64 $*"
