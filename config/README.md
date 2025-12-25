# 📁 Arquivos de Configuração - V Rising Server

Esta pasta contém os **templates de configuração** para uso com EasyPanel File Mount.

## 🎯 Como Usar no EasyPanel

### 1. ServerGameSettings.json (Configurações de Gameplay)

No EasyPanel, adicione um **File Mount**:
- **Tipo**: File
- **Caminho do Container**: `/data/saves/Settings/ServerGameSettings.json`
- **Conteúdo**: Copie o conteúdo de `ServerGameSettings.json` deste repositório

### 2. ServerHostSettings.json (Configurações do Host)

⚠️ **Nota**: Este arquivo é gerado automaticamente pelo servidor usando as variáveis de ambiente.
Use o template apenas como **referência** ou para **backup**.

---

## 📋 Configurações Principais

### ServerGameSettings.json

| Configuração | Padrão | Descrição |
|-------------|--------|-----------|
| `GameModeType` | `PvP` | Modo de jogo: `PvP` ou `PvE` |
| `ClanSize` | `10` | Tamanho máximo do clã |
| `CastleDamageMode` | `Always` | Quando castelos podem ser atacados |
| `PlayerDamageMode` | `Always` | Quando jogadores podem se atacar |
| `MaterialYieldModifier_Global` | `1.0` | Multiplicador de recursos |
| `CraftRateModifier` | `1.0` | Velocidade de crafting |

### Configurações de Tempo (PlayerInteractionSettings)

| Configuração | Valor | Descrição |
|-------------|-------|-----------|
| `VSPlayerWeekdayTime` | 17:00-23:00 | Horário PvP dias úteis |
| `VSPlayerWeekendTime` | 17:00-23:00 | Horário PvP fim de semana |
| `VSCastleWeekdayTime` | 17:00-23:00 | Horário cerco dias úteis |
| `VSCastleWeekendTime` | 17:00-23:00 | Horário cerco fim de semana |

---

## 🔄 Workflow de Manutenção

### Para editar configurações:

1. **No EasyPanel** → Clique em "Edit" no File Mount
2. Faça suas alterações
3. **Reinicie o container** para aplicar

### Para fazer backup:

1. Copie o conteúdo do File Mount
2. Cole neste repositório em `config/ServerGameSettings.json`
3. Commit e push para o GitHub

### Para restaurar:

1. Copie o conteúdo de `config/ServerGameSettings.json`
2. Cole no File Mount do EasyPanel
3. Reinicie o container

---

## 💀 Modo Brutal

O servidor está configurado para usar `Difficulty_Brutal` por padrão.

A dificuldade é definida no `ServerHostSettings.json` via variável `GAME_DIFFICULTY_PRESET`:
- `Difficulty_Easy` - Fácil
- `Difficulty_Normal` - Normal
- `Difficulty_Brutal` - Brutal (+40% dano inimigos, bosses +25% HP, +70% dano, +3 níveis)

---

## 📖 Documentação Oficial

- [Instruções Oficiais Stunlock](https://github.com/StunlockStudios/vrising-dedicated-server-instructions)
- [Wiki V Rising](https://vrising.fandom.com/wiki/V_Rising_Wiki)

---

## 🔧 emulators.rc (Configurações de Emuladores)

Este arquivo permite ajustar as configurações do Box64/FEX para otimizar compatibilidade e performance.

### Localização
- **Template**: `config/emulators.rc` (incluído no build)
- **Runtime**: `/data/saves/Settings/emulators.rc` (persistente, editável)

### Configurações Disponíveis

```bash
# Box64 - Compatibilidade vs Performance
BOX64_DYNAREC_STRONGMEM=1  # 1 = mais compatível, 0 = mais rápido
BOX64_DYNAREC_BIGBLOCK=0   # 0 = blocos menores/mais seguro, 1 = otimizado

# FEX-Emu (alternativa ao Box64)
FEX_PARANOIDTSO=true       # true = mais compatível
```

### Documentação Detalhada
- [Box64 Usage Guide](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)
- [FEX-Emu Config](https://github.com/FEX-Emu/FEX/blob/main/FEXCore/Source/Interface/Config/Config.json.in)

