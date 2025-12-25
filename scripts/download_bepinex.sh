#!/bin/bash
# =============================================================================
# Download BepInEx ARM64-Friendly
# =============================================================================
# Este script baixa os arquivos BepInEx pré-configurados do repositório tsx-cloud
# que já incluem os interop assemblies pré-gerados (evitando o hang do Il2CppInterop).
# =============================================================================

set -e

BEPINEX_DIR="/opt/bepinex"
TSX_REPO="https://raw.githubusercontent.com/tsx-cloud/vrising-ntsync/main/Docker/server"

echo "[INFO] Baixando BepInEx ARM64-Friendly do tsx-cloud..."

mkdir -p "${BEPINEX_DIR}"

# Baixar arquivos raiz
echo "[INFO] Baixando winhttp.dll..."
wget -q "${TSX_REPO}/winhttp.dll" -O "${BEPINEX_DIR}/winhttp.dll"

echo "[INFO] Baixando doorstop_config.ini..."
wget -q "${TSX_REPO}/doorstop_config.ini" -O "${BEPINEX_DIR}/doorstop_config.ini"

echo "[INFO] Baixando .doorstop_version..."
wget -q "${TSX_REPO}/.doorstop_version" -O "${BEPINEX_DIR}/.doorstop_version"

# Criar estrutura BepInEx
mkdir -p "${BEPINEX_DIR}/BepInEx/config"
mkdir -p "${BEPINEX_DIR}/BepInEx/core"
mkdir -p "${BEPINEX_DIR}/BepInEx/plugins"
mkdir -p "${BEPINEX_DIR}/BepInEx/interop"
mkdir -p "${BEPINEX_DIR}/BepInEx/unity-libs"
mkdir -p "${BEPINEX_DIR}/BepInEx/addition_stuff"
mkdir -p "${BEPINEX_DIR}/dotnet"

# Função para baixar arquivos de um diretório GitHub
download_github_dir() {
    local DIR_PATH=$1
    local LOCAL_DIR=$2
    local API_URL="https://api.github.com/repos/tsx-cloud/vrising-ntsync/contents/Docker/server/${DIR_PATH}"
    
    echo "[INFO] Baixando ${DIR_PATH}..."
    
    # Obter lista de arquivos
    local FILES=$(wget -q -O - "${API_URL}" | jq -r '.[] | select(.type=="file") | .download_url')
    
    for FILE_URL in $FILES; do
        local FILENAME=$(basename "$FILE_URL")
        wget -q "${FILE_URL}" -O "${LOCAL_DIR}/${FILENAME}"
    done
}

# Baixar cada diretório
download_github_dir "BepInEx/config" "${BEPINEX_DIR}/BepInEx/config"
download_github_dir "BepInEx/core" "${BEPINEX_DIR}/BepInEx/core"
download_github_dir "BepInEx/interop" "${BEPINEX_DIR}/BepInEx/interop"
download_github_dir "BepInEx/unity-libs" "${BEPINEX_DIR}/BepInEx/unity-libs"
download_github_dir "BepInEx/addition_stuff" "${BEPINEX_DIR}/BepInEx/addition_stuff"
download_github_dir "dotnet" "${BEPINEX_DIR}/dotnet"

echo "[SUCCESS] BepInEx ARM64-Friendly baixado em ${BEPINEX_DIR}!"
echo "[INFO] Total de arquivos:"
find "${BEPINEX_DIR}" -type f | wc -l
