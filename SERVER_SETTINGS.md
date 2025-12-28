# 🧛 V Rising Server - MMO Hardcore

> **"MMO Hardcore"** - Servidor PVP/PVE estilo MMO onde solo é brutal, grupos são essenciais, e NINGUÉM é one-shot.

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Filosofia do Servidor](#filosofia-do-servidor)
- [Configurações PVP](#configurações-pvp)
- [Configurações PVE](#configurações-pve)
- [Economia e Recursos](#economia-e-recursos)
- [Sistema de Castelos](#sistema-de-castelos)
- [Siege e Raides](#siege-e-raides)
- [Hazards Ambientais](#hazards-ambientais)
- [Ciclo Dia/Noite](#ciclo-dianoite)
- [Eventos](#eventos)
- [Penalidades de Morte](#penalidades-de-morte)
- [Soul Shards](#soul-shards)
- [Progressão Esperada](#progressão-esperada)
- [Referência Técnica](#referência-técnica)

---

## 🎯 Visão Geral

| Aspecto | Configuração |
|---------|--------------|
| **Modo de Jogo** | PvP |
| **Dificuldade** | MMO Hardcore (v4.0.0) |
| **Tamanho do Clã** | 10 membros |
| **Castelos por Jogador** | 1 |
| **Loot ao Morrer** | Equipamento protegido |
| **Siege** | Horários Restritos |
| **Rates** | 1.5x - 2x (Balanceado) |
| **Boss HP** | 8.0x (lutas ÉPICAS!) |
| **Boss Dano** | ~2x (punitivo mas justo) |

---

## 💀 Filosofia do Servidor

### Os 7 Pilares do Servidor MMO Hardcore

1. **👥 GRUPOS SÃO ESSENCIAIS** - Solo é brutal, grupos são o caminho
2. **💪 NÃO É ONE-SHOT** - Difícil sim, impossível não
3. **⏱️ LUTAS ÉPICAS** - Bosses com 8x HP + jogadores com -40% dano = 35-50 min de combate
4. **📈 ESCALA PROGRESSIVA** - Mais gente = mais HP do boss, mas sempre vale a pena
5. **🏰 Castelos são ÚNICOS** - 1 por jogador, podem ser roubados
6. **🌙 Ambiente é PERIGOSO** - Blood drena 50% mais rápido, durabilidade 2x
7. **💎 Soul Shards são REI** - Objetivo endgame que força PVP aberto

---

## ⚔️ Configurações PVP

### Combate entre Jogadores

| Setting | Valor | Descrição |
|---------|-------|-----------|
| `GameModeType` | PvP | Modo PVP ativado |
| `PlayerDamageMode` | Always | PVP liberado 24/7 |
| `BloodBoundEquipment` | **true** | ✅ Mantém equipamento ao morrer |
| `DeathContainerPermission` | Anyone | Qualquer um pode lootar seu corpo |
| `CanLootEnemyContainers` | true | Pode saquear baús inimigos |
| `PvPProtectionMode` | Short | Proteção curta para novatos |
| `PvPVampireRespawnModifier` | 1.5 | Respawn 50% mais lento (~67s) |

### Horários de PVP por Jogador (Horário CLT)

| Dia | Início | Fim | Duração |
|-----|--------|-----|--------|
| **Seg-Sex** | 18:00 | 23:59 | 6 horas |
| **Sáb-Dom** | 10:00 | 23:59 | 14 horas |

> ⚠️ **Nota:** Horários adaptados para CLT - após expediente comercial (8h-18h).

---

## 👹 Configurações PVE

### Inimigos Comuns (Global)

| Modifier | Valor | Efeito |
|----------|-------|--------|
| `MaxHealthModifier` | **2.0** | Mobs têm 2x HP |
| `PowerModifier` | **1.5** | +50% dano |

### V Blood Bosses - Sistema "MMO Hardcore"

| Modifier | Valor | Efeito |
|----------|-------|--------|
| `MaxHealthModifier` | **8.0** | Bosses têm 8x HP (lutas ÉPICAS!) |
| `PowerModifier` | **1.75** | +75% dano (punitivo mas justo) |
| `LevelIncrease` | **3** | Bosses +3 níveis acima |

### Vampiro (Jogador) - Redução de Dano

| Modifier | Valor | Efeito |
|----------|-------|--------|
| `PhysicalPowerModifier` | **0.6** | -40% dano físico do jogador |
| `SpellPowerModifier` | **0.6** | -40% dano mágico do jogador |

> 🛡️ **Resultado Combinado:** Boss com 8x HP + Jogador com 60% dano = Boss **~13x mais tanky** que o normal!

### 🎯 Sistema de Escalonamento Dinâmico (NATIVO DO JOGO)

> **DESCOBERTA IMPORTANTE:** O V Rising possui escalonamento **AUTOMÁTICO** baseado no número de jogadores em combate!

| Jogadores em Combate | HP do Boss | Mecânicas Extras |
|---------------------|------------|------------------|
| **1 (Solo)** | Base (1.15x) | Padrão |
| **2 (Duo)** | **+66% auto** (1.91x) | Mais adds/projectiles |
| **3 (Trio)** | **+132% auto** (2.67x) | Frequência de habilidades ↑ |
| **4+ (Raid)** | **+200%+ auto** (3.45x+) | 💀 Mecânicas de raid exclusivas |

> ⚡ **FILOSOFIA MMO HARDCORE:**
> - **Solo:** BRUTAL - Quase impossível sem gear perfeito e skill extrema
> - **Duo:** Difícil mas possível - Coordenação é essencial
> - **Trio:** Desafiador - Margem para erros, roles naturais emergem
> - **Quartet+:** Sweet spot - Experiência MMO saudável e estável
> - **Dracula:** Level 94 - RAID obrigatório, solo-viável apenas para top 1%

### Tabela de Bosses (Levels com +0 Adaptive Brutal)

#### Farbane Woods (Solo Recomendado)
| Boss | Level Base | Level Brutal | Solo | Duo | Trio+ |
|------|-----------|--------------|------|-----|-------|
| Alpha the White Wolf | 16 | **16** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Keely the Frost Archer | 20 | **20** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Errol the Stonebreaker | 20 | **20** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Rufus the Foreman | 20 | **20** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Grayson the Armourer | 27 | **27** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Goreswine the Ravager | 27 | **27** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Lidia the Chaos Archer | 30 | **30** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Clive the Firestarter | 30 | **30** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Nibbles the Putrid Rat | 30 | **30** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Finn the Fisherman | 32 | **32** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Polora the Feywalker | 35 | **35** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💀 |
| Kodia the Ferocious Bear | 35 | **35** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💀 |
| Nicholaus the Fallen | 35 | **35** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💀 |
| Quincey the Bandit King | 37 | **37** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💀 |
| Tristan the Vampire Hunter | 46 | **46** | ⭐⭐⭐⭐⭐ | 💀 | 💀💀 |

#### Dunley Farmlands (Solo Difícil / Duo Recomendado)
| Boss | Level Base | Level Brutal | Solo | Duo | Trio+ |
|------|-----------|--------------|------|-----|-------|
| Beatrice the Tailor | 40 | **40** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💀 |
| Vincent the Frostbringer | 44 | **44** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💀 |
| Christina the Sun Priestess | 44 | **44** | ⭐⭐⭐⭐⭐ | 💀 | 💀💀 |
| Kriig the Undead General | 47 | **47** | ⭐⭐⭐⭐⭐ | 💀 | 💀💀 |
| Leandra the Shadow Priestess | 47 | **47** | ⭐⭐⭐⭐⭐ | 💀 | 💀💀 |
| Maja the Dark Savant | 47 | **47** | ⭐⭐⭐⭐⭐ | 💀 | 💀💀 |
| Bane the Shadowblade | 50 | **50** | 💀 Solo Raid | 💀💀 | 💀💀💀 |
| Grethel the Glassblower | 50 | **50** | ⭐⭐⭐⭐⭐ | 💀 | 💀💀 |
| Meredith the Bright Archer | 50 | **50** | 💀 Solo Raid | 💀💀 | 💀💀💀 |
| Terah the Geomancer | 53 | **53** | 💀 Solo Raid | 💀💀 | 💀💀💀 |
| General Elena the Hollow | 53 | **53** | 💀 Solo Raid | 💀💀 | 💀💀💀 |
| General Cassius the Betrayer | 57 | **57** | 💀 Solo Raid | 💀💀 | 💀💀💀 |
| Jade the Vampire Hunter | 57 | **57** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Raziel the Shepherd | 57 | **57** | 💀 Solo Raid | 💀💀 | 💀💀💀 |
| Octavian the Militia Captain | 58 | **58** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |

#### Silverlight Hills (Solo Extremo / Duo+ Recomendado)
| Boss | Level Base | Level Brutal | Solo | Duo | Trio+ |
|------|-----------|--------------|------|-----|-------|
| Mairwyn the Elementalist | 70 | **70** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Morian the Stormwing Matriarch | 70 | **70** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Baron du Bouchon the Sommelier | 70 | **70** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Azariel the Sunbringer | 79 | **79** | 💀💀💀 Epic | 💀💀💀💀 | 💀💀💀💀💀 |
| Voltatia the Power Master | 79 | **79** | 💀💀💀 Epic | 💀💀💀💀 | 💀💀💀💀💀 |
| Solarus the Immaculate | 86 | **86** | 💀💀💀💀 Legendary | 💀💀💀💀💀 | ☠️ RAID |

#### Gloomrot (Solo Extremo / Grupo Recomendado)
| Boss | Level Base | Level Brutal | Solo | Duo | Trio+ |
|------|-----------|--------------|------|-----|-------|
| Ziva the Engineer | 60 | **60** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Domina the Blade Dancer | 60 | **60** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Angram the Purifier | 61 | **61** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Henry Blackbrew the Doctor | 74 | **74** | 💀💀💀 Epic | 💀💀💀💀 | 💀💀💀💀💀 |
| The Winged Horror (Talzur) | 86 | **86** | 💀💀💀💀 Legendary | 💀💀💀💀💀 | ☠️ RAID |
| Adam the Firstborn | 88 | **88** | 💀💀💀💀 Legendary | 💀💀💀💀💀 | ☠️ RAID |

#### Cursed Forest (Solo Extremo / Duo+ Recomendado)
| Boss | Level Base | Level Brutal | Solo | Duo | Trio+ |
|------|-----------|--------------|------|-----|-------|
| Ungora the Spider Queen | 63 | **63** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Foulrot the Soultaker | 63 | **63** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Albert the Duke of Balaton | 64 | **64** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Willfred the Werewolf Chief | 64 | **64** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Cyril the Cursed Smith | 65 | **65** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| Matka the Curse Weaver | 76 | **76** | 💀💀💀 Epic | 💀💀💀💀 | 💀💀💀💀💀 |
| Gorecrusher the Behemoth | 84 | **84** | 💀💀💀💀 Legendary | 💀💀💀💀💀 | ☠️ RAID |
| Lord Styx the Night Champion | 84 | **84** | 💀💀💀💀 Legendary | 💀💀💀💀💀 | ☠️ RAID |

#### Mortium (Solo Legendary / Raid Recomendado)
| Boss | Level Base | Level Brutal | Solo | Duo | Trio+ |
|------|-----------|--------------|------|-----|-------|
| Sir Magnus the Overseer | 66 | **66** | 💀💀 Hard | 💀💀💀 | 💀💀💀💀 |
| General Valencia the Depraved | 84 | **84** | 💀💀💀💀 Legendary | 💀💀💀💀💀 | ☠️ RAID |
| Megara the Serpent Queen | 88 | **88** | 💀💀💀💀💀 TITAN | ☠️ RAID | ☠️☠️ EPIC RAID |
| **Dracula the Immortal King** | 91 | **91** | ☠️ SOLO RAID | ☠️☠️ EPIC | ☠️☠️☠️ LEGENDARY |

---

## 💰 Economia e Recursos

### Rates de Coleta

| Recurso | Multiplicador | Impacto |
|---------|---------------|---------|
| `MaterialYieldModifier_Global` | **1.5x** | +50% recursos de mineração |
| `DropTableModifier_Resources` | **2.0x** | +100% drops de recursos (Mitigação de Gruel) |
| `DropTableModifier_Missions` | **1.5x** | +50% loot de missões de servos |
| `DropTableModifier_General` | **1.5x** | +50% drops gerais (facilita farm) |
| `BloodEssenceYieldModifier` | **1.5x** | +50% Blood Essence |

> 🧪 **Mitigação de Irradiant Gruel:** Como a chance de sucesso da poção de sangue é fixa no código do jogo, aumentamos drasticamente os drops de recursos (`2.0x`) para que perder um prisioneiro ou falhar na mutação seja menos doloroso. "Se a roleta é viciada, jogue com mais fichas."

### Rates de Crafting

| Atividade | Multiplicador | Impacto |
|-----------|---------------|---------|
| `CraftRateModifier` | **2.0x** | Craft 2x mais rápido |
| `RefinementRateModifier` | **2.0x** | Refinamento 2x mais rápido |
| `ResearchTimeModifier` | **0.75x** | Pesquisa 25% mais rápida |
| `ServantConvertRateModifier` | **1.5x** | Conversão de servos +50% |

### Custos

| Custo | Multiplicador | Impacto |
|-------|---------------|---------|
| `BuildCostModifier` | 1.0x | Custo normal de construção |
| `RecipeCostModifier` | 1.0x | Custo normal de receitas |
| `ResearchCostModifier` | 1.0x | Custo normal de pesquisa |
| `RefinementCostModifier` | 1.0x | Custo normal de refinamento |
| `RepairCostModifier` | **1.25x** | +25% custo de reparo |
| `DismantleResourceModifier` | 0.75x | 75% recursos ao desmontar |

### Inventário

| Setting | Valor | Impacto |
|---------|-------|---------|
| `InventoryStacksModifier` | **2.0x** | Stacks 2x maiores |

> 💡 **Filosofia:** Economia 1.5x significa que recursos são **valiosos mas não raros**. Isso incentiva disputas por territórios sem tornar o grind excessivo.

---

## 🏰 Sistema de Castelos

### Limites Gerais

| Setting | Valor | Descrição |
|---------|-------|-----------|
| `CastleLimit` | **1** | 1 castelo por jogador |
| `CastleMinimumDistanceInFloors` | 3 | Distância mínima entre castelos |
| `SafetyBoxLimit` | 1 | 1 cofre seguro |
| `TombLimit` | **6** | 6 tumbas (menos revives) |
| `VerminNestLimit` | **2** | 2 ninhos (menos farm passivo) |

### Limites por Nível do Coração

| Nível | Floors | Servos |
|-------|--------|--------|
| **Level 1** | 40 | **5** |
| **Level 2** | 100 | **9** |
| **Level 3** | 180 | **13** |
| **Level 4** | 280 | **17** |
| **Level 5** | 400 | **22** |

### Penalidades de Pylon (Múltiplos Hearts)

| Pylons | Penalidade |
|--------|------------|
| 0-2 | 0% |
| 3 | **10%** |
| 4 | **25%** |
| 5 | **40%** |
| 6+ | **60%** |

### Penalidades de Floor (Expansão)

| Floors | Penalidade |
|--------|------------|
| 0-20 | 0% |
| 21-40 | **10%** |
| 41-60 | **25%** |
| 61-100 | **40%** |
| 101+ | **60%** |

### Manutenção do Castelo

| Setting | Valor | Impacto |
|---------|-------|---------|
| `CastleDecayRateModifier` | **0.5x** | Decay 50% mais lento |
| `CastleBloodEssenceDrainModifier` | **1.25x** | +25% uso de Blood Essence |

> 💡 **Strategia:** Castelos menores (max 120 floors) e menos servos (max 5) forçam escolhas estratégicas. Servos são investimentos valiosos, não farm infinito.

---

## ⚔️ Siege e Raides

### Configurações de Siege

| Setting | Valor | Descrição |
|---------|-------|-----------|
| `CastleDamageMode` | **TimeRestricted** | Dano apenas em horários |
| `CastleHeartDamageMode` | **CanBeSeizedOrDestroyedByPlayers** | ⚠️ Castelos podem ser ROUBADOS |
| `SiegeWeaponHealth` | **High** | Golems mais resistentes |
| `CastleSiegeTimer` | **600s** (10 min) | Tempo para organizar defesa |
| `CastleUnderAttackTimer` | 90s | Notificação de ataque |
| `AnnounceSiegeWeaponSpawn` | true | Anuncia spawn de golem |
| `ShowSiegeWeaponMapIcon` | true | Mostra golem no mapa |

### Horários de Siege (CLT - Após Expediente)

#### Dias de Semana (Segunda a Sexta)
| Tipo | Início | Fim | Duração |
|------|--------|-----|--------|
| Siege Castle | **20:00** | **23:00** | 3 horas |

#### Fim de Semana (Sábado e Domingo)
| Tipo | Início | Fim | Duração |
|------|--------|-----|--------|
| Siege Castle | **15:00** | **23:00** | 8 horas |

> ⚠️ **IMPORTANTE:** `CanBeSeizedOrDestroyedByPlayers` significa que ao destruir um Castle Heart inimigo, você pode **ROUBAR** o castelo ao invés de apenas destruí-lo!

### Dicas de Defesa

1. **Servants defensivos:** Lightweavers, Paladins, Clerics
2. **Esvaziar inventário** de servos antes do horário de siege
3. **Presença online** é a melhor defesa
4. **Honeycomb** design do castelo para dificultar invasão

---

## ☠️ Hazards Ambientais

Todos os hazards são **25% mais fortes** que o padrão:

| Hazard | Modifier | Efeito |
|--------|----------|--------|
| `BloodDrainModifier` | **1.5x** | Sangue drena 50% mais rápido |
| `GarlicAreaStrengthModifier` | **1.25x** | Alho 25% mais forte |
| `HolyAreaStrengthModifier` | **1.25x** | Áreas sagradas 25% mais fortes |
| `SilverStrengthModifier` | **1.25x** | Silver 25% mais perigoso |
| `SunDamageModifier` | **1.25x** | Sol causa 25% mais dano |
| `DurabilityDrainModifier` | **2.0x** | Durabilidade drena 2x mais rápido |

### Impacto Prático

- **☀️ Sol:** Tempo de exposição antes de morrer é **20% menor**
- **🧄 Alho (Dunley):** Cada stack causa +1.25% dano recebido
- **⚪ Silver:** Carregar silver causa dano **25% maior**
- **✝️ Holy Areas:** Áreas sagradas drenam vida **25% mais rápido**
- **🩸 Blood:** Sangue drena **50% mais rápido** - gestão é CRÍTICA
- **🔧 Durabilidade:** Equipamento quebra **2x mais rápido** - reparo é essencial

---

## 🌙 Ciclo Dia/Noite

### Configurações

| Setting | Valor | Descrição |
|---------|-------|-----------|
| `DayDurationInSeconds` | **720** | Ciclo total de 12 minutos |
| `DayStartHour` | 9 | Sol nasce às 9h |
| `DayEndHour` | 17 | Sol se põe às 17h |

### Distribuição

| Período | Horas In-Game | Tempo Real | % do Ciclo |
|---------|---------------|------------|------------|
| **☀️ Dia** | 9h - 17h (8h) | ~5.3 min | ~44% |
| **🌙 Noite** | 17h - 9h (16h) | ~6.7 min | ~56% |

> 💡 **Vantagem:** Noite mais longa = mais tempo para atividades de vampiro (farming, PVP, bosses)

---

## 🌕 Eventos

### Blood Moon

| Setting | Valor | Descrição |
|---------|-------|-----------|
| `BloodMoonFrequency_Min` | **5** | Mínimo 5 dias entre Blood Moons |
| `BloodMoonFrequency_Max` | **10** | Máximo 10 dias entre Blood Moons |
| `BloodMoonBuff` | **0.25** | +25% velocidade de movimento |

**Efeitos durante Blood Moon:**
- 🏃 +25% velocidade de movimento
- 🌙 Céu vermelho (visualmente distinto)
- ⚔️ Oportunidade perfeita para PVP e caça

### Mortium Rift Incursions

Eventos dinâmicos de invasão que forçam conflito por território.

---

## 💀 Penalidades de Morte

### Durabilidade

| Setting | Valor | Impacto |
|---------|-------|---------|
| `Death_DurabilityFactorLoss` | **0.5** | Perde 50% da durabilidade |
| `Death_DurabilityLossFactorAsResources` | 1.0 | Recursos baseados em durabilidade |

### Loot

| Setting | Valor | Impacto |
|---------|-------|---------|
| `BloodBoundEquipment` | **true** | ✅ MANTÉM equipamento ao morrer |
| `DeathContainerPermission` | Anyone | Qualquer um pode lootar |

### Desconexão

| Setting | Valor | Impacto |
|---------|-------|---------|
| `DisableDisconnectedDeadEnabled` | true | Log off kill ativado |
| `DisableDisconnectedDeadTimer` | **45s** | 45 segundos até morrer ao desconectar |

### Inatividade

| Setting | Valor | Impacto |
|---------|-------|---------|
| `InactivityKillEnabled` | true | Mata personagem inativo |
| `InactivityKillTimeMax` | **259200s** | 3 dias máximo |
| `InactivityKillSafeTimeAddition` | **86400s** | +1 dia de proteção |
| `InactivityKillTimerMaxItemLevel` | 84 | Aplica a gear score 84+ |

> ⚠️ **ALERTA:** Morrer significa perder **50% da durabilidade** dos itens e seus **recursos no inventário** (mas equipamento é protegido).

---

## 💎 Soul Shards

### Configurações

| Setting | Valor | Descrição |
|---------|-------|-----------|
| `RelicSpawnType` | **Unique** | Apenas 1 de cada Shard no mapa |
| `BatBoundItems` | false | Items não bloqueiam bat form |
| `BatBoundShards` | **true** | ⚠️ Shards BLOQUEIAM bat form |

### Mecânicas de Soul Shards

1. **Únicas:** Apenas 1 de cada tipo no mapa inteiro
2. **Bloqueiam Bat Form:** Não pode virar morcego com Shard
3. **Debuffs ao carregar:**
   - +25% dano recebido
   - -15% velocidade de movimento
   - Não pode montar cavalo
   - Não pode usar caves
4. **Visível no mapa:** Eye of Twilight revela localização
5. **Manutenção:** Precisa alimentar em bosses de incursão
6. **Lootável:** Perde ao morrer

> 💡 **Estratégia:** Soul Shards são o objetivo endgame. Quem as controla tem poder significativo, mas também é alvo constante.

---

## 📈 Progressão Esperada

### Early Game (Level 1-30)

| Aspecto | Experiência |
|---------|-------------|
| **Recursos** | Escassos - cada item importa |
| **Castelo** | Pequeno (25 floors, 2 servos) |
| **Hazards** | Sol, alho, silver são ameaças REAIS |
| **Morte** | Volta com menos equipamento |
| **PVP** | Evite confrontos com players mais fortes |

### Mid Game (Level 30-60)

| Aspecto | Experiência |
|---------|-------------|
| **Recursos** | Disputas territoriais começam |
| **Castelo** | Expansão para 50-80 floors |
| **Blood Moon** | Oportunidades de PVP frequentes |
| **Clãs** | Alianças entre grupos de 4 |
| **Siege** | Defenda durante horários restritos |

### End Game (Level 60-84)

| Aspecto | Experiência |
|---------|-------------|
| **Soul Shards** | Objetivo máximo - controle = poder |
| **Bosses** | ADAPTIVE BRUTAL - Solo extremo, grupo escala automaticamente |
| **Siege** | Guerras de clãs por território |
| **Economia** | Durabilidade = custo de guerra real |
| **Castelos** | Podem ser ROUBADOS, não só destruídos |

### Final Boss (Level 84+) - Raid Obrigatório

| Boss | Level Brutal | Desafio Solo | Desafio Grupo |
|------|--------------|--------------|---------------|
| Gorecrusher | **84** | 💀💀💀💀 Legendary | ☠️ RAID |
| Solarus | **86** | 💀💀💀💀 Legendary | ☠️ RAID |
| Adam | **88** | 💀💀💀💀 Legendary | ☠️ RAID |
| **Dracula** | **91** | ☠️ SOLO RAID | ☠️☠️☠️ LEGENDARY |

---

## 📚 Referência Técnica

### Arquivo de Configuração

**Localização:** `ServerGameSettings.json`

### Estrutura Principal

```json
{
    "GameModeType": "PvP",
    "CastleDamageMode": "TimeRestricted",
    "CastleHeartDamageMode": "CanBeSeizedOrDestroyedByPlayers",
    "PvPProtectionMode": "Short",
    "BloodBoundEquipment": true,
    "RelicSpawnType": "Unique",
    "ClanSize": 10,
    
    "UnitStatModifiers_Global": {
        "MaxHealthModifier": 2.0,
        "PowerModifier": 1.5
    },
    
    "UnitStatModifiers_VBlood": {
        "MaxHealthModifier": 8.0,
        "PowerModifier": 1.75,
        "LevelIncrease": 3
    },
    
    "VampireStatModifiers": {
        "PhysicalPowerModifier": 0.6,
        "SpellPowerModifier": 0.6,
        "DamageReceivedModifier": 1.0
    }
}
```

### Valores Importantes

| Categoria | Key Settings |
|-----------|-------------|
| **PVP** | `BloodBoundEquipment: true`, `DeathContainerPermission: Anyone` |
| **PVE Bosses** | `MaxHealthModifier: 8.0`, `PowerModifier: 1.75`, `LevelIncrease: 3` |
| **Mobs** | `MaxHealthModifier: 2.0`, `PowerModifier: 1.5` |
| **Vampiro** | `PhysicalPowerModifier: 0.6`, `SpellPowerModifier: 0.6` |
| **Economia** | `BloodDrainModifier: 1.5`, `DurabilityDrainModifier: 2.0` |
| **Siege** | `CastleDamageMode: TimeRestricted` |

---

## 📞 Suporte

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Morri e perdi recursos | Equipamento é protegido, mas recursos no inventário são lootáveis |
| Boss muito difícil | Sistema ADAPTIVE BRUTAL - Solo possível, grupo escala automaticamente |
| Castelo foi roubado | `CanBeSeizedOrDestroyedByPlayers` permite isso |
| Sangue acaba rápido | `BloodDrainModifier: 1.25` - gerencie melhor |

### Links Úteis

- [V Rising Wiki](https://vrising.fandom.com/)
- [V Rising Mod Wiki](https://wiki.vrisingmods.com/)
- [Stunlock Studios (Desenvolvedores)](https://www.stunlock.com/)

---

## 📝 Changelog

### v4.1.0 (2025-12-28) - Brutal Defense Update 🛡️

**FILOSOFIA: \"Bosses São Tanques de Guerra\"**

Além do HP aumentado, agora os jogadores causam menos dano, tornando os bosses ainda mais resistentes sem aumentar o dano que eles causam.

**Novas Configurações:**

| Config | Antes | Depois | Efeito |
|--------|-------|--------|--------|
| Vampire `PhysicalPowerModifier` | 1.0 | **0.6** | Jogador causa -40% dano físico |
| Vampire `SpellPowerModifier` | 1.0 | **0.6** | Jogador causa -40% dano mágico |

**Resultado Combinado:**
```
Boss HP: 8.0x
Jogador Dano: 0.6x (60%)
Tankiness Efetiva: 8.0 / 0.6 = ~13.3x

Tempo de luta estimado (grupo de 4): 35-50 minutos
```

> 🛡️ **Objetivo:** Bosses ultra-tanky sem serem one-shot machines!

---

### v4.0.0 (2025-12-28) - MMO Hardcore Update 🎮

**FILOSOFIA: "Grupos São Essenciais, Mas Ninguém é One-Shot"**

Rebalanceamento completo para criar experiência estilo MMO onde solo é quase impossível e grupos são incentivados progressivamente.

**Problema Resolvido: Juros Compostos**
A versão anterior tinha multiplicadores que se acumulavam de forma excessiva:
- `PowerModifier 2.5 × LevelIncrease 1.2 × DamageReceived 1.25 = 3.75x dano`
- Isso causava one-shots, tornando o jogo IMPOSSÍVEL ao invés de desafiador.

**Solução: Redistribuição Matemática**

| Config | Antes | Depois | Razão |
|--------|-------|--------|-------|
| VBlood `MaxHealthModifier` | 1.0 | **8.0** | Lutas ÉPICAS (25-30 min em grupo) |
| VBlood `PowerModifier` | 2.5 | **1.75** | -30% para evitar one-shots |
| VBlood `LevelIncrease` | 5 | **3** | Mais gerenciável |
| Vampire `DamageReceivedModifier` | 1.25 | **1.0** | Removido para evitar juros compostos |
| Global `MaxHealthModifier` | 1.0 | **2.0** | Mobs mais tanky |
| Global `PowerModifier` | 2.0 | **1.5** | Menos punitivo em exploração |
| `BloodDrainModifier` | 1.25 | **1.5** | Mais pressão de recursos |
| `DurabilityDrainModifier` | 1.5 | **2.0** | Incentiva reparo e grind |

**Cálculo de Dano Efetivo:**
```
Antes: 100 × 2.5 × 1.2 × 1.25 = 375 HP por hit 💀 (ONE-SHOT!)
Agora: 100 × 1.75 × 1.12 × 1.0 = 196 HP por hit ✅ (3 hits para matar)
```

**Resultado por Grupo:**

| Jogadores | HP Boss | Tempo Luta | Dificuldade |
|-----------|---------|------------|-------------|
| Solo | 3,500 | ~35s | BRUTAL (quase impossível) |
| Dupla | 5,810 | ~29s | Difícil (viável com coordenação) |
| Trio | 8,120 | ~27s | Desafiador (margem para erros) |
| 4+ | 10,430+ | ~26s | Sweet spot MMO ✅ |

> ✅ **Objetivo Alcançado:** Grupos maiores sempre vão ter vantagem progressiva, mas NUNCA vai ser "fácil demais" ou "impossível".

---

### v3.0.0 (2025-12-26) - Living Domain Update 🏰

**REMOÇÃO DE HANDICAP ARTIFICIAL**

Para garantir que a dificuldade venha da **habilidade** e não de **estatísticas invisíveis**, a penalidade de nível foi removida.

**Mudanças:**
- **Zero Level Gap:** `LevelIncrease`: 1 → **0**
  - Jogadores enfrentam bosses em pé de igualdade de Gear Score
  - Remove penalidade oculta de dano causado/recebido
  - Bosses continuam com +50% Dano (PowerModifier 1.5) mas você tem chance real de vencer

> **Veredito:** "Difícil como sempre, mas agora matematicamente justo."

### v2.1.0 (2025-12-26) - Solo Duelist Update ⚔️

**REBALANCEAMENTO SOLO - "Desafiador mas Justo"**

O feedback indicou que a combinação de Dano Recebido + Dano do Boss criava situações de "One-Shot" artificiais. O novo balanceamento foca em **Skill Checks** (esquiva e mecânica) ao invés de Stat Checks.

**Ajustes de Filosofia:**
- **Removido debuff de "papel":** Jogadores não tomam mais dano extra globalmente.
- **HP Normalizado:** Solo players têm menos janelas de DPS. Bosses com HP extra tornavam a luta um teste de paciência, não de skill. HP voltou ao normal (1.0x).
- **Dano Brutal (Power):** Mantido alto (1.5x) para punir erros, mas sem ser impossível.

**Mudanças Técnicas:**
- **Vampiro:**
  - `DamageReceivedModifier`: 1.15 → **1.0** (Dano normal, sem penalidade oculta)
- **V Blood Bosses:**
  - `MaxHealthModifier`: 1.15 → **1.0** (Lutas mais dinâmicas, menos esponja)
  - `PowerModifier`: 1.6 → **1.5** (+50% Dano Real - Erros custam caro)
  - `LevelIncrease`: 2 → **1** (Reduz a penalidade de Gear Score oculta)
- **Global Units (Trash):**
  - `PowerModifier`: 1.4 → **1.3** (Exploração menos punitiva)

**Resultado do Sistema:**
| Cenário | Dano Efetivo Recebido | HP do Boss | Veredito |
|---------|----------------------|------------|----------|
| **Antigo (v2.0)** | ~1.84x (1.6 * 1.15) | 1.15x | Injusto / One-Shot |
| **Novo (v2.1)** | **1.50x** (1.5 * 1.0) | **1.0x** | **Desafiador & Justo** |

> 💡 **Nota:** O escalonamento automático de grupo (+66% HP por player) continua ativo. O jogo agora é perfeitamente "solável" se você jogar bem, mas ainda vai te matar se você desrespeitar as mecânicas.

### v2.0.0 (2024-12-26) - Adaptive Brutal Update 🎯

**MUDANÇA MAJOR - Novo Sistema "Adaptive Brutal"**

Descoberta: O V Rising possui escalonamento **NATIVO** baseado no número de jogadores em combate!
- HP do boss escala automaticamente +66% por jogador adicional
- Mecânicas extras são ativadas em grupo

**Ajustes de VBlood Bosses:**
- `MaxHealthModifier`: 1.75 → **1.15** (permite escalamento nativo)
- `PowerModifier`: 2.0 → **1.6** (+60% dano, ainda brutal)
- `LevelIncrease`: 5 → **2** (desafiador, não impossível)

**Ajustes de Vampiro:**
- `DamageReceivedModifier`: 1.2 → **1.15** (margem para solo)

**Dracula Especial:**
- Level: 98 → **94** (solo-viável para veteranos)

**Resultado do Sistema:**
| Jogadores | HP Efetivo | Experiência |
|-----------|------------|-------------|
| Solo | 1.15x | Extremamente Desafiador |
| Duo | 1.91x | Muito Difícil |
| Trio | 2.67x | Raid |
| 4+ | 3.45x+ | Epic Raid |

### v1.1.0 (2024-12-25) - Teamwork Update
- **MAJOR:** Configurações de boss focadas em competitividade e teamwork
  - `PowerModifier`: 1.7 → **2.0** (+100% dano)
  - `MaxHealthModifier`: 1.25 → **1.75** (+75% HP)
  - `LevelIncrease`: 3 → **5** (+5 níveis)
- **DRACULA RAID BOSS:** Configuração individual
  - Level fixo: **98** (base 91 + 7 bônus)
  - Grupo recomendado: **4-5 jogadores** coordenados
- Adicionada legenda de dificuldade na tabela de bosses
- Bosses endgame agora exigem coordenação de grupo

### v3.0.0 (2025-12-26) - Living Domain Update 🏰

**FILOSOFIA: "Seu Exército, Sua Vida"**
Para combater a sensação de "mundo vazio" em servidores menores, transformamos os castelos em fortalezas vivas e povoadas.

**População de Servos e Estruturas:**
Aumentamos drasticamente o limite de servos e estruturas geradoras de inimigos.

| Heart Level | Anterior | **Novo Limite** |
|-------------|----------|-----------------|
| Level 1 | 3 | **5** |
| Level 2 | 5 | **9** |
| Level 3 | 7 | **13** |
| Level 4 | 9 | **17** |
| Level 5 | 12 | **22** |

**Fábrica de Lacaios:**
- **Tumbas:** 6 → **20** (Crie necropóles gigantescas)
- **Ninhos:** 2 → **6** (Farm interno massivo)

**Dinâmica de Mundo:**
- **Blood Moon:** A cada **3-5 dias** (Antes: 5-10). O mundo pulsa com mais frequência.

**Impacto:**
- **Defesa:** Raides se tornam guerras contra NPCs reais.
- **Imersão:** Ao voltar da caçada, seu castelo está cheio de atividade.
- **Utilidade:** Mais servos caçando = mais recursos passivos enquanto você explora.

### v1.0.0 (2024-12-25)
- Configuração inicial "Brutal Competitive - High Stakes Economy"
- Economia 1.5x balanceada
- Hazards +25% mais fortes
- Blood Moon frequente (5-10 dias)
- Siege TimeRestricted
- Equipamento protegido ao morrer
- Bosses Brutal (+3 níveis, +25% HP, +70% dano)
