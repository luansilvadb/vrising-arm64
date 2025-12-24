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

# Verifica se display está disponível (ignorando erros)
if command -v xdpyinfo &>/dev/null; then
    if ! xdpyinfo -display "$DISPLAY" &>/dev/null 2>&1; then
        echo "AVISO: Display $DISPLAY não detectado, continuando mesmo assim..."
    fi
fi

# Detecta o caminho do Wine no RootFS
# FEXRootFSFetcher salva o RootFS em ~/.fex-emu/RootFS/
WINE_PATH=""
if [ -f "$HOME/.fex-emu/RootFS/usr/bin/wine64" ]; then
    WINE_PATH="$HOME/.fex-emu/RootFS/usr/bin/wine64"
elif [ -f "/home/vrising/.fex-emu/RootFS/usr/bin/wine64" ]; then
    WINE_PATH="/home/vrising/.fex-emu/RootFS/usr/bin/wine64"
fi

# Se Wine não está no RootFS, precisa instalar primeiro
if [ -z "$WINE_PATH" ]; then
    echo "Wine não encontrado no RootFS. Instalando via FEXBash..."
    FEXBash -c "apt-get update && apt-get install -y wine64 winbind" 2>/dev/null || true
    
    if [ -f "$HOME/.fex-emu/RootFS/usr/bin/wine64" ]; then
        WINE_PATH="$HOME/.fex-emu/RootFS/usr/bin/wine64"
    fi
fi

if [ -z "$WINE_PATH" ]; then
    echo "ERRO: Wine64 não encontrado. Execute 'FEXBash apt install wine64' manualmente."
    exit 1
fi

# Executa via FEX-Emu
exec FEXInterpreter "$WINE_PATH" "$@"

