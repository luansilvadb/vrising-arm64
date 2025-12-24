#!/bin/bash
# Wrapper que executa Wine via FEX-Emu
# O RootFS é extraído em /opt/fex-rootfs durante o build

# Diretórios Wine
export WINEPREFIX="${WINEPREFIX:-/data/wine-prefix}"
export WINEARCH=win64
export WINEDEBUG=-all

# Desabilita componentes gráficos desnecessários
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"

# Display virtual (Xvfb deve estar rodando via entrypoint)
export DISPLAY="${DISPLAY:-:99}"

# Caminho do RootFS extraído
ROOTFS_DIR="${FEX_ROOTFS:-/opt/fex-rootfs}"

# Wine64 está em /usr/lib/wine/wine64 ou como wine64-stable symlink
# Usamos o binário direto em lib/wine/wine64
WINE_BIN="${ROOTFS_DIR}/usr/lib/wine/wine64"

if [ -e "${WINE_BIN}" ]; then
    echo "Usando Wine: ${WINE_BIN}"
    exec FEXInterpreter "${WINE_BIN}" "$@"
else
    # Fallback: tenta wine-stable
    WINE_BIN="${ROOTFS_DIR}/usr/bin/wine-stable"
    if [ -e "${WINE_BIN}" ]; then
        echo "Usando Wine: ${WINE_BIN}"
        exec FEXInterpreter "${WINE_BIN}" "$@"
    else
        echo "ERRO: Wine não encontrado!"
        echo "Procurado em: ${ROOTFS_DIR}/usr/lib/wine/wine64"
        echo "Conteúdo de ${ROOTFS_DIR}/usr/lib/wine/:"
        ls -la "${ROOTFS_DIR}/usr/lib/wine/" 2>/dev/null | head -20 || echo "Diretório não existe"
        exit 1
    fi
fi
