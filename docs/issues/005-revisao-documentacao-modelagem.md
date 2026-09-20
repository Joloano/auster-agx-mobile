# Issue 005 — Revisão da documentação e dos modelos de dados

## Objetivo

Elevar a documentação do repositório ao padrão esperado de um projeto profissional e garantir que os modelos de banco de dados publicados sejam revisáveis e verificáveis, sem alterar o comportamento do aplicativo.

## Motivação

A auditoria do repositório apontou os seguintes problemas:

- O README não possui sumário, seção de pré-requisitos, licença nem identificação de autoria.
- A seção "Estrutura do repositório" descreve `scripts/` como "automação de publicação e criação de issues", mas o diretório contém o gerador dos modelos ER e o script de publicação.
- O `.env.example` documenta duas opções, enquanto o README documenta três.
- O modelo físico do cache SQLite só existe como PNG e como `.brM3` binário, formatos que não podem ser revisados em diff nem conferidos automaticamente.
- O repositório não possui `.gitattributes`, então arquivos gravados no Windows aparecem como modificados apenas por CRLF a cada commit.

## Critérios de aceite

- README com sumário navegável, pré-requisitos, licença e autoria.
- Descrição de `scripts/` corrigida e alinhada ao conteúdo real do diretório.
- `.env.example` alinhado às opções documentadas no README e em `INSTALACAO.md`.
- DDL versionado do cache SQLite publicado em `docs/modelo-er/auster-agx-mobile-fisico.sql`.
- Diagrama ER textual do cache SQLite no índice da modelagem, renderizável no GitHub.
- `.gitattributes` definindo `eol=lf` para texto e tratamento binário para PNG, `.brM3` e fontes.
- `node scripts/gerar-modelos-er.mjs` continua validando 28 entidades, 41 relacionamentos, 35 tabelas e 48 FKs.
- Todos os links relativos do README e do índice da modelagem continuam resolvendo.

## Fora do escopo

- Alterar o schema do cache SQLite ou qualquer regra do backend oficial.
- Alterar código Dart de produção.

## Status

Em andamento.
