# SPECS-002: Suporte a Mods com BepInEx

> **Status**: 🚧 Em Implementação  
> **Data**: 2025-12-25  
> **Autor**: Projeto vrising-arm64

---

## 1. Visão Geral

Este documento descreve a arquitetura para suporte a **mods via BepInEx** no servidor V Rising ARM64.

### Stack de Mods

```
┌─────────────────────────────────────────────────────────┐
│                      Mods (.dll)                        │
│              (Plugins da comunidade)                    │
├─────────────────────────────────────────────────────────┤
│                      BepInEx 6.0                        │
│              (Framework de modding Unity)               │
├─────────────────────────────────────────────────────────┤
│                   VRisingServer.exe                     │
│                   (Windows x86_64)                      │
├─────────────────────────────────────────────────────────┤
│                     Wine WOW64                          │
│              (Traduz Windows → Linux)                   │
├─────────────────────────────────────────────────────────┤
│                      Box64                              │
│              (Emula x86_64 → ARM64)                     │
├─────────────────────────────────────────────────────────┤
│                   Linux ARM64                           │
│              (Host: Oracle Cloud, etc)                  │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Componentes do BepInEx

### 2.1 Estrutura de Arquivos

```
/data/server/
├── VRisingServer.exe
├── winhttp.dll              ← Hook DLL (injeta BepInEx)
├── doorstop_config.ini      ← Configuração do Doorstop
├── .doorstop_version
├── dotnet/                  ← .NET Runtime
│   ├── shared/
│   └── ...
└── BepInEx/
    ├── core/                ← DLLs do framework
    │   ├── BepInEx.Core.dll
    │   ├── BepInEx.Unity.IL2CPP.dll
    │   └── ...
    ├── plugins/             ← Mods instalados
    │   ├── SeuMod.dll
    │   └── ...
    ├── config/              ← Configurações dos mods
    │   ├── BepInEx.cfg
    │   └── SeuMod.cfg
    ├── cache/               ← Cache de assemblies (gerado)
    └── interop/             ← DLLs Il2Cpp (gerado)
```

### 2.2 Fluxo de Inicialização

```
1. Wine carrega VRisingServer.exe
2. Windows carrega winhttp.dll (hook do Doorstop)
3. Doorstop carrega dotnet runtime
4. BepInEx é inicializado
5. [Primeira vez] Cpp2IL + Il2CppInterop geram interop/
6. BepInEx carrega plugins de BepInEx/plugins/
7. VRisingServer.exe inicia normalmente
```

---

## 3. Integração com Arquitetura Atual

### 3.1 Variáveis de Ambiente Novas

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `BEPINEX_ENABLED` | `false` | Habilita/desabilita BepInEx |

### 3.2 Volumes

```yaml
volumes:
  - vrising-data:/data           # Dados do servidor
  - ./mods:/data/mods            # Persistência de mods
```

### 3.3 Estrutura no Container

```
/opt/bepinex/                   # BepInEx instalado no build
├── BepInExPack_V_Rising/
│   ├── BepInEx/
│   ├── dotnet/
│   ├── winhttp.dll
│   └── doorstop_config.ini

/data/                           # Volume persistente
├── server/
│   └── BepInEx/plugins/ → /data/mods/   # Symlink
└── mods/                        # Mods persistentes
```

---

## 4. Desafios Técnicos

### 4.1 Il2CppInterop no ARM64/Box64

**Problema**: BepInEx usa Il2CppInterop para gerar DLLs de interoperabilidade. Este processo:
- Usa escrita multithreaded de arquivos
- Box64 pode travar durante esta operação
- FEX-Emu pode crashar no Cpp2IL

**Sintoma**:
```
[BepInEx] Running Cpp2IL...
[BepInEx] Generating interop assemblies...
[HANG ou SEGFAULT]
```

**Soluções Disponíveis**:

1. **Aguardar** - Box64 v0.3.8+ tem melhorias
2. **Pré-gerar interop** - Gerar em máquina x86_64 e copiar
3. **Mais memória** - 12GB+ pode ajudar
4. **Patch Il2CppInterop** - Desabilitar multithreading

**Implementação Atual**:
- Aumentar timeout de primeira execução
- Documentar workaround para usuários
- Monitorar estabilidade

### 4.2 Wine DLL Override

**Requisito**: BepInEx precisa que `winhttp.dll` seja carregado como nativo.

**Solução**:
```bash
export WINEDLLOVERRIDES="winhttp=n,b;mscoree=d;mshtml=d;dnsapi=b"
```

---

## 5. Implementação

### 5.1 Dockerfile

```dockerfile
# =============================================================================
# BepInEx para suporte a mods
# =============================================================================
ENV BEPINEX_ENABLED="false" \
    BEPINEX_VERSION="1.733.2"

RUN mkdir -p /opt/bepinex && \
    cd /opt/bepinex && \
    wget -q "https://thunderstore.io/package/download/BepInEx/BepInExPack_V_Rising/${BEPINEX_VERSION}/" \
         -O bepinex.zip && \
    unzip -q bepinex.zip && \
    rm bepinex.zip && \
    ls -la
```

### 5.2 Entrypoint.sh - Função install_bepinex()

```bash
install_bepinex() {
    if [ "${BEPINEX_ENABLED}" != "true" ]; then
        log_info "BepInEx desabilitado (BEPINEX_ENABLED=${BEPINEX_ENABLED})"
        return 0
    fi
    
    log_info "Instalando/atualizando BepInEx..."
    
    BEPINEX_SOURCE="/opt/bepinex/BepInExPack_V_Rising"
    
    # Copiar arquivos do BepInEx para o diretório do servidor
    cp -n "${BEPINEX_SOURCE}/winhttp.dll" "${SERVER_DIR}/" 2>/dev/null || true
    cp -n "${BEPINEX_SOURCE}/doorstop_config.ini" "${SERVER_DIR}/" 2>/dev/null || true
    cp -n "${BEPINEX_SOURCE}/.doorstop_version" "${SERVER_DIR}/" 2>/dev/null || true
    
    # Copiar dotnet runtime
    if [ ! -d "${SERVER_DIR}/dotnet" ]; then
        cp -r "${BEPINEX_SOURCE}/dotnet" "${SERVER_DIR}/"
    fi
    
    # Copiar BepInEx core (preservar config e plugins existentes)
    mkdir -p "${SERVER_DIR}/BepInEx"
    cp -rn "${BEPINEX_SOURCE}/BepInEx/core" "${SERVER_DIR}/BepInEx/" 2>/dev/null || true
    
    # Criar diretório de mods e symlink
    mkdir -p /data/mods
    mkdir -p "${SERVER_DIR}/BepInEx/plugins"
    
    # Copiar mods para plugins
    if [ -d "/data/mods" ] && [ "$(ls -A /data/mods 2>/dev/null)" ]; then
        cp -r /data/mods/* "${SERVER_DIR}/BepInEx/plugins/" 2>/dev/null || true
    fi
    
    log_success "BepInEx instalado!"
}
```

---

## 6. Uso

### 6.1 Habilitar Mods

```bash
# .env ou EasyPanel
BEPINEX_ENABLED=true
```

### 6.2 Adicionar Mods

1. Coloque arquivos `.dll` na pasta `mods/`
2. Reinicie o container

### 6.3 Configurar Mods

Após primeira execução, edite os arquivos em:
```
/data/server/BepInEx/config/
```

---

## 7. Mods Populares

| Mod | Categoria | Descrição |
|-----|-----------|-----------|
| **Bloodstone** | API | Framework base para outros mods |
| **VampireCommandFramework** | API | Comandos de chat customizados |
| **KindredLogistics** | QoL | Sistema de logística avançado |
| **KindredSchematics** | QoL | Blueprints de construção |
| **ServerLaunchFix** | Fix | Correções de inicialização |
| **XPRising** | Gameplay | Sistema de XP e progressão |

---

## 8. Troubleshooting

### Mods não carregam

1. Verificar: `BEPINEX_ENABLED=true`
2. Logs: `docker logs vrising-server | grep BepInEx`
3. Arquivo de log: `/data/server/BepInEx/LogOutput.log`

### Servidor trava na inicialização

1. Pode ser geração de interop (aguarde 5-10 min)
2. Se persistir, delete `/data/server/BepInEx/interop/`
3. Aumente memória para 12GB+

### Erro "winhttp.dll not found"

Verificar se BepInEx foi copiado corretamente:
```bash
docker exec vrising-server ls -la /data/server/winhttp.dll
```

---

## 9. Fluxo de Desenvolvimento

```
┌──────────────────┐
│  Docker Build    │
│  (BepInEx em     │
│  /opt/bepinex)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Container Start │
│  entrypoint.sh   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  BEPINEX_ENABLED │ NO  │  Skip BepInEx    │
│  = true?         ├────►│  Start server    │
└────────┬─────────┘     └──────────────────┘
         │ YES
         ▼
┌──────────────────┐
│  install_bepinex │
│  Copia arquivos  │
│  Configura mods  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  start_server    │
│  Wine + BepInEx  │
│  carrega mods    │
└──────────────────┘
```

---

## 10. Roadmap

- [x] Estrutura básica de suporte a mods
- [x] Documentação de uso
- [ ] Testar em ambiente real
- [ ] Avaliar patch Il2CppInterop para ARM64
- [ ] Adicionar suporte a pré-geração de interop
- [ ] Script de backup de configs de mods

---

*Documento criado em 2025-12-25. Atualizar conforme necessário.*
