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

## Sincronizacao

Alteracoes feitas sem internet entram em `sync_queue`. Ao detectar conectividade, `SyncService` tenta enviar as operacoes pendentes e atualiza o cache local.

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

O repositorio local esta pronto para publicacao. Depois de autenticar o GitHub CLI:

```powershell
gh auth login
```

Criar o repositorio remoto, fazer push e abrir as issues versionadas:

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
7. Alterar status permitido.
8. Ver alteracao pendente.
9. Religar internet.
10. Sincronizar com servidor.
11. Abrir detalhe.
12. Capturar GPS.

## Limitacoes

- GPS nao sincroniza com backend porque nao foi encontrado endpoint real para coordenadas de demanda.
- Resolucao distribuida de conflito esta fora do MVP.
- Issues foram criadas como arquivos locais porque `gh` nao esta autenticado nesta maquina.
- Web/Windows desktop nao sao alvos suportados neste MVP; o app usa SQLite via FFI para o armazenamento offline mobile.

## Possiveis melhorias

- Criar endpoint oficial para registrar check-in/localizacao em demanda.
- Adicionar notificacoes de sincronizacao.
- Expandir testes de widget.
- Publicar issues no GitHub quando houver autenticacao do `gh`.
