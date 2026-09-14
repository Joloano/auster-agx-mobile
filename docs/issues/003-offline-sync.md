# Issue 003 - Offline-first e fila de sincronizacao

## Objetivo

Persistir demandas localmente e registrar alteracoes offline em fila para sincronizar quando a conexao voltar.

## Criterios de aceite

- Leituras usam banco local como fonte para a UI.
- Quando online, API atualiza o banco local.
- Alteracoes offline entram em `sync_queue`.
- `SyncService` processa pendencias ao detectar internet.
- Falhas incrementam tentativas e permanecem pendentes.

## Estrategia de conflito

MVP usa ultima escrita do app local. Conflitos avancados ficam fora do escopo academico inicial.
