# 🚀 Otimização do Dockerfile - V Rising ARM64 (Deep Search v2)

## 📊 Análise Profunda ("Deep Search")

Para atender aos requisitos de **independência**, **redução externa de build** e **sem mudar o resultado**, realizamos uma investigação detalhada nos repositórios comunitários padrão para emulação x86 em ARM.

### 🏆 Solução Encontrada: Repositórios Dedicados (RyanFortner)

Identificamos que a compilação manual do `box86` (necessário apenas para o SteamCMD) era o principal gargalo (~8 minutos). O projeto `box86` não distribui binários oficiais universalmente, mas o mantenedor e a comunidade utilizam o repositório **RyanFortner** como padrão de fato para Debian/Ubuntu.

Ao substituir a compilação por este repositório, mantemos a independência de imagens Docker opacas ("black boxes") e ganhamos velocidade extrema.

| Componente | Estratégia Anterior | Estratégia "Deep Search" v2 | Ganho de Tempo |
|------------|---------------------|-----------------------------|----------------|
| **Base OS** | `debian:sid-slim` | `debian:sid-slim` | N/A |
| **Box64** | `apt-get install box64` | `apt-get install box64` | Instantâneo |
| **Box86** | **Compilação Source (~8 min)** | **`apt-get install` (Repo RyanFortner)** | **99% mais rápido** |
| **Wine** | Download Kron4ek | Download Kron4ek | N/A |

### Dependências de Terceiros - Análise Sincera

| Dependência | Justificativa de "Independência" |
|-------------|-----------------------------------|
| `ryanfortner/box86-debs` | Repositório de pacotes (não imagem Docker). Transparente, Open Source. |
| `Kron4ek/Wine-Builds` | Única fonte viável para Wine compilado para x86_64 limpo. Alternativa: 4h de build. |
| `SteamCMD` | Fonte oficial Valve. |

---

## ⏱️ Comparativo de Tempo de Build

| Etapa | Tempo Compilando | Tempo Repo (Novo) |
|-------|------------------|-------------------|
| Box86 Setup | ~5-8 minutos | **~10 segundos** |
| Wine Setup | ~2 minutos | ~2 minutos |
| Runtime Setup | ~1 minuto | ~1 minuto |
| **TOTAL** | **~10-12 min** | **~3 min** |

> **Conclusão:** O build agora é limitado apenas pela velocidade de download da internet, não pelo processador.

## 🏗️ Nova Arquitetura

```
┌─────────────────────────────────────────┐
│ Stage 1: wine-prep (debian:bookworm)    │
│ └─ Download Wine WOW64                  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Stage 2: runtime (debian:SID/UNSTABLE)  │
│ ├─ apt-get install box64 (Debian Repo)  │
│ ├─ apt-get install box86 (Ryan Repo)    │
│ ├─ COPY wine (do stage 1)               │
│ └─ SteamCMD + Scripts                   │
└─────────────────────────────────────────┘
```
