# 🧛 V Rising Dedicated Server - ARM64 Docker

[![Docker](https://img.shields.io/badge/Docker-ARM64-blue?logo=docker)](https://www.docker.com/)
[![V Rising](https://img.shields.io/badge/V%20Rising-Dedicated%20Server-red)](https://store.steampowered.com/app/1604030/V_Rising/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Servidor dedicado de **V Rising** otimizado para rodar em **ARM64** (Oracle Cloud Ampere A1, Raspberry Pi 5, Orange Pi 5, etc.) usando Docker com **Box64/Box86 + Wine** para emulação.

## 📋 Requisitos

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| **CPU** | 2 cores ARM64 | 4 cores ARM64 |
| **RAM** | 8 GB | 16-24 GB |
| **Disco** | 10 GB | 20 GB SSD |
| **SO** | Ubuntu 20.04 ARM64 | Ubuntu 22.04+ ARM64 |

> ⚠️ **Nota**: Este servidor usa emulação x86/x64 via Box64/Box86, o que adiciona overhead de ~20-40% de CPU comparado a um servidor nativo.

## 🚀 Deploy Rápido

### Opção 1: EasyPanel (Recomendado)

1. **Fork/Clone este repositório** para sua conta GitHub

2. **No EasyPanel**, crie um novo serviço:
   - Tipo: `Docker`
   - Source: `GitHub`
   - Repositório: `seu-usuario/vrising-arm64`
   - Branch: `main`

3. **Configure as variáveis de ambiente**:
   ```
   SERVER_NAME=Meu Servidor V Rising
   WORLD_NAME=world1
   PASSWORD=minhasenha
   MAX_USERS=40
   GAME_PORT=9876
   QUERY_PORT=9877
   RCON_PASSWORD=senhaforte123
   TZ=America/Sao_Paulo
   ```

4. **Configure as portas** (UDP):
   - `9876` → Game Port
   - `9877` → Query Port

5. **Configure os volumes** para persistência:
   - `/data/server` → Arquivos do servidor
   - `/data/saves` → Saves do mundo

6. **Deploy!** 🎉

### Opção 2: Docker Compose

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/vrising-arm64.git
cd vrising-arm64

# Copie e configure o arquivo .env
cp .env.example .env
nano .env

# Inicie o servidor
docker compose up -d

# Veja os logs
docker compose logs -f
```

### Opção 3: Docker CLI

docker run -d \
  --name vrising-server \
  --restart unless-stopped \
  -e SERVER_NAME="Meu Servidor" \
  -e WORLD_NAME="world1" \
  -e PASSWORD="minhasenha" \
  -e MAX_USERS="40" \
  -e RCON_PASSWORD="senhaforte123" \
  -p 9876:9876/udp \
  -p 9877:9877/udp \
  -p 25575:25575/tcp \
  -v vrising-data:/data \
  seu-usuario/vrising-arm64
```

## ⚙️ Variáveis de Ambiente

Estas variáveis controlam **apenas** o `ServerHostSettings.json` (infraestrutura do servidor).
Para configurações de **gameplay**, use o File Mount do EasyPanel com `ServerGameSettings.json`.

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `SERVER_NAME` | `V Rising Server` | Nome do servidor |
| `SERVER_DESCRIPTION` | `Servidor dedicado brasileiro` | Descrição |
| `WORLD_NAME` | `world1` | Nome do save/mundo |
| `PASSWORD` | ` ` (vazio) | Senha do servidor |
| `MAX_USERS` | `40` | Máximo de jogadores |
| `MAX_ADMINS` | `5` | Máximo de admins |
| `GAME_PORT` | `9876` | Porta do jogo (UDP) |
| `QUERY_PORT` | `9877` | Porta de query (UDP) |
| `LIST_ON_MASTER_SERVER` | `false` | Listar no Steam |
| `LIST_ON_EOS` | `false` | Listar no EOS |
| `GAME_DIFFICULTY_PRESET` | `Difficulty_Brutal` | Preset de dificuldade |
| `SERVER_FPS` | `60` | FPS do servidor |
| `AUTO_SAVE_COUNT` | `25` | Número de saves mantidos |
| `AUTO_SAVE_INTERVAL` | `120` | Intervalo entre saves (segundos) |
| `COMPRESS_SAVE_FILES` | `true` | Comprimir saves |
| `RCON_ENABLED` | `true` | Habilitar RCON |
| `RCON_PORT` | `25575` | Porta RCON (TCP) |
| `RCON_PASSWORD` | ` ` (vazio) | Senha RCON |
| `AUTO_UPDATE` | `true` | Atualizar servidor no restart |
| `TZ` | `America/Sao_Paulo` | Timezone |

## 📁 Estrutura de Diretórios

```
/data/
├── server/          # Arquivos do servidor V Rising
├── saves/           # Saves do mundo
│   └── Settings/    # Configurações do servidor
│       ├── ServerHostSettings.json
│       └── ServerGameSettings.json
└── logs/            # Logs do servidor
```

## 🔧 Configurações Avançadas

### 💀 Modo Brutal (Dificuldade)

O servidor vem configurado com **Difficulty_Brutal** por padrão. Você pode alterar via variável de ambiente:

| Preset | Descrição |
|--------|----------|
| `Difficulty_Easy` | Inimigos mais fracos, ideal para iniciantes |
| `Difficulty_Normal` | Balanceamento padrão do jogo |
| `Difficulty_Brutal` | Modo hardcore - desafiador! |

#### O que muda no Brutal?

| Modificador | Valor | Efeito |
|-------------|-------|--------|
| **Inimigos (todos)** | | |
| `PowerModifier` | 1.4 | +40% de dano |
| **Bosses V Blood** | | |
| `MaxHealthModifier` | 1.25 | +25% de vida |
| `PowerModifier` | 1.7 | +70% de dano |
| `LevelIncrease` | 3 | +3 níveis acima do normal |

### ServerHostSettings.json

Para configurações avançadas do host, edite `/data/saves/Settings/ServerHostSettings.json`:

```json
{
  "Name": "Meu Servidor",
  "Description": "Servidor épico de V Rising!",
  "Port": 9876,
  "QueryPort": 9877,
  "MaxConnectedUsers": 40,
  "Password": "minhasenha",
  "GameDifficultyPreset": "Difficulty_Brutal",
  "ListOnMasterServer": true,
  "Rcon": {
    "Enabled": true,
    "Port": 25575,
    "Password": "rconpassword"
  }
}
```

### ServerGameSettings.json

Para configurações de gameplay, edite `/data/saves/Settings/ServerGameSettings.json`:

```json
{
  "GameModeType": "PvP",
  "ClanSize": 4,
  "BloodDrainModifier": 1.0,
  "DurabilityDrainModifier": 1.0,
  "MaterialYieldModifier_Global": 1.0,
  "CraftRateModifier": 1.0
}
```

### 📝 Manutenção via EasyPanel (File Mount)

Para editar configurações diretamente no EasyPanel:

1. **Adicionar File Mount**:
   - No EasyPanel, vá em **Mounts** → **Add File Mount**
   - Caminho: `/data/saves/Settings/ServerGameSettings.json`
   - Conteúdo: Copie de `config/ServerGameSettings.json` deste repositório

2. **Editar configurações**:
   - Clique em **Edit** no File Mount
   - Faça suas alterações
   - Clique em **Save**
   - **Reinicie o container** para aplicar

3. **Fazer backup**:
   - Copie o conteúdo do File Mount
   - Cole em `config/ServerGameSettings.json` no repositório
   - Commit e push para o GitHub

> 💡 **Dica**: O arquivo `config/` contém templates prontos para uso!

## 🌐 Conectando ao Servidor

### Conexão Direta

1. Abra V Rising
2. Vá em **Play** → **Online Play** → **Direct Connect**
3. Digite o IP do seu servidor e a porta: `ip:9876`
4. Conecte!

### Lista de Servidores

Se você habilitou `LIST_ON_MASTER_SERVER=true`:
1. Abra V Rising
2. Vá em **Play** → **Online Play** → **Find Servers**
3. Procure pelo nome do seu servidor

## 🛠️ Manutenção

### Ver Logs

```bash
docker compose logs -f vrising
```

### Reiniciar Servidor

```bash
docker compose restart vrising
```

### Atualizar Servidor

O servidor é atualizado automaticamente na inicialização via SteamCMD.

Para forçar uma atualização:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Backup dos Saves

```bash
# Criar backup
docker compose exec vrising tar -czvf /tmp/backup.tar.gz /data/saves
docker cp vrising-server:/tmp/backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz
```

## 🐛 Troubleshooting

### Servidor não inicia

1. Verifique os logs:
   ```bash
   docker compose logs -f vrising
   ```

2. Verifique se as portas estão liberadas:
   ```bash
   nc -vzu localhost 9876
   ```

3. Verifique se há memória suficiente:
   ```bash
   docker stats vrising-server
   ```

### Jogadores não conseguem conectar

1. Verifique se as portas UDP estão abertas no firewall:
   - Oracle Cloud: Security Lists → Ingress Rules
   - UFW: `sudo ufw allow 9876:9877/udp`

2. Verifique se o servidor está ouvindo:
   ```bash
   docker compose exec vrising netstat -ulnp
   ```

### Performance lenta

A emulação via Box64/Wine adiciona overhead. Considere:
- Aumentar limites de RAM no docker-compose.yml
- Usar instância com mais cores ARM64
- Reduzir `MAX_USERS`

## 📊 Estrutura do Projeto

```
vrising-arm64/
├── Dockerfile           # Imagem Docker ARM64
├── docker-compose.yml   # Compose para EasyPanel
├── .env.example         # Variáveis de exemplo
├── .gitignore           # Arquivos ignorados
├── config/              # 📁 Templates para EasyPanel File Mount
│   ├── ServerGameSettings.json   # Configurações de gameplay
│   ├── ServerHostSettings.json   # Configurações do host (backup)
│   └── README.md                 # Documentação dos configs
├── scripts/
│   └── entrypoint.sh    # Script de inicialização
└── README.md            # Esta documentação
```

## 🙏 Créditos

- [Box64](https://github.com/ptitSeb/box64) - Emulador x86_64 para ARM64
- [Box86](https://github.com/ptitSeb/box86) - Emulador x86 para ARM
- [Wine](https://www.winehq.org/) - Camada de compatibilidade Windows
- [Stunlock Studios](https://www.stunlockstudios.com/) - Desenvolvedores do V Rising
- [TrueOsiris/docker-vrising](https://github.com/TrueOsiris/docker-vrising) - Inspiração

## 📄 Licença

MIT License - Veja [LICENSE](LICENSE) para mais detalhes.

---

**Feito com 🧛 por vampiros para vampiros!**
