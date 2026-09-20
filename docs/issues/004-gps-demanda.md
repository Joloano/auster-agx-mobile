# Issue 004 — Registrar localização via GPS

## Objetivo

Permitir capturar o GPS no detalhe de uma demanda e armazenar latitude, longitude, precisão e horário no banco local.

## Critérios de aceite

- O aplicativo solicita permissão de localização em tempo de execução.
- Trata permissão negada, permissão permanentemente negada e GPS desligado.
- Mostra as coordenadas capturadas na tela de detalhe.
- Não envia o GPS ao backend enquanto não existir endpoint real.

## Status

Concluída.
