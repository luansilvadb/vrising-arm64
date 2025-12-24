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

# Verifica se wine64 existe no RootFS
if [ -f "${ROOTFS_DIR}/usr/bin/wine64" ]; then
    exec FEXInterpreter "${ROOTFS_DIR}/usr/bin/wine64" "$@"
elif [ -f "${ROOTFS_DIR}/usr/bin/wine" ]; then
    exec FEXInterpreter "${ROOTFS_DIR}/usr/bin/wine" "$@"
else
    echo "ERRO: Wine não encontrado em ${ROOTFS_DIR}/usr/bin/"
    echo "Conteúdo de ${ROOTFS_DIR}/usr/bin/:"
    ls -la "${ROOTFS_DIR}/usr/bin/" | grep -i wine || echo "Nenhum binário wine encontrado"
    exit 1
fi
