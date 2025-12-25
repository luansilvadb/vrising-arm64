# 🔧 BepInEx - Guia de Mods para V Rising

## O que é BepInEx?

**BepInEx** é um framework de modding para jogos Unity (como V Rising). Ele permite carregar plugins customizados que modificam o comportamento do jogo sem alterar os arquivos originais.

## 📋 Pré-requisitos

- Servidor V Rising ARM64 funcionando
- `BEPINEX_ENABLED=true` nas variáveis de ambiente
- Mínimo 8GB de RAM (BepInEx requer memória para geração de cache)

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
    ├── YourMod.dll
    ├── AnotherMod.dll
    └── ...
```

### 3. Reiniciar o Servidor

Após adicionar mods, reinicie o container:
```bash
docker compose restart vrising
```

## 📁 Onde Encontrar Mods

- **Thunderstore**: https://thunderstore.io/c/v-rising/
- **V Rising Mods**: https://vrisingmods.com/

### Mods Populares para Servidores

| Mod | Descrição |
|-----|-----------|
| **ServerLaunchFix** | Correções de inicialização |
| **KindredLogistics** | Sistema de logística avançado |
| **KindredSchematics** | Blueprints de construção |
| **VampireCommandFramework** | Framework para comandos de chat |
| **Bloodstone** | API base para outros mods |

## ⚙️ Configuração de Mods

Após a primeira execução, os arquivos de configuração dos mods aparecem em:
```
/data/server/BepInEx/config/

# Via EasyPanel File Mount:
Mount: /data/server/BepInEx/config/SeuMod.cfg
```

## 🔄 Atualizando Mods

1. Substitua o arquivo `.dll` na pasta `mods/`
2. Reinicie o servidor

## ⚠️ Importante: ARM64 e BepInEx

O servidor roda em ARM64 com emulação x86_64 via Box64. Isso significa:

### Primeira Inicialização
- **Pode demorar 5-10 minutos** na primeira vez
- BepInEx gera cache de interoperabilidade (.dll)
- Após gerado, inicializações são normais

### Se o Servidor Travar
Se BepInEx travar durante geração de cache:
1. Pare o servidor
2. Delete a pasta `/data/server/BepInEx/interop/`
3. Reinicie (irá regenerar)

## 🐛 Troubleshooting

### Mods não carregam
1. Verifique se `BEPINEX_ENABLED=true`
2. Verifique logs: `docker logs vrising-server`
3. Procure por `[BepInEx]` nos logs

### Erro "Interop generation failed"
1. Aumente a memória do container para 12GB+
2. Delete `/data/server/BepInEx/cache/` e `/data/server/BepInEx/interop/`
3. Reinicie

### Mod incompatível
- Verifique se o mod é compatível com a versão atual do V Rising
- Mods de cliente NÃO funcionam no servidor

## 📝 Compatibilidade

| Componente | Versão |
|------------|--------|
| BepInExPack V Rising | 1.733.2 |
| V Rising | Oakveil Update (1.0+) |
| Arquitetura | ARM64 (via Box64 emulação) |

## 🔗 Links Úteis

- [BepInEx GitHub](https://github.com/BepInEx/BepInEx)
- [V Rising Modding Discord](https://vrisingmods.com/discord)
- [Thunderstore V Rising](https://thunderstore.io/c/v-rising/)

---

**Nota**: Mods são mantidos pela comunidade. Sempre verifique a compatibilidade antes de instalar.
