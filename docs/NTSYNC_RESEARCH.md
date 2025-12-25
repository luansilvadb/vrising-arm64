# Deep Research: Migração para NTSync

> **Data:** 2025-12-25  
> **Referência:** [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)

---

## 📖 O que é NTSync?

**NTSync** (NT Synchronization) é um driver do kernel Linux que implementa primitivas de sincronização do Windows NT diretamente no kernel. Isso permite que Wine/Proton execute aplicações Windows com muito melhor desempenho e compatibilidade.

### Por que NTSync é importante?

| Problema sem NTSync | Solução com NTSync |
|---------------------|-------------------|
| Wine emula sincronização em userspace | Sincronização nativa no kernel |
| Overhead de RPC para "kernel" process do Wine | Chamadas diretas ao kernel |
| APIs complexas como `NtWaitForMultipleObjects` são lentas | Implementação eficiente no kernel |
| Performance degradada em apps multi-thread | Performance perto do nativo |

### Benefícios Documentados

| Métrica | Melhoria |
|---------|----------|
| FPS (vs vanilla Wine) | +50% a +100% |
| FPS (vs fsync) | +5% a +15% |
| Uso de CPU | Significativamente menor |
| Latência | Mais consistente |
| Estabilidade | Melhor em jogos multi-thread |

---

## 🔍 Análise do Projeto de Referência

### Arquitetura tsx-cloud/vrising-ntsync

```
tsx-cloud/vrising-ntsync/
├── Docker/
│   ├── Dockerfile              # Usa imagem base customizada
│   ├── start.sh                # Script de inicialização
│   ├── emulators.rc            # Configurações Box64/FEX
│   ├── load_emulators_env.sh   # Loader de configurações
│   └── server/                 # Arquivos BepInEx modificados
├── docker-compose-example/
│   └── docker-compose.yml
├── logs/                       # Logs de exemplo
└── README.md
```

### Componentes-Chave

1. **Imagem Base**: `tsxcloud/steamcmd-wine-ntsync:latest`
   - Inclui Wine staging-tkg-ntsync-wow64
   - SteamCMD pré-configurado
   - Box64/FEX-Emu para ARM64
   - Ubuntu 25.04 com kernel 6.14+

2. **Wine**: Versão `staging-tkg-ntsync-wow64`
   - Staging patches para melhor compatibilidade
   - TkG patches para performance
   - NTSync integrado
   - WOW64 para rodar 32-bit sem multilib

3. **NTSync**: Opcional mas recomendado
   - Funciona sem NTSync (graceful degradation)
   - Quando disponível, usa automaticamente

---

## 📊 Comparação: Nosso Projeto vs Referência

| Aspecto | Nosso Projeto Atual | Projeto Referência |
|---------|---------------------|---------------------|
| **Imagem Base** | `weilbyte/box:debian-11` | `tsxcloud/steamcmd-wine-ntsync:latest` |
| **SO Base** | Debian 11 (Bullseye) | Ubuntu 25.04 (Plucky) |
| **Kernel** | ~5.10 | 6.14+ |
| **Wine** | 11.0-rc3 vanilla WOW64 | staging-tkg-ntsync-wow64 |
| **NTSync** | ❌ Não suportado | ✅ Suportado |
| **Box64** | v0.3.8 (compilado) | v0.3.8+ (pré-instalado) |
| **Box86** | Incluído na imagem | Incluído na imagem |
| **winetricks** | ❌ Não instalado | ✅ Instalado |
| **BepInEx** | Padrão | Modificado para ARM64 |

---

## 🛠️ Requisitos para NTSync Funcionar

### No Host (VPS/Servidor)

1. **Kernel Linux 6.14+**
   ```bash
   uname -r
   # Deve mostrar 6.14.x ou superior
   ```

2. **Módulo ntsync carregado**
   ```bash
   # Verificar se existe
   modinfo ntsync
   
   # Carregar temporariamente
   sudo modprobe ntsync
   
   # Carregar automaticamente no boot
   echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf
   ```

3. **Device /dev/ntsync acessível**
   ```bash
   ls -la /dev/ntsync
   # crw-rw-rw- 1 root root ... /dev/ntsync
   ```

### No Container Docker

1. **Wine com suporte NTSync**
   - Usar builds: `staging-tkg-ntsync`, `wine-cachyos`, ou similar
   
2. **Device mapeado**
   ```yaml
   devices:
     - /dev/ntsync:/dev/ntsync
   ```

3. **Verificação de funcionamento**
   ```bash
   # Dentro do container
   lsof /dev/ntsync
   # Se mostrar processos Wine, NTSync está ativo
   ```

---

## 🎯 Três Abordagens Possíveis

### Abordagem A: Usar Imagem tsxcloud Diretamente

```dockerfile
FROM tsxcloud/steamcmd-wine-ntsync:latest
# ... customizações mínimas
```

**✅ Prós:**
- Zero configuração de Wine/NTSync
- Testado com V Rising
- Mantido por terceiros

**❌ Contras:**
- Perda de controle total
- Dependência externa
- Menos flexibilidade

### Abordagem B: Reescrever com Ubuntu 25.04

```dockerfile
FROM ubuntu:25.04
# Compilar Box64/Box86
# Instalar Wine staging-tkg-ntsync
# Configurar SteamCMD
```

**✅ Prós:**
- Controle total
- Código 100% nosso
- Flexível

**❌ Contras:**
- Muito trabalho
- Tempo de build longo
- Mais manutenção

### Abordagem C: Híbrida (Recomendada)

```dockerfile
FROM ubuntu:25.04
# OU continuar com Debian 11 se NTSync não for prioridade

# Atualizar Wine para staging-tkg-ntsync
# Manter estrutura atual
# Adicionar detecção automática de NTSync
```

**✅ Prós:**
- Compatível com/sem NTSync
- Menor disrupção
- Upgrade gradual

**❌ Contras:**
- Complexidade moderada

---

## 📋 Plano de Implementação (Abordagem C)

### Fase 1: Dockerfile

**Mudanças principais:**

```dockerfile
# ANTES
FROM weilbyte/box:debian-11

# DEPOIS (opção 1 - Ubuntu 25.04 para NTSync nativo)
FROM ubuntu:25.04

# DEPOIS (opção 2 - Manter Debian 11, sem NTSync)
FROM weilbyte/box:debian-11
# Apenas atualizar Wine para staging-tkg
```

**Wine URL atualizada:**
```bash
# Vanilla (atual)
https://github.com/Kron4ek/Wine-Builds/releases/download/11.0-rc3/wine-11.0-rc3-amd64-wow64.tar.xz

# Com NTSync (novo)
https://github.com/Kron4ek/Wine-Builds/releases/download/11.0-rc3/wine-11.0-rc3-staging-tkg-ntsync-amd64-wow64.tar.xz
```

### Fase 2: entrypoint.sh

**Adicionar função de verificação:**

```bash
check_ntsync() {
    log_info "Verificando suporte NTSync..."
    log_info "Kernel: $(uname -r)"
    
    if [ -e "/dev/ntsync" ]; then
        if lsmod | grep -q ntsync; then
            log_success "NTSync disponível e módulo carregado!"
            export NTSYNC_AVAILABLE="true"
        else
            log_warning "Device /dev/ntsync existe, mas módulo não carregado"
            export NTSYNC_AVAILABLE="false"
        fi
    else
        log_info "NTSync não disponível (sem /dev/ntsync)"
        log_info "Para melhor performance, use kernel 6.14+ com módulo ntsync"
        export NTSYNC_AVAILABLE="false"
    fi
}
```

### Fase 3: Configuração de Emuladores

**Criar `config/emulators.rc`:**

```bash
### BOX64 settings
# Aumentar compatibilidade (diminui performance levemente)
BOX64_DYNAREC_STRONGMEM=1
BOX64_DYNAREC_BIGBLOCK=0

### FEX-EMU settings (se usar FEX em vez de Box64)
FEX_PARANOIDTSO=true
```

**Criar `scripts/load_emulators_env.sh`:**

```bash
#!/bin/bash
EMULATORS_CONFIG="${SAVES_DIR}/Settings/emulators.rc"

# Copiar padrão se não existir
if [ ! -f "${EMULATORS_CONFIG}" ]; then
    cp /scripts/config/emulators.rc "${EMULATORS_CONFIG}"
fi

# Carregar configurações
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ "$line" == BOX64_* ]] || [[ "$line" == FEX_* ]]; then
        export "$line"
        log_info "Emulator config: $line"
    fi
done < "${EMULATORS_CONFIG}"
```

### Fase 4: docker-compose.yml

**Adicionar suporte NTSync (opcional):**

```yaml
services:
  vrising:
    # ... configurações existentes ...
    
    # NTSync - OPCIONAL
    # Descomente se seu host tiver kernel 6.14+ com NTSync
    # devices:
    #   - /dev/ntsync:/dev/ntsync
```

### Fase 5: Documentação

**Atualizar README.md com:**

1. Requisitos de kernel para NTSync
2. Como verificar se NTSync está disponível
3. Como habilitar NTSync no host
4. Performance esperada com/sem NTSync

---

## 🚀 Variáveis de Ambiente Novas

| Variável | Default | Descrição |
|----------|---------|-----------|
| `NTSYNC_ENABLED` | `auto` | `auto`, `true`, `false` - controle manual |
| `BOX64_DYNAREC_STRONGMEM` | `1` | Compatibilidade de memória |
| `BOX64_DYNAREC_BIGBLOCK` | `0` | Tamanho de bloco JIT |

---

## ⚠️ Considerações Importantes

### Para Ubuntu 25.04

1. **Ainda não é LTS** - menos estável que 24.04
2. **Requer host com kernel 6.14+** - hosts EasyPanel podem não ter
3. **ARM64 suporte experimental** em Ubuntu cloud images

### Alternativa: Continuar sem NTSync

Se o host não suportar NTSync:
- Wine staging-tkg ainda é melhor que vanilla
- fsync/esync funcionam como fallback
- Performance ainda será boa

### BepInEx

O projeto de referência usa uma versão modificada do Il2CppInterop:
- https://github.com/tsx-cloud/Il2CppInterop/commits/v-rising_1.1_arm_friendly/

Isso resolve problemas de threading no ARM64. Podemos:
1. Usar esta versão modificada
2. Ou continuar com nossa abordagem de pré-gerar assemblies

---

## 📝 Próximos Passos

1. **Decisão:** Qual abordagem seguir (A, B ou C)?
2. **Teste:** Verificar se host Oracle ARM suporta kernel 6.14
3. **Implementação:** Aplicar mudanças escolhidas
4. **Validação:** Testar com e sem NTSync

---

## 📚 Referências

- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)
- [Kron4ek/Wine-Builds](https://github.com/Kron4ek/Wine-Builds)
- [NTSync no Linux 6.14](https://www.phoronix.com/news/NTSync-Merged-Linux-6.14)
- [Wine NTSync Documentation](https://wiki.winehq.org/Ntsync)
- [Box64 Usage](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)
