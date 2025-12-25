# 🔧 BepInEx ARM64 - Estratégia de Pré-Geração de Interop

## O Problema

O BepInEx em ARM64 (via Box64) **trava** durante a geração de interop assemblies porque:

1. **Il2CppInterop** usa `Parallel.ForEach` por padrão
2. O **Box64** não lida bem com threading intensivo do .NET
3. Resultado: O servidor trava antes de gerar os assemblies

## A Solução

**Pré-gerar os interop assemblies em x86_64** e incluir no Docker image.

Os assemblies são **portáteis** - podem ser gerados em qualquer máquina x86_64 e usados no ARM64, desde que a versão do V Rising seja a mesma.

---

## Workflow GitHub Actions

Foi criado um workflow em `.github/workflows/generate-interop.yml` que:

1. Roda em runner x86_64 do GitHub (gratuito)
2. Baixa V Rising Server via SteamCMD
3. Instala BepInEx
4. Roda o servidor para gerar interop
5. Faz upload como artifact

### Como usar:

1. **Fazer push do arquivo para GitHub**
2. **Ir em Actions → Generate BepInEx Interop → Run workflow**
3. **Baixar o artifact gerado**
4. **Colocar os arquivos em `bepinex/prebuilt/interop/`**

---

## Estrutura do Projeto (após pré-geração)

```
vrising-arm64/
├── bepinex/
│   ├── prebuilt/
│   │   └── interop/           # Assemblies pré-gerados
│   │       ├── Assembly-CSharp.dll
│   │       ├── Il2Cppmscorlib.dll
│   │       └── ... (muitos outros)
│   └── README.md
└── .github/
    └── workflows/
        └── generate-interop.yml
```

---

## Modificação no Dockerfile

Após ter os arquivos pré-gerados, adicionar no Dockerfile:

```dockerfile
# Copiar interop pré-gerado (para ARM64)
COPY bepinex/prebuilt/interop/ /opt/bepinex/prebuilt/interop/
```

## Modificação no entrypoint.sh

Adicionar antes de iniciar o servidor:

```bash
# Usar interop pré-gerado se disponível
if [ -d "/opt/bepinex/prebuilt/interop" ] && [ ! -d "${SERVER_DIR}/BepInEx/interop" ]; then
    log_info "Copiando interop pré-gerado (skip generation)..."
    mkdir -p "${SERVER_DIR}/BepInEx/interop"
    cp -r /opt/bepinex/prebuilt/interop/* "${SERVER_DIR}/BepInEx/interop/"
    log_success "Interop pré-gerado instalado!"
fi
```

---

## Vantagens desta abordagem

| Aspecto | Benefício |
|---------|-----------|
| **Tempo de inicialização** | De 10-15 min → segundos |
| **Estabilidade** | Evita completamente o bug do Box64 |
| **Portabilidade** | Funciona em qualquer ARM64 |
| **Manutenção** | Re-gerar apenas quando V Rising atualizar |

---

## Quando re-gerar?

- Após **atualizações do V Rising** (patches, DLCs)
- Após **atualizações do BepInEx** major
- Se mods reportarem **incompatibilidade**

O workflow pode ser rodado manualmente a qualquer momento.

---

## Alternativas investigadas

| Opção | Viabilidade | Problema |
|-------|-------------|----------|
| Patch Il2CppInterop | Complexo | Requer recompilar BepInEx |
| Wine com NTSync | Médio | Requer Wine custom build |
| FEX-Emu | Não | Trava antes do Box64 |
| **Pré-geração** | ✅ Fácil | Nenhum |

---

*Documento criado em 2025-12-25. Atualizar conforme necessário.*
