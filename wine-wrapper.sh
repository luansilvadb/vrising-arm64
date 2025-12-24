#!/bin/bash
# Wrapper que executa Wine via FEX-Emu
# Usa FEXBash para configurar o ambiente RootFS corretamente

# Diretórios Wine
export WINEPREFIX="${WINEPREFIX:-/data/wine-prefix}"
export WINEARCH=win64
export WINEDEBUG=-all

# Desabilita componentes gráficos desnecessários
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"

# Display virtual (Xvfb deve estar rodando via entrypoint)
export DISPLAY="${DISPLAY:-:99}"

# Usa FEXBash para executar wine64 dentro do contexto do RootFS
# FEXBash configura o ambiente corretamente para que Wine encontre seus arquivos
echo "Executando Wine via FEXBash: wine64 $@"
exec FEXBash -c "WINEPREFIX='${WINEPREFIX}' WINEARCH='${WINEARCH}' WINEDEBUG='${WINEDEBUG}' WINEDLLOVERRIDES='${WINEDLLOVERRIDES}' DISPLAY='${DISPLAY}' wine64 $*"
