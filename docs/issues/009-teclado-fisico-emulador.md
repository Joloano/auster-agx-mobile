# Issue 009 — Teclado do computador no emulador Android

## Objetivo

Fazer o teclado do computador digitar nos campos do app quando ele roda no emulador, sem ajuste manual no AVD.

## Motivação

O AVD `auster_test`, criado pelo `avdmanager` como descreve o `INSTALACAO.md`, vem com `hw.keyboard=no` no `config.ini`. Com esse valor o Android nem registra um teclado físico: `adb shell dumpsys input` não lista nenhum, e o teclado do computador não digita no login nem nos outros campos. Só o teclado virtual da tela funciona.

Com `hw.keyboard=yes` e um boot a frio, o `dumpsys input` passa a listar `AT Translated Set 2 keyboard` e a digitação volta a funcionar.

## Critérios de aceite

- `scripts/dev/subir-ambiente.ps1` localiza o `config.ini` do AVD (respeitando `ANDROID_AVD_HOME`, `ANDROID_USER_HOME` e o `path=` do `<nome>.ini`) e grava `hw.keyboard=yes` quando o valor for outro ou estiver ausente.
- Quando o arquivo muda, o emulador sobe com `-no-snapshot-load`, porque o snapshot guarda o hardware antigo; se ele já estiver aberto, o script o fecha com `adb emu kill` antes.
- Sem mudança no arquivo, o fluxo continua igual, com o boot rápido pelo snapshot.
- O `INSTALACAO.md` explica o problema e mostra a correção manual.

## Status

Concluída em 22 de setembro de 2026.
