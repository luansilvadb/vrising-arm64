# BepInEx Prebuilt Files

Este diretório contém arquivos pré-gerados para evitar problemas no ARM64.

## interop/

Contém os assemblies de interoperabilidade gerados via GitHub Actions.

### Como gerar:

1. Fazer push do projeto para GitHub
2. Ir em **Actions** → **Generate BepInEx Interop**
3. Clicar em **Run workflow**
4. Aguardar ~15-20 minutos
5. Baixar o artifact `vrising-bepinex-interop`
6. Extrair em `bepinex/prebuilt/interop/`
7. Commit e push

### Por que isso é necessário?

O BepInEx usa `Il2CppInterop` para gerar assemblies que permitem mods se comunicarem com o jogo. No ARM64 (via Box64), esta geração **trava** porque o código usa `Parallel.ForEach` que não funciona bem com emulação.

A solução é gerar em x86_64 (via GitHub Actions) e copiar para o ARM64.
