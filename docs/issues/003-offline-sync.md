# Issue 003 — Offline-first e fila de sincronização

## Objetivo

Persistir demandas localmente e registrar alterações offline em fila para sincronizar quando a conexão voltar.

## Critérios de aceite

- Leituras usam o banco local como fonte para a UI.
- Quando online, a API atualiza o banco local.
- Alterações offline entram em `sync_queue`.
- `SyncService` processa pendências ao detectar internet.
- Falhas transitórias incrementam tentativas e permanecem pendentes.
- Rejeições permanentes são bloqueadas para não gerar repetição infinita.

## Estratégia de conflito

O MVP usa a última escrita do aplicativo local. Conflitos avançados ficam fora do escopo acadêmico inicial.

## Status

Concluída.
