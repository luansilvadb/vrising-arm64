# 🏭 KindredLogistics - O Castelo Industrial

> **"Automatize seu castelo como um jogador de Modded Minecraft"**

---

## 📋 Visão Geral

**KindredLogistics** é o mod de qualidade de vida mais transformador para servidores V Rising. Ele transforma o gerenciamento de inventário manual em um sistema automatizado elegante - semelhante ao Applied Energistics ou Refined Storage do Minecraft.

### Por que usar?

| Problema Vanilla | Solução KindredLogistics |
|------------------|--------------------------|
| 30% do tempo gasto organizando inventário | Quick Stash em 1 segundo |
| Carregar recursos para cada estação | Pull direto dos baús |
| Esquecer de abastecer brazeiros | Auto-refill automático |
| Itens de missões bagunçados | Servants auto-stash para baús "spoils" |
| Não saber onde guardou algo | `.finditem` para localizar qualquer coisa |

---

## 📦 Dependências

O KindredLogistics precisa destes mods instalados **antes**:

| Mod | Versão | Download |
|-----|--------|----------|
| BepInExPack V Rising | ≥1.691.3 | ✅ Já incluído no projeto |
| VampireCommandFramework | ≥0.9.0 | [Thunderstore](https://thunderstore.io/c/v-rising/p/deca/VampireCommandFramework/) |

---

## 🚀 Instalação

### Passo 1: Baixar os Mods

Baixe estes arquivos `.dll`:

1. **VampireCommandFramework.dll**
   - https://thunderstore.io/c/v-rising/p/deca/VampireCommandFramework/

2. **KindredLogistics.dll** (v1.5.4)
   - https://thunderstore.io/c/v-rising/p/odjit/KindredLogistics/

### Passo 2: Instalar

Coloque os arquivos na pasta `mods/`:

```
vrising-arm64/
└── mods/
    ├── VampireCommandFramework.dll  # Dependência
    └── KindredLogistics.dll          # Mod principal
```

### Passo 3: Reiniciar

```bash
docker compose restart vrising
```

---

## 🎮 Funcionalidades

### 1. Quick Stash (O Game-Changer)

**O que faz**: Deposita automaticamente itens do inventário em baús que já contêm aquele tipo de item.

**Como usar**:
- Abra o inventário e **pressione R duas vezes rapidamente**
- OU **clique duas vezes no botão Sort**
- OU use o comando `.stash`

> 💡 **Impacto**: Elimina ~30% do tempo gasto em "Inventory Tetris"

---

### 2. Craft Pulling (Rede de Recursos)

**O que faz**: Puxa recursos automaticamente dos baús próximos para crafting.

**Como usar**:
- Em qualquer estação de crafting
- **Clique com botão direito** na receita
- Recursos são puxados automaticamente dos baús do território

> 💡 **Impacto**: Transforma o castelo em uma "rede de recursos" unificada

---

### 3. Auto-Salvage (Reciclagem Automática)

**O que faz**: Itens colocados em um baú especial são automaticamente enviados para o Devourer.

**Como configurar**:
1. Coloque um baú perto do Devourer
2. **Renomeie** o baú para: `salvage`
3. Qualquer item colocado nele será reciclado automaticamente

---

### 4. Auto-Refill Brazeiros

**O que faz**: Abastece automaticamente Brazeiros com fuel de um baú central.

**Como configurar**:
1. Coloque um baú perto dos brazeiros
2. **Renomeie** o baú para: `brazier`
3. Brazeiros serão reabastecidos automaticamente

**Modos especiais de brazeiro** (renomeie o brazeiro):
- `night` - Sempre ligado (decorativo)
- `prox` - Liga apenas quando jogadores estão perto (economia)

---

### 5. Auto-Refill Spawners

**O que faz**: Abastece automaticamente Tombs, Vermin Nests e Stygian Spawners.

**Como configurar**:
1. Coloque um baú perto dos spawners
2. **Renomeie** o baú para: `spawner`
3. Spawners serão reabastecidos com bones/flowers automaticamente

---

### 6. Servant Auto-Stash

**O que faz**: Servants depositam automaticamente os itens de missões em baús designados.

**Como configurar**:
1. Coloque um baú na área do castelo
2. **Renomeie** o baú para: `spoils`
3. Servants retornando de missões depositarão loot automaticamente

---

### 7. Find Item

**O que faz**: Localiza em qual baú um item está guardado.

**Como usar**:
```
.finditem iron
.finditem leather
.finditem blood essence
```

---

### 8. Conveyor System (Chain Crafting)

**O que faz**: Cria uma "esteira" entre baús e estações para crafting em cadeia.

**Exemplo de uso**:
```
Baú de Madeira → Serraria → Baú de Tábuas → Carpintaria → Baú de Móveis
```

> 📖 Veja detalhes completos no [Wiki oficial](https://github.com/Odjit/KindredLogistics/wiki)

---

## ⚙️ Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `.stash` | Deposita itens nos baús apropriados |
| `.finditem <nome>` | Localiza um item nos baús |
| `.sort` | Organiza o inventário atual |

> ⚠️ Use esses comandos **no chat do jogo** (pressione Enter)

---

## 📝 Configuração

Após a primeira execução, o arquivo de configuração aparece em:
```
/data/server/BepInEx/config/KindredLogistics.cfg
```

Configurações disponíveis:
- Habilitar/desabilitar funcionalidades
- Raio de busca de baús
- Intervalo de auto-refill
- E mais...

---

## 🔗 Links

- [GitHub - KindredLogistics](https://github.com/Odjit/KindredLogistics)
- [Wiki Oficial](https://github.com/Odjit/KindredLogistics/wiki)
- [Thunderstore](https://thunderstore.io/c/v-rising/p/odjit/KindredLogistics/)
- [Discord V Rising Modding](https://vrisingmods.com/discord)

---

## ✅ Compatibilidade

| Componente | Status |
|------------|--------|
| V Rising 1.1 | ✅ Suportado (v1.5.4) |
| ARM64/Box64 | ✅ Server-side, funciona |
| Multiplayer | ✅ Apenas servidor precisa do mod |

---

*Guia criado para o projeto vrising-arm64 em 2025-12-25*
