# 🏰 Velion: High Rate & Chill [v5.0.1]

> **CLAN SIZE: 10 | PVP | 2.5x LOOT / 2.0x YIELD | TP LIBERADO**

Informações essenciais atualizadas conforme `ServerGameSettings.json`.

---

## ⚡ Direto ao Ponto (Resumo)

| Configuração | Valor | Detalhes |
| :--- | :---: | :--- |
| **👥 Tamanho do Clã** | **10** | Forme exércitos. Guerras massivas. |
| **⚔️ Modo PVP** | **Padrão** | **Gear Bound** (Não perde set ao morrer), mas perde Loot/Recursos. |
| **🎒 Teleporte** | **LIBERADO** | **Viaje com itens** nos portais e cavernas (`TeleportBoundItems: false`). |
| **⛏️ Farm (Yield)** | **2.0x** | Você coleta o dobro de recursos ao bater em árvores/pedras. |
| **📦 Loot (Drops)** | **2.5x** | Drop de Recursos de mobs/baús é 2.5x. Geral é 1.5x. |
| **🏰 Castelo** | **1 por Player** | Limite de 1 Castelo (Heart) por jogador. |
| **🦇 Morcego** | **Buffado** | Pode voar carregando itens e **Soul Shards**! |

---

## 📅 Horários Críticos (Tempo Real/Local)

O mundo é perigoso, mas sua base só corre perigo nestas horas:

| Evento | Seg-Sex | Sáb-Dom | Status |
| :--- | :---: | :---: | :--- |
| **🛡️ Raid (Dano a Castelo)** | 20:00 - 23:00 | 15:00 - 23:00 | **Golems Podem Spawnar**. Timer: 90s (Under Attack). |
| **⚔️ PVP Mundo Aberto** | 18:00 - 23:59 | 10:00 - 23:59 | Combate ativo contra players. |

> ⚠️ **Siege:** Golems levam 10min (600s) para serem destruídos por timers passivos se não defendidos.
> **Castelo:** `CastleDamageMode` é TimeRestricted. `Never` destrói castelo por inatividade (apenas decadência).

---

## ⚔️ Meta de Combate & Stats

Ajustes finos para promover PVP duradouro e PVE desafiador.

1.  **V-Blood (Bosses):**
    *   **HP:** 2.0x (`UnitStatModifiers_VBlood`).
    *   **Power:** 1.1x (+10% Dano).
    *   Além disso, Global Unit HP é 1.25x (acumulativo).
2.  **Vampiros (Players):**
    *   **HP:** 1.2x (20% mais vida para evitar one-shots).
    *   **Dano:** 1.0x (Padrão).
    *   **Recebido:** 1.0x.
3.  **Limites de Construção:**
    *   **Tumbas:** 20 por castelo.
    *   **Ninhos (Vermin):** 6 por castelo.
    *   **Pisos:** Nível 1 (40) -> Nível 5 (400).

---

## 🏗️ Economia & Crafting

*   **Velocidade de Crafting:** 2.0x (Mais rápido).
*   **Velocidade de Refino:** 2.0x (Serrarias/Fornalhas mais rápidas).
*   **Custo de Construção/Receita:** 1.0x (Padrão).
*   **Stack de Itens:** 2.0x (Carregue o dobro no inventário).
*   **Inatividade:** Se desconectar morto, seu corpo some em 45s (`DisableDisconnectedDeadTimer`).

---

## ⚙️ Outros Detalhes

*   **Dia/Noite:** Dia dura 30 minutos (`DayDurationInSeconds: 1800`). Dia começa 9h, termina 17h (Noites longas).
*   **Blood Moon:** Frequência a cada 3-5 dias. Buff de 25%.
*   **Equipamento Inicial:** Nenhum (Start hardcore).
*   **Desmontar:** Recupera 75% dos recursos.

---

## 🚀 Otimizações de Sistema (Performance Tuning)

Este servidor roda em infraestrutura Cloud ARM64 (Oracle Ampere) com otimizações de nível de Kernel para garantir **60 FPS estáveis** mesmo em guerras de Clãs (10v10).

1.  **FEX Emulator Turbo Mode (`TSO=0`):** Desativamos proteções redundantes de memória da emulação. Isso libera **+20% de CPU** para o jogo.
2.  **Unity Multi-Threading:** O servidor está forçado a usar **4 núcleos dedicados** para física e IA (Physics/AI jobs), evitando gargalo em um único núcleo.
3.  **Kernel Network Stack Tuned:**
    *   **Buffers UDP:** Aumentados de 200KB para **32MB** (Dinâmico).
    *   **Keepalive:** Conexões "mortas" caem em 5 minutos (antes era 2 horas).
    *   **Backlog:** O servidor aceita surtos de conexão sem lagar (Queue de 65k pacotes).
    *   **Garbage Collection:** Modo Incremental ativado para eliminar travadas de limpeza de RAM.

---
*Configuração gerada baseada no arquivo `ServerGameSettings.json`.*
