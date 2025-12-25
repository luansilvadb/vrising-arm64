# 🔧 Troubleshooting: NTSync e BepInEx

> **Data:** 2025-12-25  
> **Contexto:** V Rising Dedicated Server ARM64 Docker

---

## 📋 Resumo Executivo

| Problema | Causa Raiz | Status | Solução |
|----------|-----------|--------|---------|
| **NTSync: false** | `/dev/ntsync` não existe no HOST | ⚠️ Impacto: Performance | Criar device no HOST ou desabilitar |
| **BepInEx não carrega** | Arquivos críticos faltando ou Il2CppInterop crash | ❌ Mods não funcionam | Verificar arquivos, reinstalar |

---

## 🔴 Problema 1: NTSync não funciona

### Diagnóstico dos Logs

```
[NTSYNC] Kernel version on this machine is -- 6.14.0-1016-oracle
[INFO] NTSYNC module detected via lsmod, but /dev/ntsync not mapped.
[WARNING] Add 'devices: - /dev/ntsync:/dev/ntsync' to docker-compose.yml
[NTSYNC] NTSync Status: false
```

### O que está acontecendo?

1. ✅ **Kernel 6.14.0** - Correto, NTSync foi merged no 6.14
2. ✅ **Módulo ntsync carregado** - `lsmod` detecta o módulo
3. ❌ **Device `/dev/ntsync` não existe** - O módulo está carregado mas o device não foi criado

### Causa Raiz

O kernel **6.14.0-1016-oracle** é um kernel customizado pela Oracle para Oracle Cloud Infrastructure. Mesmo que o módulo `ntsync` apareça no `lsmod`, o device `/dev/ntsync` pode não ser criado automaticamente por:

1. **CONFIG_NTSYNC não habilitado** na compilação do kernel Oracle
2. **Módulo stub** - Existe mas não faz nada
3. **Permissões/udev** - Device criado mas não acessível

### Solução - Passos no HOST (fora do container)

```bash
# 1. Verificar se kernel tem suporte real a NTSync
grep -i NTSYNC /boot/config-$(uname -r)
# Esperado: CONFIG_NTSYNC=m ou CONFIG_NTSYNC=y
# Se não aparecer: kernel não suporta NTSync

# 2. Verificar se device existe
ls -la /dev/ntsync
# Se "No such file or directory": device não foi criado

# 3. Tentar carregar módulo
sudo modprobe ntsync
# Se erro: módulo não está disponível

# 4. Verificar dmesg
dmesg | grep -i ntsync
# Procurar por erros ou mensagens de sucesso

# 5. Verificar minor number (se módulo carregou)
grep ntsync /proc/misc
# Se aparecer número: módulo está ativo

# 6. Criar device manualmente (temporário)
# Primeiro descobrir minor do /proc/misc, exemplo: "236 ntsync"
sudo mknod /dev/ntsync c 10 236
sudo chmod 666 /dev/ntsync
```

### Criar Regra udev (persistente)

```bash
# Criar regra udev para criar device automaticamente
echo 'KERNEL=="ntsync", MODE="0666"' | sudo tee /etc/udev/rules.d/99-ntsync.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Recarregar módulo
sudo modprobe -r ntsync
sudo modprobe ntsync

# Verificar
ls -la /dev/ntsync
```

### Alternativa: Desabilitar NTSync

Se NTSync não funcionar no seu kernel Oracle, **o servidor funciona perfeitamente sem ele**:

**Editar `docker-compose.yml`:**
```yaml
services:
  vrising:
    # ...
    
    # Comentar ou remover estas linhas:
    # devices:
    #   - /dev/ntsync:/dev/ntsync
```

**Impacto:**
- Performance ~30-50% menor que com NTSync
- Mas ainda funciona bem para servidor dedicado
- tsx-cloud documenta que é opcional

---

## 🔴 Problema 2: BepInEx não carrega

### Diagnóstico dos Logs

```
[BEPINEX] ENABLE_PLUGINS=true
[BEPINEX] BepInEx already installed, checking for updates...
[BEPINEX] Enabling BepInEx plugins...
[SUCCESS] Plugins ENABLED in doorstop_config.ini
[BEPINEX] Wine DLL override set: winhttp=n,b
...
[INFO] Executando VRisingServer.exe via Wine (staging-tkg)...
[UnityMemory] Configuration Parameters...
```

### O que está acontecendo?

O BepInEx parece estar configurado, mas **não há nenhum log do BepInEx após o servidor iniciar**. Se estivesse funcionando, você veria:

```
[Info :   BepInEx] BepInEx 6.0.0-pre.2 - VRisingServer
[Info : Preloader] Loading [BepInEx.Unity.IL2CPP]
```

### Causas Prováveis (em ordem de probabilidade)

#### 1. 🔴 `winhttp.dll` não existe

O BepInEx usa `winhttp.dll` como proxy DLL para injetar o Doorstop. Se não existir, nada carrega.

**Verificar:**
```bash
docker exec -it vrising-server ls -la /data/server/winhttp.dll
```

**Se não existir:**
```bash
docker exec -it vrising-server bash
cd /tmp
wget -q "https://github.com/BepInEx/BepInEx/releases/download/v6.0.0-pre.2/BepInEx-Unity.IL2CPP-win-x64-6.0.0-pre.2.zip"
unzip -o BepInEx-Unity.IL2CPP-win-x64-6.0.0-pre.2.zip
cp winhttp.dll /data/server/
```

#### 2. 🔴 `dotnet/coreclr.dll` não existe

BepInEx 6 IL2CPP precisa do CoreCLR runtime.

**Verificar:**
```bash
docker exec -it vrising-server ls -la /data/server/dotnet/
# Deve ter: coreclr.dll, System.*.dll, etc.
```

**Se não existir:**
```bash
# O diretório dotnet vem junto com o BepInEx
docker exec -it vrising-server bash
cd /tmp
wget -q "https://github.com/BepInEx/BepInEx/releases/download/v6.0.0-pre.2/BepInEx-Unity.IL2CPP-win-x64-6.0.0-pre.2.zip"
unzip -o BepInEx-Unity.IL2CPP-win-x64-6.0.0-pre.2.zip
cp -r dotnet /data/server/
```

#### 3. 🟡 Il2CppInterop crash com Box64

O BepInEx padrão usa multithreading no Il2CppInterop para gerar assemblies, o que causa crash ou hang com Box64.

**Sintomas:**
- Servidor trava na primeira inicialização com ENABLE_PLUGINS=true
- Nenhum log após "Starting server..."

**Solução:**
Usar o fork do tsx-cloud que desabilita multithreading:
- https://github.com/tsx-cloud/Il2CppInterop/commits/v-rising_1.1_arm_friendly/

Ou pré-gerar assemblies em máquina x86_64.

#### 4. 🟡 Instalação incompleta não detectada

O script `setup_bepinex.sh` verifica apenas:
- Se `/data/server/BepInEx/core` existe
- Se `/data/server/doorstop_config.ini` existe

Mas **não verifica** se `winhttp.dll` ou `dotnet/` existem.

### Solução Completa: Reinstalação Limpa

```bash
# 1. Entrar no container
docker exec -it vrising-server bash

# 2. Limpar instalação anterior
rm -rf /data/server/BepInEx
rm -f /data/server/doorstop_config.ini
rm -f /data/server/winhttp.dll
rm -rf /data/server/dotnet

# 3. Sair do container
exit

# 4. Reiniciar container (vai reinstalar BepInEx)
docker restart vrising-server

# 5. Verificar logs
docker logs -f vrising-server
```

### Verificar se BepInEx carregou

Após reiniciar, procurar nos logs por:
```
[Info   :   BepInEx] BepInEx 6.0.0-pre.2
[Message: Preloader] Preloader started
[Info   :Cpp2IL] Running Cpp2IL...
```

Se aparecer "Cpp2IL", o BepInEx está gerando os assemblies (primeira execução demora).

---

## 🔍 Debug Avançado

### Habilitar logs detalhados do Wine

```bash
# No docker-compose.yml ou entrypoint.sh
export WINEDEBUG="warn+all"
# Ou para DLL loading:
export WINEDEBUG="trace+loaddll"
```

### Verificar DLL overrides

```bash
docker exec -it vrising-server bash
echo $WINEDLLOVERRIDES
# Esperado: mscoree=d;mshtml=d;dnsapi=b;winhttp=n,b
```

### Verificar Wine registry

```bash
docker exec -it vrising-server bash
cat /data/wine/user.reg | grep -i winhttp
# Deve mostrar override para winhttp
```

### Testar winhttp.dll manualmente

```bash
docker exec -it vrising-server bash
cd /data/server
wine cmd /c "echo %windir%"
# Se funcionar, Wine está ok
```

---

## 📊 Checklist de Verificação

### NTSync

- [ ] Kernel é 6.14+ (`uname -r`)
- [ ] CONFIG_NTSYNC habilitado (`grep NTSYNC /boot/config-*`)
- [ ] Módulo carregado (`lsmod | grep ntsync`)
- [ ] Device existe (`ls -la /dev/ntsync`)
- [ ] Permissões OK (`stat /dev/ntsync`)
- [ ] Docker tem acesso (`privileged: true` ou `devices:`)

### BepInEx

- [ ] `winhttp.dll` existe em `/data/server/`
- [ ] `dotnet/coreclr.dll` existe
- [ ] `BepInEx/core/BepInEx.Unity.IL2CPP.dll` existe
- [ ] `doorstop_config.ini` tem `enabled = true`
- [ ] WINEDLLOVERRIDES inclui `winhttp=n,b`
- [ ] Logs mostram BepInEx inicializando

---

## 🚀 Recomendações

### Curto Prazo

1. **NTSync:** Se não funcionar no kernel Oracle, desabilite. É opcional.
2. **BepInEx:** Verificar se `winhttp.dll` existe. Forçar reinstalação se necessário.

### Médio Prazo

1. **Atualizar `setup_bepinex.sh`** para verificar `winhttp.dll` e `dotnet/`
2. **Considerar tsx-cloud image** como referência ou base

### Longo Prazo

1. **Pré-gerar assemblies Interop** em CI/CD (x86_64) e incluir na imagem
2. **Usar fork Il2CppInterop** do tsx-cloud para compatibilidade ARM64

---

## 📚 Referências

- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)
- [tsx-cloud/Il2CppInterop (ARM-friendly fork)](https://github.com/tsx-cloud/Il2CppInterop)
- [BepInEx Documentation](https://docs.bepinex.dev)
- [Wine DLL Overrides](https://wiki.winehq.org/Wine_User's_Guide#WINEDLLOVERRIDES)
- [NTSync Linux Kernel](https://wiki.winehq.org/Ntsync)
