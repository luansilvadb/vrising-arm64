# =============================================================================
# BepInEx ARM64 Integration para V Rising (tsx-cloud approach)
# =============================================================================
#
# IMPORTANTE: Este diretório contém os arquivos BepInEx PRÉ-PACKAGED.
# Isso é necessário porque o Il2CppInterop padrão trava no ARM64/Box64.
#
# ## Estrutura necessária:
#
# ```
# bepinex/
# ├── doorstop_config.ini        # Configuração do Unity Doorstop
# ├── README.md                   # Este arquivo
# └── server/                     # ← ARQUIVOS PRÉ-PACKAGED (copiar de tsx-cloud)
#     ├── winhttp.dll             # DLL hook do Doorstop
#     ├── doorstop_config.ini     # Cópia do doorstop_config.ini
#     ├── dotnet/                 # CoreCLR runtime
#     │   ├── coreclr.dll
#     │   └── ... (outros arquivos dotnet)
#     └── BepInEx/                # Estrutura BepInEx
#         ├── core/               # Core BepInEx DLLs
#         ├── config/             # Configurações padrão
#         ├── plugins/            # Plugins pré-instalados
#         ├── patchers/           # Patchers (opcional)
#         ├── interop/            # ← CRUCIAL! Assemblies pré-gerados
#         └── unity-libs/         # Libraries Unity
# ```
#
# ## Por que pré-packaged?
#
# O BepInEx 6 para IL2CPP precisa gerar "interop assemblies" na primeira 
# execução usando Cpp2IL e Il2CppInterop. Esse processo:
#
# 1. Usa MULTITHREADING intensivo
# 2. TRAVA com Box64 no ARM64 (bug conhecido)
# 3. Pode demorar 10-30 minutos mesmo quando funciona
#
# A solução do tsx-cloud é PRÉ-GERAR esses assemblies em uma máquina x86_64
# e incluí-los no repositório/imagem Docker.
#
# ## Como obter os arquivos pré-packaged:
#
# ### Opção 1: Copiar do tsx-cloud
# ```bash
# git clone https://github.com/tsx-cloud/vrising-ntsync.git
# cp -r vrising-ntsync/Docker/server/* bepinex/server/
# ```
#
# ### Opção 2: Gerar em máquina x86_64
# 1. Rodar V Rising + BepInEx em um PC Windows ou Linux x86_64
# 2. Aguardar BepInEx gerar os assemblies interop
# 3. Copiar a pasta BepInEx/ completa para cá
#
# ## Uso:
#
# 1. Colocar os arquivos pré-packaged em `bepinex/server/`
# 2. Definir `ENABLE_PLUGINS=true` no docker-compose.yml ou EasyPanel
# 3. Reiniciar o container
# 4. Colocar plugins em `/data/server/BepInEx/plugins/` no container
#
# ## Fonte:
#
# Baseado em:
# - https://github.com/tsx-cloud/vrising-ntsync
# - https://github.com/tsx-cloud/Il2CppInterop (fork ARM-friendly)
# - https://github.com/BepInEx/BepInEx
#
# =============================================================================
