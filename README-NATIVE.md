# VRising ARM64 - Versão SteamCMD Nativa

## 🎯 Diferença Principal

**Antes (Wine + SteamCMD)**: Wine para download → SSL falha ❌  
**Agora (SteamCMD nativo)**: SteamCMD Linux via FEX para download → Wine só para executar ✅

## 🚀 Como Usar

```bash
# Build
docker-compose -f docker-compose.native.yml build

# Run
docker-compose -f docker-compose.native.yml up
```

## 📊 Arquitetura

```
┌─────────────────────────────────────────┐
│  Download (SteamCMD Linux 32-bit)       │
│  ↓ FEX executa binário x86              │
│  ↓ Sem Wine = Sem problema SSL          │
│  ✓ VRisingServer.exe baixado            │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│  Execução (Wine via FEX)                │
│  ↓ Wine roda VRisingServer.exe          │
│  ↓ FEX emula x86_64                     │
│  ✓ Servidor funcionando                 │
└─────────────────────────────────────────┘
```

## ✅ Vantagens

- **Sem problemas de SSL** (SteamCMD Linux não tem bug do Wine)
- **Mais rápido** (download direto)
- **Mais estável** (menos camadas de emulação no download)
- **Wine só para o necessário** (executar o servidor)

## 📁 Arquivos

- `Dockerfile.native` - Build com SteamCMD Linux
- `entrypoint.native.sh` - Download nativo + execução Wine
- `docker-compose.native.yml` - Orquestração
