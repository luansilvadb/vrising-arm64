# =============================================================================
# BepInEx ARM64 Integration para V Rising
# =============================================================================
#
# Este diretório contém os arquivos base do BepInEx modificados para
# funcionar em ARM64 com Box64.
#
# ## Estrutura:
#
# ```
# bepinex/
# ├── doorstop_config.ini    # Configuração do Unity Doorstop
# ├── winhttp.dll            # DLL hook do Doorstop (baixado no build)
# ├── dotnet/                # CoreCLR runtime (baixado no build)
# └── BepInEx/               # Estrutura BepInEx
#     ├── core/              # Core BepInEx DLLs
#     ├── config/            # Configurações dos plugins
#     ├── plugins/           # Plugins instalados
#     └── patchers/          # Patchers (opcional)
# ```
#
# ## Uso:
#
# 1. Definir `ENABLE_PLUGINS=true` no docker-compose.yml
# 2. Colocar plugins em `/data/server/BepInEx/plugins/`
# 3. Reiniciar o container
#
# ## Notas ARM64:
#
# - Usa Il2CppInterop modificado do tsx-cloud para compatibilidade Box64
# - Evita problemas de multithreading no gerador de interop
# - Pre-gera assemblies de interop no build
#
# ## Fonte:
#
# Baseado em:
# - https://github.com/tsx-cloud/vrising-ntsync
# - https://github.com/tsx-cloud/Il2CppInterop
# - https://github.com/BepInEx/BepInEx
#
# =============================================================================
