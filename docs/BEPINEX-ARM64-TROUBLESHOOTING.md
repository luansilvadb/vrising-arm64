# 🔧 BepInEx + ARM64 - Guia de Troubleshooting

> **Última atualização**: 2025-12-25  
> **Versão BepInEx**: 1.733.2  
> **Ambiente**: ARM64 (Oracle Cloud, Raspberry Pi 5, etc) via Box64

---

## 📋 Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Mods (.dll)                          │
├─────────────────────────────────────────────────────────┤
│              BepInEx 6.0 (Il2CPP)                       │
│     ├─ Il2CppInterop (gera DLLs de interop)             │
│     └─ Unity Doorstop (injeta em VRisingServer.exe)     │
├─────────────────────────────────────────────────────────┤
│              VRisingServer.exe (Windows x64)            │
├─────────────────────────────────────────────────────────┤
│              Wine WOW64 (Windows → Linux)               │
├─────────────────────────────────────────────────────────┤
│              Box64 (x86_64 → ARM64 emulation)           │
├─────────────────────────────────────────────────────────┤
│              Linux ARM64 Host                           │
└─────────────────────────────────────────────────────────┘
```

---

## ⚠️ Problemas Conhecidos (ARM64 Específicos)

### 1. Il2CppInterop Hang/Travamento

**Sintomas**:
- Servidor "trava" por mais de 10-15 minutos na **primeira execução**
- Logs param em `[BepInEx] Generating interop assemblies...`
- Container usa 100% CPU sem progresso
- Timeout do healthcheck

**Causa**:
Il2CppInterop usa **escrita multithreaded de arquivos** durante a geração de DLLs. Box64 pode ter problemas com essa operação.

**Soluções**:

1. **Aguardar mais tempo** (até 15 minutos na primeira vez é normal)

2. **Aumentar memória** para 12-16GB:
   ```yaml
   # docker-compose.yml
   services:
     vrising:
       deploy:
         resources:
           limits:
             memory: 16G
   ```

3. **Deletar cache e tentar novamente**:
   ```bash
   docker exec vrising-server rm -rf /data/server/BepInEx/interop/
   docker exec vrising-server rm -rf /data/server/BepInEx/cache/
   docker restart vrising-server
   ```

4. **Verificar variáveis Box64** (já configuradas por padrão):
   ```bash
   BOX64_DYNAREC_STRONGMEM=2
   BOX64_DYNAREC_WAIT=1
   ```

---

### 2. Erro "winhttp.dll not found" ou BepInEx não carrega

**Sintomas**:
- Servidor inicia mas mods não carregam
- Nenhum log `[BepInEx]` aparece
- Pasta `BepInEx/plugins` vazia após iniciar

**Causa**:
`winhttp.dll` não está sendo carregado como nativo pelo Wine.

**Solução**:
Verificar que `WINEDLLOVERRIDES` inclui `winhttp=n,b`:
```bash
docker exec vrising-server echo $WINEDLLOVERRIDES
# Deve incluir: winhttp=n,b
```

Se não incluir, adicione ao `.env`:
```bash
WINEDLLOVERRIDES="winhttp=n,b;mscoree=d;mshtml=d;dnsapi=b"
```

---

### 3. Erro "Interop generation failed" ou "Cpp2IL error"

**Sintomas**:
- Logs mostram erro durante geração de interop
- `System.AccessViolationException`
- Crash durante `Cpp2IL`

**Soluções**:

1. **Limpar cache completamente**:
   ```bash
   docker exec vrising-server bash -c "
     rm -rf /data/server/BepInEx/interop/
     rm -rf /data/server/BepInEx/cache/
     rm -rf /data/server/BepInEx/unhollowed/
   "
   docker restart vrising-server
   ```

2. **Aumentar swap (para VPS com pouca RAM)**:
   ```bash
   # No host ARM64
   sudo fallocate -l 8G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **Desabilitar mods temporariamente** para gerar interop limpo:
   ```bash
   # Mover mods para backup
   docker exec vrising-server mv /data/server/BepInEx/plugins /data/server/BepInEx/plugins.bak
   docker restart vrising-server
   # Após iniciar OK, restaurar mods
   docker exec vrising-server mv /data/server/BepInEx/plugins.bak /data/server/BepInEx/plugins
   docker restart vrising-server
   ```

---

### 4. Mod Incompatível / Crash ao Carregar

**Sintomas**:
- Servidor crasheia após iniciar
- Logs mostram erro em mod específico
- `NullReferenceException` em plugin

**Diagnóstico**:
```bash
# Ver log detalhado do BepInEx
docker exec vrising-server cat /data/server/BepInEx/LogOutput.log

# Procurar erros
docker exec vrising-server grep -i "error\|exception\|fail" /data/server/BepInEx/LogOutput.log
```

**Solução**:
1. Remover o mod problemático de `/data/mods/`
2. Verificar dependências (muitos mods precisam de Bloodstone + VCF)
3. Verificar compatibilidade com versão do V Rising

---

## 🔍 Comandos de Diagnóstico

### Ver se BepInEx está ativo
```bash
docker logs vrising-server 2>&1 | grep -i "bepinex"
```

### Ver plugins carregados
```bash
docker exec vrising-server cat /data/server/BepInEx/LogOutput.log | grep "Loading \[" 
```

### Ver estrutura BepInEx
```bash
docker exec vrising-server ls -la /data/server/BepInEx/
docker exec vrising-server ls -la /data/server/BepInEx/plugins/
```

### Ver erros recentes
```bash
docker exec vrising-server tail -100 /data/server/BepInEx/LogOutput.log | grep -i "error"
```

### Verificar se arquivos estão no lugar
```bash
docker exec vrising-server ls -la /data/server/winhttp.dll
docker exec vrising-server ls -la /data/server/doorstop_config.ini
docker exec vrising-server ls -la /data/server/dotnet/
```

---

## 📊 Tempo de Inicialização Esperado

| Cenário | Tempo Esperado |
|---------|----------------|
| Primeira execução (gerando interop) | 5-15 minutos |
| Segunda execução (cache pronto) | 2-5 minutos |
| Executando sem mods | 1-3 minutos |
| Adicionando novo mod | +30 segundos |

> **Nota**: Tempos baseados em Oracle Cloud Ampere A1 (4 cores, 24GB RAM)

---

## ✅ Checklist de Verificação

Antes de reportar problemas, verifique:

- [ ] `BEPINEX_ENABLED=true` está configurado
- [ ] RAM do container ≥ 8GB (recomendado 16GB)
- [ ] Primeira execução aguardou pelo menos 15 minutos
- [ ] Arquivos existem em `/data/server/BepInEx/`
- [ ] Log do container mostra `[BepInEx]` carregando
- [ ] Mods estão em `/data/mods/` ou `/data/server/BepInEx/plugins/`
- [ ] Mods possuem dependências instaladas (Bloodstone, VCF)

---

## 🔗 Links Úteis

- [BepInEx GitHub](https://github.com/BepInEx/BepInEx)
- [Il2CppInterop](https://github.com/BepInEx/Il2CppInterop)
- [Box64 Environment Variables](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)
- [V Rising Modding Discord](https://vrisingmods.com/discord)
- [Thunderstore V Rising](https://thunderstore.io/c/v-rising/)

---

## 🆘 Ainda com Problemas?

Se nenhuma das soluções acima funcionou:

1. **Colete os logs**:
   ```bash
   docker logs vrising-server > server.log 2>&1
   docker exec vrising-server cat /data/server/BepInEx/LogOutput.log > bepinex.log 2>/dev/null
   ```

2. **Verifique recursos**:
   ```bash
   docker stats vrising-server --no-stream
   ```

3. **Opção nuclear** (reinstalar BepInEx do zero):
   ```bash
   docker exec vrising-server rm -rf /data/server/BepInEx
   docker exec vrising-server rm -f /data/server/winhttp.dll
   docker exec vrising-server rm -f /data/server/doorstop_config.ini
   docker restart vrising-server
   ```

---

*Documento criado em 2025-12-25 para o projeto vrising-arm64*
