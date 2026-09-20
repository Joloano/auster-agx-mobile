# Issue 002 — Dashboard e demandas mobile

## Objetivo

Exibir dashboard e lista de demandas usando os endpoints reais do AusterAgX.

## Critérios de aceite

- Dashboard consome `GET /dashboard/resumo`.
- Lista inicial consome `GET /dashboard/demandas`.
- Detalhe consome `GET /demandas/{id}/detalhe`.
- O aplicativo exibe estados de carregamento, erro, vazio e offline.

## Decisão de UX

No mobile, priorizar lista agrupada por status e filtros simples em vez de tabela Kanban larga.

## Status

Concluída.
