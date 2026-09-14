# Investigacao da API AusterAgX

Referencia analisada:

```text
C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\AusterAgX-Mobile-Reference
```

## Autenticacao e seguranca

Arquivos consultados:

- `backend/auster-auth/src/main/java/com/austertec/auster_agx/auth/web/AuthController.java`
- `backend/auster-auth/src/main/java/com/austertec/auster_agx/auth/security/SecurityConfig.java`
- `frontend/src/data/auth/authApi.ts`
- `frontend/src/data/http/setupHttpInterceptors.ts`

O backend usa JWT stateless. Rotas liberadas sem JWT incluem `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, recuperacao de senha, Google OAuth, health check e Swagger. As demais rotas exigem autenticacao.

O refresh token e rotacionado: reapresentar refresh token ja usado e tratado como possivel roubo de sessao.

## Endpoints do MVP

| Funcionalidade | Endpoint | Metodo | Request | Response | Precisa JWT? | Observacoes |
|---|---|---|---|---|---|---|
| Login | `/auth/login` | POST | `{ "email": string, "senha": string }` | `accessToken`, `tokenType`, `expiresIn`, `refreshToken`, `userId`, `nome`, `email`, `perfil`, `authority`, `deveAlterarSenha` | Nao | Contrato real de `LoginRequest` e `AuthResponse`. |
| Renovar token | `/auth/refresh` | POST | `{ "refreshToken": string }` | mesmo formato do login | Nao | Refresh token rotaciona a cada uso. |
| Logout | `/auth/logout` | POST | `{ "refreshToken": string }` | 204 sem corpo | Nao | Revoga refresh token no servidor. |
| Usuario logado | `/auth/me` | GET | sem corpo | `userId`, `nome`, `email`, `perfil`, `authority`, `ativo`, `deveAlterarSenha` | Sim | Usado para validar sessao salva. |
| Resumo dashboard | `/dashboard/resumo` | GET | sem corpo | metricas de clientes, fazendas, talhoes, areas e maiores fazendas | Sim | Visao global ou carteira conforme perfil. |
| Demandas painel | `/dashboard/demandas` | GET | query `arquivada`, `pagina`, `tamanho` | pagina com demandas do painel | Sim | Fonte principal da lista mobile inicial. |
| Lista demandas | `/demandas` | GET | exige uma query entre `pedidoId`, `fazendaId`, `talhaoId`, `clienteId` ou `busca`; aceita `status`, `pagina`, `tamanho` | pagina de `DemandaResponse` | Sim | Nao usar sem filtro, backend retorna erro. |
| Detalhe demanda | `/demandas/{id}/detalhe` | GET | path `id` UUID | demanda, pedido, cliente, fazendas, grupos, talhoes, sensoriamentos, culturas e cadeia | Sim | Endpoint agregado ideal para tela de detalhe. |
| Atualizar demanda | `/demandas/{id}` | PATCH | `tipo`, `representanteId`, `prazo`, `areaDeInteresse`, `status`, `situacaoDados`, `situacaoMapeamento`, `retrabalho` | `DemandaResponse` | Sim | Requer `SUPER_ADMIN` ou `USUARIO_TECNICO_PRESCRICAO`. |
| Fluxo de status | `/demandas/status-fluxo` | GET | sem corpo | `ordem`, `transicoesValidas`, `exigeDadosPreenchidos`, `exigeMapeamentoConcluido` | Sim | Fonte real das transicoes. |
| Historico status | `/demandas/{id}/historico-status` | GET | path `id` UUID | lista de alteracoes de status | Sim | Util para evolucao futura. |

## Campos de demanda relevantes

`DemandaResponse` real contem:

- `id`
- `pedidoId`
- `pedidoCodigo`
- `clienteNome`
- `fazendaNomes`
- `codigoDemanda`
- `tipo`
- `status`
- `statusChave`
- `situacaoDados`
- `situacaoMapeamento`
- `retrabalho`
- `demandaOrigemId`
- `numeroAplicacao`
- `representanteId`
- `representanteNome`
- `prazo`
- `areaDeInteresse`
- `grupoIds`
- `sensoriamentoIds`
- `ativo`
- `createdAt`

`DashboardDemandaPainelResponse` real contem:

- `id`
- `tipo`
- `codigo`
- `aplicacao`
- `fazenda`
- `talhoes`
- `areaHa`
- `cultura`
- `dataPrevista`
- `representanteId`
- `responsavelNome`
- `status`
- `situacaoDados`
- `situacaoMapeamento`
- `metodoMapeamento`
- `arquivada`
- `areaDeInteresse`
- `retrabalho`

## Recurso nativo GPS

Nao encontrei endpoint de demanda especifico para receber latitude, longitude, precisao e horario de captura.

Ha campos de latitude/longitude em fazendas e talhoes, mas eles pertencem a outro fluxo de cadastro. Por seguranca, o MVP captura GPS localmente no detalhe da demanda e guarda no banco local academico. A sincronizacao de GPS com o backend deve ser discutida apenas se for criado um endpoint real.
