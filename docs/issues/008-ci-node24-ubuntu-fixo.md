# Issue 008 — CI em Node.js 24 e com imagem do Ubuntu fixa

## Objetivo

Eliminar os avisos da primeira execução da CI antes que eles virem falhas.

## Motivação

A execução de 21 de setembro de 2026 passou nos dois jobs, mas deixou quatro anotações:

- `actions/checkout@v4` e `actions/setup-node@v4` rodam em Node.js 20, que o GitHub está desativando e já força para Node.js 24.
- O rótulo `ubuntu-latest` passa a apontar para o Ubuntu 26 a partir de 19 de outubro de 2026. A troca de imagem pode mudar pacotes do sistema, como o SQLite nativo usado pelos testes, sem nenhum commit no repositório.

## Critérios de aceite

- `actions/checkout@v5` e `actions/setup-node@v5`, que declaram `node24`.
- Os dois jobs em `ubuntu-24.04`; a atualização para uma imagem nova passa a ser uma decisão explícita.
- Workflow sem erros no `actionlint`.
- Próxima execução da CI sem avisos de depreciação.

## Status

Em andamento.
