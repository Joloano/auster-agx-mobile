# Issue 007 — Licença, ambiente com um comando, scripts versionados e CI

## Objetivo

Fechar as lacunas de infraestrutura do repositório mantendo o aplicativo Flutter na raiz: licença explícita, ambiente de desenvolvimento reprodutível, scripts de apoio versionados e integração contínua.

## Motivação

- O README declara uso acadêmico, mas não existe arquivo de licença; o GitHub exibe o repositório como "sem licença".
- Subir o ambiente exige passos manuais frágeis: `docker compose` do backend, `mvnw install` antes do `-pl auster-erp`, seed com `docker cp` e `psql`, e um checksum do Flyway que só aparece em bancos antigos.
- Os scripts que automatizam esse fluxo ficaram fora do Git, na pasta acima do repositório.
- Nada impede que um commit quebre análise estática, testes ou deixe os modelos de dados desatualizados.

## Critérios de aceite

- `LICENSE` com MIT para o código do aplicativo e `NOTICE` excluindo marca, logotipos e ícones da AUSTER, a API AusterAgX e as fontes sob SIL OFL 1.1.
- `docker-compose.yml` na raiz sobe Postgres/PostGIS, a API AusterAgX construída a partir do repositório do backend e aplica a massa de teste apenas quando o banco está vazio.
- O caminho do backend é configurável por `AUSTERAGX_BACKEND_DIR`, sem copiar código da AusterTec para este repositório.
- `scripts/dev/subir-ambiente.ps1` sobe o ambiente e executa o app no emulador ou gera o APK para celular com o IP da rede Wi-Fi.
- `scripts/dev/diagnosticar-api.ps1` confere API, login, massa de teste e dispositivos conectados.
- Workflow de CI executa `flutter analyze`, `flutter test` e falha se os artefatos de `docs/modelo-er` estiverem desatualizados.
- README e `INSTALACAO.md` descrevem o novo fluxo.

## Fora do escopo

- Incluir o código do backend neste repositório.
- Mover o aplicativo Flutter para uma subpasta.

## Status

Em andamento.
