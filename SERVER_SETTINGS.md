# 🏰 Velion: PVP & High Rate [v1.0.1]

> **CLAN SIZE: 10 | PVP | 2.5x LOOT / 2.0x YIELD | TP LIBERADO**

Informações essenciais atualizadas conforme `ServerGameSettings.json`.

---

## ⚡ Configurações do Servidor

> **Resumo do Servidor:**
> *   **Dificuldade:** Bosses com 2.0x Vida e Nível +2 (Difícil mas justo).
> *   **Ritmo:** Lutas longas, exigem estratégia, não sorte.
> *   **Grupo:** Reviver rápido (2s) torna o multiplayer muito divertido e heroico.
> *   **Iniciantes:** Vida extra (+20%) e Loot abundante (2.5x) para nunca ficarem travados no farm.
> *   **Conveniência:** Inventários gigantes (Stacks 4.0x) e menos consumo de sangue.

| Configuração | Valor | Detalhes |
| :--- | :---: | :--- |
| **👥 Tamanho do Clã** | **10** | Forme exércitos. Guerras massivas. |
| **⚔️ Modo PVP** | **Padrão** | **Gear Bound** (Mantém set), mas perde Loot/Recursos (Full Loot). |
| **🎒 Teleporte** | **LIBERADO** | **Viaje com itens** nos portais e cavernas (`TeleportBoundItems: false`). |
| **⛏️ Coleta (Yield)** | **2.0x** | Dobro de recursos ao bater em árvores/pedras. |
| **📦 Loot (Drops)** | **2.5x** | Drop de Recursos 2.5x. Geral 1.5x. Missões 5.0x. |
| **🏰 Castelo** | **1 por Player** | Limite de 1 Castelo (Heart) por jogador. |
| **🦇 Morcego** | **Buffado** | Pode voar carregando itens e **Soul Shards**! |

---

## 📅 Horários Críticos

O mundo é perigoso, mas sua base só corre perigo nestas horas:

| Evento | Seg-Sex | Sáb-Dom | Status |
| :--- | :---: | :---: | :--- |
| **🛡️ Raid (Dano a Castelo)** | 20:00 - 23:00 | 15:00 - 23:00 | **Golems Podem Spawnar**. Timer: 90s (Under Attack). |
| **⚔️ PVP Mundo Aberto** | 18:00 - 23:59 | 10:00 - 23:59 | Combate ativo contra players. |

> ⚠️ **Siege:** Golems levam 10min (600s) para serem destruídos por timers passivos se não defendidos.
> **Castelo:** `CastleDamageMode` é TimeRestricted. Fora do horário o castelo é invulnerável a players.

---

## ⚔️ Meta de Combate & Stats

Ajustes finos para promover PVP duradouro e PVE desafiador.

1.  **V-Blood (Bosses):**
    *   **HP:** 2.0x (Combates épicos).
    *   **Power:** 1.1x (+10% Dano).
    *   **Nível:** +2 (Bosses têm +2 níveis).
    *   **Global Unit HP:** 1.25x (Mobs comuns também são mais resistentes).
2.  **Vampiros (Jogadores):**
    *   **HP:** 1.2x (+20% vida para evitar one-shots).
    *   **Dano:** 1.0x (Padrão).
    *   **Recebido:** 1.0x (Padrão).
3.  **Castelo & Limites:**
    *   **Tumbas:** 20 por castelo.
    *   **Ninhos (Vermin):** 6 por castelo.
    *   **Pisos:** Começa com 40 (Lvl 1) e vai até 400 (Lvl 5).

---

## 🏗️ Economia & Crafting

*   **Velocidade de Crafting:** 3.0x (Mais rápido).
*   **Velocidade de Refino:** 3.0x (Serrarias/Fornalhas mais rápidas).
*   **Velocidade de Pesquisa:** 2.0x (Tempo reduzido pela metade).
*   **Servos:** Conversão 5.0x mais rápida | Loot de Missões 5.0x.
*   **Stack de Itens:** 4.0x (Carregue 4x mais no inventário).
*   **Durabilidade:** 0.5x (Itens quebram 50% mais devagar).
*   **Essência de Sangue:** 2.0x (Drop dobrado).
*   **Inatividade:** Se desconectar morto, seu corpo some em 45s.

---

## ⚙️ Configurações do Servidor (Detalhes Técnicos)

*   **Dia/Noite:** Dia dura 30 minutos (Noites longas: Dia 9h-17h).
*   **Blood Moon:** Frequência a cada 3-5 dias. Buff de 25%.
*   **Decaimento do Castelo:** 0.5x (Base consome 50% menos sangue/tempo).
*   **Respawn PVP:** 1.5x (33% maior que o padrão).
*   **Equipamento Inicial:** Nenhum (Start hardcore).
*   **Desmontar:** Recupera 75% dos recursos.

---

## 📜 Regras Adicionais (Detalhes Técnicos)

*   **Raid Full:** Castelos podem ser **Capturados ou Destruídos** durante o Raid (`CanBeSeizedOrDestroyedByPlayers`). Use chaves para conquistar.
*   **Siege Golems:** Vida **Alta** (High). Invocação anunciada no chat global e ícone visível no mapa.
*   **Loot de Morte:** **Full Loot**. Qualquer jogador pode saquear seu corpo e baús inimigos ABERTOS (`CanLootEnemyContainers`).
*   **Durabilidade na Morte:** Equipamentos perdem **25%** de durabilidade ao morrer PVP/PVE.
*   **Sede de Sangue:** Drenagem de sangue **30% mais lenta** (0.7x).
*   **Relíquias (Soul Shards):** Únicas (Apenas uma de cada no servidor).
*   **Waypoints:** Bloqueados (Necessário descobrir viajando).
*   **Vizinhança:** Distância mínima de **3 pisos** entre castelos rivais.

---

## 🚀 Performance & Estabilidade (O Diferencial)

Não é promessa vazia. Entenda **por que** nosso servidor roda melhor que a maioria:

1.  **Batalhas Gigantes sem Lag:**
    *   **O Segredo:** A maioria dos servidores usa 1 núcleo do processador. Nós forçamos o jogo a usar **4 Núcleos Reais**.
    *   **Na Prática:** O servidor consegue calcular a física de 50 monstros e 10 jogadores ao mesmo tempo sem "engasgar". O PVP massivo flui liso.
2.  **Seus Ataques Registram na Hora:**
    *   **O Segredo:** Aumentamos a capacidade de tráfego (Buffer) de 200KB (padrão) para **32MB**.
    *   **Na Prática:** Seus dados de movimento e ataque não pegam "fila". O clique é instantâneo, sem aquela sensação de estar "patinando" no mapa.
3.  **Potência & Velocidade (4 Gbps):**
    *   **O Segredo:** Rodamos em processadores **Enterprise ARM64** com um Link de **4 Gigabits** (Oracle Cloud).
    *   **Na Prática:** Internet 40x mais rápida que conexões comuns. O servidor nunca vai "gargalar" por excesso de jogadores.
4.  **Salvamento Invisível:**
    *   **O Segredo:** Prioridade de disco ajustada no sistema operacional.
    *   **Na Prática:** Sabe aquela travada de 3 segundos quando o servidor salva? Aqui ela não existe.

> *Resumo: Tecnologia de ponta configurada manualmente para alta performance.*

---
