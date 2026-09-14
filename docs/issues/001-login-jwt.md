# Issue 001 - Login REST com JWT

## Objetivo

Implementar login usando `POST /auth/login`, persistir tokens em armazenamento seguro e validar sessao com `GET /auth/me`.

## Criterios de aceite

- Tela de login envia `email` e `senha`.
- JWT e refresh token sao armazenados em `flutter_secure_storage`.
- Requisicoes autenticadas enviam `Authorization: Bearer <token>`.
- Erros 401/403, servidor indisponivel e sem conexao sao tratados na UI.

## Endpoints

- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/refresh`
- `POST /auth/logout`
