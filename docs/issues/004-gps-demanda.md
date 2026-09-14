# Issue 004 - Registrar localizacao via GPS

## Objetivo

Permitir capturar GPS no detalhe de uma demanda e armazenar latitude, longitude, precisao e horario no banco local.

## Criterios de aceite

- App solicita permissao de localizacao.
- Trata permissao negada, permissao permanentemente negada e GPS desligado.
- Mostra coordenadas capturadas na tela de detalhe.
- Nao envia GPS ao backend enquanto nao existir endpoint real.
