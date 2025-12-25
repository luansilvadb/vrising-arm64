# SPECS-001: Fundação do Projeto V Rising ARM64

> **Status**: ✅ Implementado e Funcionando  
> **Data**: 2025-12-24  
> **Autor**: Projeto vrising-arm64

---

## 1. Visão Geral

Este projeto permite rodar o **V Rising Dedicated Server** (Windows x86_64) em servidores **ARM64** (como Oracle Cloud Ampere A1) usando emulação.

### Stack de Emulação

```
┌─────────────────────────────────────────────────────────┐
│                   VRisingServer.exe                      │
│                   (Windows x86_64)                       │
├─────────────────────────────────────────────────────────┤
│                     Wine WOW64                           │
│              (Traduz Windows → Linux)                    │
├─────────────────────────────────────────────────────────┤
│                      Box64                               │
│              (Emula x86_64 → ARM64)                      │
├─────────────────────────────────────────────────────────┤
│                   Linux ARM64                            │
│              (Host: Oracle Cloud, etc)                   │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Arquitetura de Arquivos

```
vrising-arm64/
├── Dockerfile              # Imagem Docker com Box64 + Wine + SteamCMD
├── docker-compose.yml      # Configuração para deploy
├── scripts/
│   └── entrypoint.sh       # Script de inicialização do container
├── docs/
│   └── SPECS-001-foundation.md  # Este documento
├── README.md               # Documentação para usuários
└── .env.example            # Exemplo de variáveis de ambiente
```

---

## 3. Componentes Principais

### 3.1 Dockerfile

| Componente | Versão | Propósito |
|------------|--------|-----------|
| **Base Image** | `weilbyte/box:debian-11` | Debian com Box86/Box64 pré-compilados |
| **Box64** | v0.3.8 (compilado) | Emulador x86_64 → ARM64 |
| **Wine** | 11.0-rc3 WOW64 | Camada de compatibilidade Windows |
| **SteamCMD** | Linux x86 | Download do servidor V Rising |
| **Xvfb** | - | Display virtual para Wine |

### 3.2 Entrypoint.sh

Fluxo de execução:

```
1. init_display()          → Inicia Xvfb (display virtual)
2. init_wine_fast()        → Cria Wine prefix mínimo
3. install_or_update_server() → Baixa V Rising via SteamCMD
4. configure_server()      → Cria arquivos de configuração JSON
5. start_server()          → Inicia VRisingServer.exe via Box64+Wine
```

---

## 4. Desafios Técnicos Resolvidos

### 4.1 Erro `__res_query` (CRÍTICO)

**Problema**: Wine's `dnsapi.so` chamava `__res_query` de `libresolv`, mas:
- glibc 2.34+ moveu esse símbolo para `libc.so`
- Box64 não conseguia encontrar o símbolo

**Sintoma**:
```
[BOX64] Error: Symbol __res_query not found in /opt/wine/lib/wine/x86_64-unix/dnsapi.so
```

**Solução**:
```dockerfile
# Remover dnsapi.so força Wine a usar implementação builtin
rm -f /opt/wine/lib/wine/x86_64-unix/dnsapi.so
```

**Arquivo**: `Dockerfile` (linha ~120)

---

### 4.2 SteamCMD "Missing Configuration"

**Problema**: Primeira execução do SteamCMD sempre falha com "Missing configuration"

**Causa**: Cache de configuração do app precisa ser criado antes do download

**Solução**: 
1. Pré-inicializar SteamCMD no build do Docker
2. Retry logic com mensagens claras (não é erro real)

**Arquivo**: `Dockerfile` (pré-init) + `entrypoint.sh` (retry logic)

---

### 4.3 Bibliotecas X11 Faltando

**Problema**: Wine precisava de libs X11 não incluídas na imagem base

**Sintoma**:
```
Error initializing native libXinerama.so.1
Error initializing native libXrandr.so.2
```

**Solução**:
```dockerfile
RUN apt-get install -y \
    libxinerama1 libxrandr2 libxcomposite1 \
    libxi6 libxcursor1 libcups2 libegl1
```

---

## 5. Configurações do Servidor

### 5.1 Variáveis de Ambiente (ServerHostSettings)

Estas variáveis controlam **apenas** o `ServerHostSettings.json` (infraestrutura):

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `SERVER_NAME` | V Rising Server | Nome exibido na lista |
| `SERVER_DESCRIPTION` | Servidor dedicado brasileiro | Descrição |
| `WORLD_NAME` | world1 | Nome do save |
| `PASSWORD` | (vazio) | Senha do servidor |
| `MAX_USERS` | 40 | Máximo de jogadores |
| `MAX_ADMINS` | 5 | Máximo de admins |
| `GAME_PORT` | 9876 | Porta UDP do jogo |
| `QUERY_PORT` | 9877 | Porta UDP de query |
| `LIST_ON_MASTER_SERVER` | false | Aparecer na lista Steam |
| `LIST_ON_EOS` | false | Aparecer no Epic |
| `GAME_DIFFICULTY_PRESET` | Difficulty_Brutal | Preset de dificuldade |
| `SERVER_FPS` | 60 | FPS do servidor |
| `AUTO_SAVE_COUNT` | 25 | Número de saves mantidos |
| `AUTO_SAVE_INTERVAL` | 120 | Intervalo entre saves (seg) |
| `COMPRESS_SAVE_FILES` | true | Comprimir saves |
| `RCON_ENABLED` | true | Habilitar RCON |
| `RCON_PORT` | 25575 | Porta RCON (TCP) |
| `RCON_PASSWORD` | (vazio) | Senha RCON |

### 5.2 Arquivos de Configuração

Criados em `/data/saves/Settings/`:

- `ServerHostSettings.json` - **Gerado dinamicamente** a partir das variáveis de ambiente
- `ServerGameSettings.json` - **Gerenciado via File Mount** do EasyPanel (gameplay)

---

## 6. Volumes e Persistência

```yaml
volumes:
  - vrising-data:/data   # Contém tudo:
    # /data/server/      → Binários do V Rising (~2GB)
    # /data/saves/       → Saves e configurações
    # /data/wine/        → Wine prefix
    # /data/logs/        → Logs do servidor
```

**⚠️ IMPORTANTE**: Não deletar o volume `vrising-data` ou perderá os saves!

---

## 7. Rede

### Portas Necessárias

| Porta | Protocolo | Uso |
|-------|-----------|-----|
| 9876 | **UDP** | Conexão do jogo |
| 9877 | **UDP** | Steam Query (lista de servidores) |

### Firewall/Cloud

Certifique-se de liberar UDP nas portas no:
- Security List (Oracle Cloud)
- Firewall do host (`iptables`/`ufw`)
- EasyPanel/proxy

---

## 8. Performance

### Requisitos Mínimos (ARM64)

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disco | 10 GB | 20 GB |

### Overhead de Emulação

- **Box64**: ~10-20% overhead em CPU
- **Wine**: Overhead mínimo (tradução de API)
- **Total estimado**: 70-80% da performance nativa x86

---

## 9. Troubleshooting

### Servidor não inicia

1. Verificar logs: `docker logs vrising-server`
2. Verificar se portas UDP estão abertas
3. Verificar se Wine prefix foi criado: `/data/wine/system.reg`

### Erro de memória

Aumentar limites no docker-compose:
```yaml
deploy:
  resources:
    limits:
      memory: 12G
```

### Saves corrompidos

Backups em: `/data/saves/AutoSave_*`

---

## 10. Comandos Úteis

```bash
# Ver logs em tempo real
docker logs -f vrising-server

# Entrar no container
docker exec -it vrising-server bash

# Verificar processos
docker exec vrising-server ps aux

# Backup dos saves
docker cp vrising-server:/data/saves ./backup-saves

# Reiniciar servidor
docker restart vrising-server
```

---

## 11. Histórico de Desenvolvimento

| Data | Mudança |
|------|---------|
| 2025-12-24 | Projeto inicial criado |
| 2025-12-24 | Fix crítico: remoção de `dnsapi.so` |
| 2025-12-24 | Box64 atualizado para v0.3.8 |
| 2025-12-24 | SteamCMD pré-inicialização no build |
| 2025-12-24 | Servidor funcionando! ✅ |

---

## 12. Links Úteis

- [V Rising Dedicated Server Guide](https://github.com/StunlockStudios/vrising-dedicated-server-instructions)
- [Box64 GitHub](https://github.com/ptitSeb/box64)
- [Wine WOW64](https://wiki.winehq.org/Wine64)
- [Kron4ek Wine Builds](https://github.com/Kron4ek/Wine-Builds)

---

*Documento gerado em 2025-12-24. Atualizar conforme necessário.*
