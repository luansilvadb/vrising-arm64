#!/bin/bash
# Wrapper que executa comandos via FEX-Emu + Wine

# Diretórios
export WINEPREFIX="${WINEPREFIX:-/data/wine-prefix}"
export WINEARCH=win64
export WINEDEBUG=-all

# Desabilita componentes gráficos desnecessários
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"

# Display virtual (Xvfb deve estar rodando via entrypoint)
export DISPLAY="${DISPLAY:-:99}"

# Verifica se display está disponível
if ! xdpyinfo -display "$DISPLAY" &>/dev/null 2>&1; then
    echo "AVISO: Display $DISPLAY não detectado, continuando mesmo assim..."
fi

# Executa via FEX-Emu
exec FEXInterpreter /opt/fex-rootfs/usr/bin/wine64 "$@"
