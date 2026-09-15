# AusterAgX Mobile

## Objetivo

Aplicativo Flutter academico para acompanhamento mobile de demandas do AusterAgX, com login REST, JWT, armazenamento offline, fila de sincronizacao e captura de GPS.

## Motivacao para versao mobile

Colaboradores podem consultar e atualizar demandas fora do computador, inclusive em areas com conectividade limitada. O app prioriza o fluxo de demandas, nao a conversao completa do ERP.

## Arquitetura

A organizacao segue o padrao do projeto de referencia `gestao-riscos-mobile`, separando base tecnica, camada de dados, telas por feature, rotas e widgets compartilhados:

```text
lib/
  app/
  routes/
  core/
    config/
    errors/
    network/
  data/
    local/
    models/
    repositorios/
    services/
    sync/
  features/
    authentication/
    dashboard/
    demandas/
    location/
    shell/
  widgets/
```

O shell usa `StatefulShellRoute.indexedStack`, como no app de referencia, para manter pilhas independentes entre Dashboard e Demandas. A barra global de sincronizacao fica em `widgets/sync_status_bar.dart`.

O comportamento de demandas foi alinhado ao AusterAgX oficial: o mobile usa os mesmos endpoints REST, o mesmo contrato de DTOs, os mesmos grupos operacionais do painel e as mesmas regras de transicao vindas de `/demandas/status-fluxo`.

## Modelo ER mobile/offline

O modelo local foi mantido enxuto para proteger a integridade do sistema oficial: o app mobile nao replica todo o ERP, apenas guarda o necessario para login, dashboard, demandas, fila offline e capturas de GPS. Os objetos principais da API ficam cacheados como JSON, preservando compatibilidade com o backend existente.

```mermaid
erDiagram
  AUTH_USER ||--|| AUTH_TOKENS : autentica
  DASHBOARD_OVERVIEW ||--o{ DASHBOARD_ITEM : resume
  DEMANDA ||--|| DEMANDA_DETAIL : detalha
  DEMANDA ||--o{ DEMANDA_STATUS_HISTORY : historico
  DEMANDA ||--o{ SYNC_QUEUE : gera
  DEMANDA ||--o{ LOCATION_CAPTURE : registra
  DEMANDA_DETAIL ||--o{ SENSORIAMENTO : inclui
  DEMANDA_DETAIL ||--o{ CULTURA : inclui
  STATUS_FLUXO ||--o{ SYNC_QUEUE : orienta

  AUTH_USER {
    string userId PK
    string nome
    string email
    string perfil
    string authority
    boolean ativo
    boolean deveAlterarSenha
  }

  AUTH_TOKENS {
    string accessToken
    string refreshToken
  }

  DASHBOARD_OVERVIEW {
    int id PK
    json payload
    datetime updated_at
  }

  DASHBOARD_ITEM {
    string id PK
    json payload
    datetime updated_at
  }

  DEMANDA {
    string id PK
    string pedidoId
    string codigoDemanda
    string tipo
    string status
    string statusChave
    string situacaoDados
    string situacaoMapeamento
  }

  DEMANDA_DETAIL {
    string id PK
    json payload
    datetime updated_at
  }

  DEMANDA_STATUS_HISTORY {
    string demanda_id PK
    json payload
    datetime updated_at
  }

  STATUS_FLUXO {
    int id PK
    json payload
    datetime updated_at
  }

  SENSORIAMENTO {
    string id PK
    string codigoMapeamento
    string fonte
    string status
  }

  CULTURA {
    int id PK
    string nome
  }

  SYNC_QUEUE {
    int id PK
    string operation_type
    string entity
    string entity_id
    json payload
    datetime created_at
    int attempts
    string status
  }

  LOCATION_CAPTURE {
    int id PK
    string demanda_id FK
    float latitude
    float longitude
    float accuracy
    datetime captured_at
  }
```

No SQLite, as tabelas reais sao `dashboard_overview`, `dashboard_items`, `demanda_details`, `demanda_status_history`, `status_fluxo`, `sync_queue` e `location_captures`. `AuthTokens` ficam no `flutter_secure_storage`; `AuthUser` e `Demanda` representam modelos da API usados pelo app e serializados nos payloads locais.

## Tecnologias

- Dio: cliente HTTP e interceptors.
- Riverpod: estado assíncrono e injecao de dependencias.
- GoRouter: navegacao declarativa.
- flutter_secure_storage: armazenamento seguro de JWT e refresh token.
- SQLite via sqlite3: cache local e fila de sincronizacao.
- connectivity_plus: monitoramento de conectividade.
- geolocator e permission_handler: GPS e permissoes nativas.

## Integracao com API

Endpoints reais documentados em `docs/investigacao-api.md`.

Durante desenvolvimento:

- Android Emulator: `http://10.0.2.2:8080`
- Celular fisico: usar o IP da maquina na rede local.

Configurar URL com:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Autenticacao

O login usa `POST /auth/login` com `email` e `senha`. A resposta contem `accessToken`, `refreshToken` e dados do usuario. Tokens ficam no armazenamento seguro, nunca em SharedPreferences.

## Funcionamento offline

Demandas sincronizadas sao salvas no SQLite. A UI le primeiro do banco local; quando existe internet, o repositorio busca a API, atualiza o banco e reflete os dados.

O cache inclui dashboard, detalhes agregados, historico de status e metadados de transicao. Assim, depois da primeira sincronizacao, o app continua mostrando o contexto operacional mesmo sem conexao.

## Sincronizacao

Alteracoes feitas sem internet entram em `sync_queue`. Ao detectar conectividade, `SyncService` tenta enviar as operacoes pendentes e atualiza o cache local.

O PATCH enviado para `/demandas/{id}` segue o contrato oficial: `tipo`, `representanteId`, `prazo`, `areaDeInteresse`, `status`, `situacaoDados`, `situacaoMapeamento` e `retrabalho`. A tela so oferece alteracao de status/dados/mapeamento para perfis administrativos (`SUPER_ADMIN` e `USUARIO_TECNICO_PRESCRICAO`), como no frontend oficial.

## Recurso nativo utilizado

GPS no detalhe da demanda. Como nao foi encontrado endpoint especifico para gravar coordenadas na demanda, a captura fica armazenada localmente no MVP.

## Como executar

Este workspace usa Flutter e Android SDK portateis em `C:\auster-mobile-tools`, para nao depender de instalacao global nem tocar no sistema oficial:

```powershell
cd "C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\auster_agx_mobile"

C:\auster-mobile-tools\flutter\bin\flutter.bat pub get
C:\auster-mobile-tools\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para evitar falhas do analysis server com o caminho acentuado `Área de Trabalho`, tambem existe um junction ASCII:

```powershell
cd C:\auster-mobile-work\auster_agx_mobile
```

## Testes

```powershell
C:\auster-mobile-tools\flutter\bin\flutter.bat analyze
C:\auster-mobile-tools\flutter\bin\flutter.bat test
```

## Publicacao no GitHub

O repositorio academico foi publicado como privado em:

```text
https://github.com/Joloano/auster-agx-mobile
```

Para repetir a publicacao em outro remoto ou recriar as issues versionadas:

```powershell
cd C:\auster-mobile-work\auster_agx_mobile
.\scripts\publish-github.ps1 -RepositoryFullName SEU_USUARIO/auster-agx-mobile -CreateRepo -CreateIssues
```

Para publicar em um repositorio ja existente:

```powershell
.\scripts\publish-github.ps1 -RepositoryFullName SEU_USUARIO/auster-agx-mobile -CreateIssues
```

## Demonstracao

1. Abrir app.
2. Login via API REST.
3. Receber JWT.
4. Ver dashboard/demandas.
5. Desligar internet.
6. Continuar vendo dados locais.
7. Alterar status, situacao dos dados ou situacao do mapeamento quando o perfil permitir.
8. Ver alteracao pendente e card local atualizado.
9. Religar internet.
10. Sincronizar com servidor.
11. Abrir detalhe com resumo, contexto, sensoriamento, cadeia e historico.
12. Capturar GPS.

## Prints das telas

Prints demonstrativos do fluxo mobile com dados de exemplo:

<p>
  <img src="docs/screenshots/mobile-login.png" alt="Tela de login do AusterAgX Mobile" width="180">
  <img src="docs/screenshots/mobile-dashboard.png" alt="Dashboard mobile com resumo e demandas recentes" width="180">
  <img src="docs/screenshots/mobile-demandas.png" alt="Lista mobile de demandas agrupadas por status" width="180">
  <img src="docs/screenshots/mobile-detalhe-demanda.png" alt="Detalhe mobile da demanda com status e GPS" width="180">
</p>

## Limitacoes

- GPS nao sincroniza com backend porque nao foi encontrado endpoint real para coordenadas de demanda.
- Resolucao distribuida de conflito esta fora do MVP.
- Web/Windows desktop nao sao alvos suportados neste MVP; o app usa SQLite via FFI para o armazenamento offline mobile.

## Possiveis melhorias

- Criar endpoint oficial para registrar check-in/localizacao em demanda.
- Adicionar notificacoes de sincronizacao.
- Expandir testes de widget.
