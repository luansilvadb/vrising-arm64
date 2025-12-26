# Guia: Como Rodar Mods de V Rising em Servidor ARM64 (Método Local-Fix)

Este guia resolve o problema de **travamento (crash)** que ocorre ao tentar rodar o BepInEx/Mods em servidores com processador ARM (Raspberry Pi, Oracle Cloud, etc.) através do Docker.

O segredo não é "compilar" a ponte no ARM, mas sim **gerar os arquivos em um PC normal** e transplantá-los para o servidor.

## Pré-requisitos

1. Um **PC Windows ou Linux (x64)** com o jogo ou servidor instalado.
2. O seu servidor **ARM64** rodando o Docker.
3. Acesso aos arquivos do servidor (via FTP, SFTP ou terminal).

---

## Passo 1: Gerar os Arquivos (No seu PC)

Você precisa fazer o BepInEx rodar **uma vez** num computador normal para ele criar os arquivos necessários.

1. Baixe o **BepInExPack V Rising** (use o Thunderstore ou GitHub).
2. Instale no seu **V Rising Dedicado** (no PC/SteamCMD) ou no próprio Jogo Local.
   - Extraia o conteúdo para a pasta do jogo/servidor.
   - Deve ficar assim: `.../VRisingServer/BepInEx/` e `.../VRisingServer/winhttp.dll`.
3. **Inicie o Servidor/Jogo**.
4. Espere ele carregar totalmente.
5. Feche o jogo/servidor.
6. Vá até a pasta `BepInEx`.
   - Verifique se apareceu uma pasta chamada `interop` (ou `unhollowed` em versões antigas).
   - Verifique se dentro de `BepInEx/plugins` já tem mods básicos.
7. **Empacote tudo**: Crie um `.zip` contendo:
   - A pasta `BepInEx/` (inteira, com a `interop` gerada dentro).
   - O arquivo `winhttp.dll`.
   - O arquivo `doorstop_config.ini`.

---

## Passo 2: Preparar o Servidor ARM (Docker)

Antes de enviar os arquivos, precisamos garantir que o script de inicialização do servidor não delete seus mods.

1. Abra seu arquivo `docker-compose.yml`.
2. Na seção `environment`, adicione ou altere a variável `ENABLE_MODS`:

```yaml
    environment:
      - ENABLE_MODS=true  # <--- IMPORTANTE: Se não colocar true, ele apaga os mods!
      # ... outras variáveis ...
```

3. Reinicie o container para aplicar a configuração (sem os mods ainda):
   ```bash
   docker compose up -d
   ```

---

## Passo 3: Transplante (Injeção dos Arquivos)

Agora vamos colocar os arquivos gerados no Passo 1 dentro do servidor ARM.

### Opção A: Usando `docker cp` (Mais fácil)

Supondo que seu container se chama `vrising-fex` (padrão do seu compose):

1. Envie o `.zip` do Passo 1 para a máquina onde está o Docker.
2. Descompacte o zip numa pasta temporária (ex: `meus_mods`).
3. Copie para dentro do volume do servidor (`/data/server`):

```bash
# Copia o winhttp.dll
docker cp meus_mods/winhttp.dll vrising-fex:/data/server/

# Copia o doorstop_config.ini
docker cp meus_mods/doorstop_config.ini vrising-fex:/data/server/

# Copia a pasta BepInEx inteira
docker cp meus_mods/BepInEx vrising-fex:/data/server/
```

### Opção B: Se você usa Bind Mounts
Se você mudou seu `docker-compose.yml` para usar pastas locais (ex: `./data:/data`), basta colar os arquivos na pasta `data/server` do host.

---

## Passo 4: Configuração Final (O Pulo do Gato)

Para evitar que o servidor tente "regenerar" os arquivos e trave de novo, precisamos blindar a configuração.

1. Entre no container para editar a config (ou edite o arquivo se tiver acesso direto):
   ```bash
   docker exec -it vrising-fex bash
   ```
2. Vá para a pasta do BepInEx:
   ```bash
   cd /data/server/BepInEx/config
   ```
   *(Se a pasta config não existir, rode o servidor uma vez com os arquivos lá, espere travar/carregar, e veja se cria).*

3. Edite o arquivo `BepInEx.cfg` (se existir). Procure por configurações relacionadas a **Dump** ou **Unhollower**.
   - Geralmente não precisa mexer se você copiou a pasta `interop` completa. O BepInEx detecta que as DLLs já existem e pula a geração.

---

## Passo 5: Teste

1. Reinicie o container:
   ```bash
   docker compose restart
   ```
2. Acompanhe os logs imediatamente:
   ```bash
   docker compose logs -f
   ```

**O que você deve ver no Log:**
- `[Info : BepInEx] Legacy BepInEx version detected` (ou similar)
- `[Info : BepInEx] Chainloader ready`
- **NÃO DEVE VER**: Erros gigantes de "Il2CppInterop", "Segmentation Fault" ou travamentos longos na inicialização.

## Como Adicionar Novos Mods?

Sempre que quiser adicionar um mod novo (`.dll`):
1. Coloque o `.dll` na pasta `BepInEx/plugins` do servidor.
2. Se o mod depender apenas de funções padrão do jogo, vai funcionar.
3. **Cuidado**: Se o mod exigir novas classes que não foram mapeadas na sua pasta `interop` antiga, você pode precisar refazer o **Passo 1** no PC e atualizar a pasta `interop` do servidor.
