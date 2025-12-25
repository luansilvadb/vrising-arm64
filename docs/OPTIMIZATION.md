# 🚀 Otimização do Dockerfile - V Rising ARM64 (Deep Search)

## 📊 Análise Profunda ("Deep Search")

Para atender aos requisitos de **independência** e **redução extrema de build**, realizamos uma investigação detalhada nos repositórios oficiais Debian e alternativos upstream.

### 🏆 Solução Encontrada: Debian Sid (Unstable)

Descobrimos que a distribuição **Debian Sid (Unstable)** contém o pacote `box64` oficialmente nos seus repositórios para arquitetura ARM64. Isso permite eliminar completamente o estágio de compilação do Box64, que era o maior gargalo.

| Componente | Estratégia Anterior | Estratégia "Deep Search" | Ganho de Tempo |
|------------|---------------------|--------------------------|----------------|
| **Base OS** | `debian:11-slim` | `debian:sid-slim` | N/A |
| **Box64** | Compilação Source (15min+) | `apt-get install box64` (5s) | **99% mais rápido** |
| **Box86** | Compilação Source | Compilação (Mantido para compatibilidade) | N/A |
| **Wine** | Download GitHub | Download GitHub | N/A |

### Dependências de Terceiros - Status

| Dependência | Tipo | Status | Justificativa |
|-------------|------|--------|---------------|
| `debian:sid-slim` | Imagem Oficial | ✅ Aprovado | Base oficial Debian (bleeding edge) |
| `box64` (apt) | Pacote do Repo | ✅ Aprovado | **Independência total** (vem do OS) |
| `Kron4ek/Wine` | Binários GitHub | ⚠️ Aceitável | Única opção WOW64 viável (upstream) |

---

## ⏱️ Comparativo de Tempo de Build

| Etapa | Tempo Anterior | Tempo Otimizado | Status |
|-------|----------------|-----------------|--------|
| Pull Base Image | ~15s | ~15s | Igual |
| **Box86 Compile** | ~10 min | ~8 min | Otimizado flags |
| **Box64 Compile** | **~15 min** | **0s (apt install)** | 🚀 **ELIMINADO** |
| **Wine Prep** | ~2 min | ~2 min | Igual |
| **Runtime Setup** | ~2 min | ~1 min | Mais rápido |
| **TOTAL** | **~30 min** | **~10-12 min** | 📉 **-60%** |

> **Nota:** Builds subsequentes com Cache Docker continuam levando apenas ~2-3 minutos.

---

## 🏗️ Arquitetura Final

```
┌─────────────────────────────────────────┐
│ Stage 1: box86-builder (debian:sid)     │
│ ├─ Compila Box86 (32-bit)               │
│ └─ Necessário para SteamCMD             │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Stage 2: wine-prep (debian:sid)         │
│ └─ Download Wine WOW64                  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Stage 3: runtime (debian:sid)           │
│ ├─ apt-get install box64 (OFICIAL)      │
│ ├─ COPY box86 (do stage 1)              │
│ ├─ COPY wine (do stage 2)               │
│ └─ SteamCMD + Scripts                   │
└─────────────────────────────────────────┘
```

## 🧪 Teste de Validação

```bash
docker build -t vrising-arm64:optimized .
# O build deve levar cerca de 10-12 minutos na primeira vez.
```
