# 🔧 BepInEx - Guia de Mods para V Rising (ARM64)

## O que é BepInEx?

**BepInEx** é um framework de modding para jogos Unity (como V Rising). Ele permite carregar plugins customizados que modificam o comportamento do jogo sem alterar os arquivos originais.

---

## 📋 Pré-requisitos

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| **RAM** | 8 GB | 16 GB |
| **BepInEx** | Habilitado via env | `BEPINEX_ENABLED=true` |
| **Disco** | 2 GB extra | SSD recomendado |

> ⚠️ **ARM64**: A primeira inicialização pode demorar 5-15 minutos para gerar cache de interoperabilidade.

---

## 🚀 Como Habilitar Mods

### 1. Ativar BepInEx

No EasyPanel ou `.env`:
```bash
BEPINEX_ENABLED=true
```

### 2. Adicionar Mods

Coloque os arquivos `.dll` dos mods na pasta `mods/`:

```
vrising-arm64/
└── mods/
    ├── Bloodstone.dll          # API base (recomendado)
    ├── VampireCommandFramework.dll  # Comandos (recomendado)
    ├── SeuMod.dll
    └── ...
```

### 3. Reiniciar o Servidor

```bash
docker compose restart vrising
```

---

## 📦 Mods Essenciais (Dependências)

A maioria dos mods requer estes como dependências:

| Mod | Versão | Descrição |
|-----|--------|-----------|
| [**Bloodstone**](https://thunderstore.io/c/v-rising/p/deca/Bloodstone/) | 0.2.x | API base para modding |
| [**VampireCommandFramework**](https://thunderstore.io/c/v-rising/p/deca/VampireCommandFramework/) | 0.9.x | Framework de comandos de chat |

> 💡 **Dica**: Instale Bloodstone + VCF primeiro, depois os outros mods.

---

## 📁 Onde Encontrar Mods

- **Thunderstore**: https://thunderstore.io/c/v-rising/
- **V Rising Mods**: https://vrisingmods.com/

### Mods Populares para Servidores

| Mod | Categoria | Descrição |
|-----|-----------|-----------|
| **[KindredLogistics](../docs/GUIDE-KindredLogistics.md)** | ⭐ QoL | Automação de inventário (must-have!) |
| **KindredSchematics** | QoL | Blueprints e templates de construção |
| **KindredCommands** | Admin | Comandos administrativos avançados |
| **XPRising** | Gameplay | Sistema de XP e progressão |
| **CoffinSleep** | Gameplay | Sistema de sono em caixões |
| **BloodyBoss** | Gameplay | Customização de bosses |

> 📖 Veja o [Guia completo do KindredLogistics](../docs/GUIDE-KindredLogistics.md) - o mod mais transformador para servidores!

---

## 🛠️ Script de Download de Mods

Use o script para baixar mods automaticamente do Thunderstore:

```bash
# Baixar um mod específico
./scripts/download-mod.sh odjit/KindredLogistics

# Baixar pack QoL (VCF + KindredLogistics)
./scripts/download-mod.sh --qol

# Listar mods instalados
./scripts/download-mod.sh --list
```

Exemplos de mods populares:
```bash
./scripts/download-mod.sh deca/VampireCommandFramework
./scripts/download-mod.sh odjit/KindredLogistics
./scripts/download-mod.sh odjit/KindredSchematics
./scripts/download-mod.sh odjit/KindredCommands
```

## ⚙️ Configuração de Mods

Após a primeira execução, os arquivos de configuração aparecem em:

```
/data/server/BepInEx/config/
├── BepInEx.cfg           # Config do BepInEx
├── Bloodstone.cfg        # Config do Bloodstone
├── SeuMod.cfg            # Config de cada mod
└── ...
```

### Via EasyPanel File Mount
```
Mount: /data/server/BepInEx/config/SeuMod.cfg
```

---

## 🔄 Atualizando Mods

1. Substitua o arquivo `.dll` na pasta `mods/`
2. Reinicie o servidor

> ⚠️ **Backup**: Sempre faça backup de `BepInEx/config/` antes de atualizar.

---

## ⚠️ Importante: ARM64 e BepInEx

O servidor roda em ARM64 com emulação x86_64 via Box64. Isso significa:

### Primeira Inicialização
- **Pode demorar 5-15 minutos** na primeira vez
- BepInEx gera cache de interoperabilidade (DLLs .NET)
- Logs podem parecer "travados" - isso é normal
- Após gerado, inicializações são muito mais rápidas

### Otimizações Aplicadas
O projeto já inclui otimizações para ARM64:
```bash
BOX64_DYNAREC_STRONGMEM=2  # Melhor sincronização de memória
BOX64_DYNAREC_WAIT=1       # Aguarda blocos DynaRec
```

### Se o Servidor Travar
Se BepInEx travar durante geração de cache:
1. Pare o servidor
2. Delete as pastas de cache:
   ```bash
   rm -rf /data/server/BepInEx/interop/
   rm -rf /data/server/BepInEx/cache/
   ```
3. Reinicie (irá regenerar)

---

## 🐛 Troubleshooting

### Mods não carregam
1. Verifique se `BEPINEX_ENABLED=true`
2. Verifique logs: `docker logs vrising-server`
3. Procure por `[BepInEx]` nos logs
4. Verifique: `cat /data/server/BepInEx/LogOutput.log`

### Erro "Interop generation failed"
1. Aumente a memória do container para 12GB+
2. Delete cache e interop:
   ```bash
   rm -rf /data/server/BepInEx/cache/
   rm -rf /data/server/BepInEx/interop/
   ```
3. Reinicie

### Mod incompatível
- Verifique se o mod é compatível com a versão atual do V Rising
- Mods de **cliente** NÃO funcionam no servidor
- Verifique se as dependências estão instaladas

### Comandos não funcionam
1. Verifique se VampireCommandFramework está instalado
2. Use o prefixo correto (geralmente `.` ou `!`)
3. Verifique permissões de admin in-game

---

## 📝 Compatibilidade

| Componente | Versão |
|------------|--------|
| BepInExPack V Rising | 1.733.2 |
| BepInEx Core | 6.0.0-be.733 |
| V Rising | Oakveil Update (1.0+) |
| Arquitetura | ARM64 (via Box64) |

---

## 🔗 Links Úteis

- [BepInEx GitHub](https://github.com/BepInEx/BepInEx)
- [Il2CppInterop](https://github.com/BepInEx/Il2CppInterop) - Gerador de interop
- [V Rising Modding Discord](https://vrisingmods.com/discord)
- [Thunderstore V Rising](https://thunderstore.io/c/v-rising/)
- [Troubleshooting ARM64](./docs/BEPINEX-ARM64-TROUBLESHOOTING.md)

---

## 📚 Documentação Adicional

- [Guia de Troubleshooting ARM64](../docs/BEPINEX-ARM64-TROUBLESHOOTING.md)
- [Especificações Técnicas](../docs/SPECS-002-bepinex-mods.md)

---

**Nota**: Mods são mantidos pela comunidade. Sempre verifique a compatibilidade antes de instalar.
