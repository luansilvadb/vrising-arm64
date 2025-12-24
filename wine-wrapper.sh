#!/bin/bash
# Wrapper que executa Wine via FEX-Emu
# O RootFS SquashFS já contém Wine64 instalado

# Diretórios Wine
export WINEPREFIX="${WINEPREFIX:-/data/wine-prefix}"
export WINEARCH=win64
export WINEDEBUG=-all

# Desabilita componentes gráficos desnecessários
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"

# Display virtual (Xvfb deve estar rodando via entrypoint)
export DISPLAY="${DISPLAY:-:99}"

# Executa wine64 via FEXInterpreter
# O FEX monta o RootFS automaticamente e wine64 está disponível em /usr/bin/wine64
exec FEXInterpreter /usr/bin/wine64 "$@"
