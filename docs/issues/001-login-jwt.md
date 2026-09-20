# Issue 001 — Login REST com JWT

## Objetivo

Implementar login usando `POST /auth/login`, persistir tokens em armazenamento seguro e validar a sessão com `GET /auth/me`.

## Critérios de aceite

- Tela de login envia `email` e `senha`.
- JWT e refresh token são armazenados em `flutter_secure_storage`.
- Requisições autenticadas enviam `Authorization: Bearer <token>`.
- Erros 401/403, servidor indisponível e ausência de conexão são tratados na UI.

## Endpoints

- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/refresh`
- `POST /auth/logout`

## Status

Concluída.
