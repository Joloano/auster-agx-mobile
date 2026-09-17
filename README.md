# AusterAgX Mobile

## Objetivo

Aplicativo Flutter acadêmico para acompanhamento mobile de demandas do AusterAgX, com login REST, JWT, troca obrigatória de senha temporária, armazenamento offline, fila de sincronização e captura de GPS.

## Motivação para versão mobile

Colaboradores podem consultar e atualizar demandas fora do computador, inclusive em áreas com conectividade limitada. O app prioriza o fluxo de demandas, não a conversão completa do ERP.

## Arquitetura

A organização segue o padrão do projeto de referência `gestao-riscos-mobile`, separando base técnica, camada de dados, telas por feature, rotas e widgets compartilhados:

```text
lib/
  app/
  routes/
  core/
    auth/
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

O shell usa `StatefulShellRoute.indexedStack`, como no app de referência, para manter pilhas independentes entre Dashboard e Demandas. A barra global de sincronização fica em `widgets/sync_status_bar.dart`.

O comportamento de demandas foi alinhado ao AusterAgX oficial: o mobile usa os mesmos endpoints REST, o mesmo contrato de DTOs, os mesmos grupos operacionais do painel e as mesmas regras de transição vindas de `/demandas/status-fluxo`.

## Identidade visual AUSTER

A interface reutiliza o logo bicolor oficial do AUSTER em `assets/branding/auster-logo-bicolor.png`, além das cores institucionais azul (`#0261BD`) e verde (`#00B37B`). Títulos usam Bebas Neue e os demais textos usam Inter, acompanhando o frontend oficial. Login, troca de senha, cabeçalho, navegação, dashboard, demandas e detalhes compartilham os mesmos componentes de identidade visual.

## Modelo ER e esquema local

Os dados foram documentados em dois níveis para não misturar o domínio do aplicativo com sua estratégia de cache. Ambos foram criados no [brModelo desktop](https://github.com/chcandido/brModelo) e os arquivos `.brM3` e XML foram reabertos e validados pelo motor do brModelo 3.2.0.

### MER conceitual

O MER apresenta as entidades do domínio offline e suas cardinalidades. Uma `DEMANDA` pode ter zero ou um `DETALHE_DEMANDA` e zero ou muitas ocorrências de `HISTORICO_STATUS`, `CAPTURA_LOCALIZACAO` e `OPERACAO_SINCRONIZACAO`. Cada ocorrência dependente pertence a exatamente uma demanda.

**Arquivos conceituais:** [editar no brModelo (`.brM3`)](docs/modelo-er/auster-agx-mobile.brM3) · [fonte XML](docs/modelo-er/auster-agx-mobile.xml) · [imagem em alta resolução](docs/modelo-er/auster-agx-mobile.png)

<p align="center">
  <img src="docs/modelo-er/auster-agx-mobile.png" alt="MER conceitual do AusterAgX Mobile criado no brModelo" width="100%">
</p>

### Esquema físico SQLite

O segundo modelo reproduz literalmente as sete tabelas criadas em `lib/data/local/app_database.dart`, incluindo tipos, chaves primárias, nulabilidade, valores padrão, `CHECK` e `AUTOINCREMENT`.

**Arquivos físicos:** [editar no brModelo (`.brM3`)](docs/modelo-er/auster-agx-mobile-fisico.brM3) · [fonte XML](docs/modelo-er/auster-agx-mobile-fisico.xml) · [imagem em alta resolução](docs/modelo-er/auster-agx-mobile-fisico.png)

<p align="center">
  <img src="docs/modelo-er/auster-agx-mobile-fisico.png" alt="Esquema físico do SQLite offline do AusterAgX Mobile no brModelo" width="100%">
</p>

| Conceito | Persistência física offline |
| --- | --- |
| Resumo de demanda | `dashboard_items.payload`, um JSON por `id` de demanda |
| Detalhe de demanda | `demanda_details.payload`, um JSON por `id` de demanda |
| Histórico de status | `demanda_status_history.payload`, uma lista JSON por `demanda_id` |
| Operação de sincronização | Uma linha em `sync_queue`; `entity` e `entity_id` identificam o agregado |
| Captura de localização | Uma linha em `location_captures` associada logicamente por `demanda_id` |
| Resumo do dashboard | Snapshot JSON único em `dashboard_overview`, com `id = 1` |
| Regras de transição | Snapshot JSON único em `status_fluxo`, com `id = 1` |

O SQLite atual não declara nenhuma `FOREIGN KEY`. Por isso, `demanda_id` e `entity_id` não são marcados como FKs e o modelo físico não desenha relacionamentos inexistentes. As associações aparecem somente no MER conceitual. Os payloads da API permanecem em JSON para preservar o contrato do backend e evitar duplicar o esquema transacional do ERP.

Cada usuário autenticado utiliza um arquivo SQLite próprio, com nome derivado de um hash SHA-256 do `userId`. O identificador não fica exposto no nome do arquivo e caches, fila offline e capturas GPS permanecem isolados entre contas no mesmo aparelho. A separação é física; o esquema de sete tabelas documentado abaixo continua idêntico em cada arquivo.

Credenciais, tokens e o último perfil autenticado não aparecem nos modelos porque ficam no `flutter_secure_storage`, fora do SQLite. Os objetos de demanda são reconstruídos a partir dos payloads da API e mantidos apenas como cache operacional.

## Tecnologias

- Dio: cliente HTTP e interceptors.
- Riverpod: estado assíncrono e injeção de dependências.
- GoRouter: navegação declarativa.
- flutter_secure_storage: armazenamento seguro de JWT, refresh token e perfil mínimo da sessão.
- SQLite via sqlite3: cache local e fila de sincronização.
- connectivity_plus: monitoramento de conectividade.
- geolocator e permission_handler: GPS e permissões nativas.

## Integração com API

Endpoints reais documentados em `docs/investigacao-api.md`. O aplicativo não replica validações transacionais do ERP: autenticação, autorização, transições de status e pré-requisitos continuam sendo validados pelo backend existente. O mobile consome `/demandas/status-fluxo` para projetar as ações permitidas e sempre submete a alteração ao endpoint oficial antes de considerá-la confirmada.

Erros HTTP são traduzidos em uma camada única antes de chegar às telas. O app diferencia sessão expirada, acesso negado, recurso ausente, indisponibilidade, timeout, limite de requisições e validações de negócio; detalhes técnicos e exceções internas não são exibidos ao usuário.

## Configuração da API

Durante desenvolvimento:

- Android Emulator: `http://10.0.2.2:8080`
- Celular físico: usar o IP da máquina na rede local.

As opções são definidas em tempo de compilação por `--dart-define`:

- `API_BASE_URL`: endereço base do backend; o padrão local é `http://10.0.2.2:8080`.
- `API_TIMEOUT_MS`: timeout das chamadas HTTP em milissegundos; o padrão é `10000`.
- `ALLOW_INSECURE_HTTP`: libera HTTP explicitamente. Em debug o padrão é `true`; em release, `false`.

Configurar URL com:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

O manifesto Android permite tráfego HTTP somente no build `debug`, para testes com a API na rede local. Builds de produção devem usar uma origem HTTPS sem caminho, query ou credenciais; a configuração é validada antes de o cliente HTTP ser criado.

## Autenticação

O login usa `POST /auth/login` com `email` e `senha`. A resposta contém `accessToken`, `refreshToken` e dados do usuário. Tokens ficam no armazenamento seguro, nunca em SharedPreferences.

Quando o backend retorna `deveAlterarSenha = true`, o app segue o comportamento do AUSTER oficial e bloqueia a navegação operacional até concluir `POST /auth/change-password`. O payload usa o contrato oficial (`novaSenha` e, quando aplicável, `senhaAtual`) e a resposta atualiza o usuário autenticado no estado da aplicação.

Durante a restauração da sessão, o roteador mantém uma tela neutra de carregamento. Dashboard, demandas e recursos operacionais só são montados depois da validação do usuário; links internos válidos são retomados após a autenticação.

O último perfil autenticado também é guardado no armazenamento seguro para permitir a abertura offline depois de um login validado. Falhas transitórias de conexão, timeout, `408`, `429` ou respostas `5xx` preservam tokens e usam esse perfil local. Somente ausência de refresh token ou rejeições definitivas `401/403` removem toda a sessão e notificam o estado global do aplicativo. Requisições concorrentes compartilham uma única renovação de token para evitar refresh duplicado.

## Funcionamento offline

Demandas sincronizadas são salvas no SQLite. A UI lê primeiro do banco local; quando existe internet, o repositório busca a API, atualiza o banco e reflete os dados. O cache substitui a resposta remota apenas em falhas transitórias de rede, timeout, `408`, `429` ou `5xx`; erros definitivos como `401`, `403`, `404` e violações de contrato continuam visíveis para o fluxo de autenticação e para a UI.

O cache inclui dashboard, detalhes agregados, histórico de status e metadados de transição. Assim, depois da primeira sincronização, o app continua mostrando o contexto operacional mesmo sem conexão. O cache é aberto somente depois da autenticação e é particionado por usuário para impedir exposição cruzada entre contas.

## Sincronização

Alterações feitas sem internet entram em `sync_queue`. Ao detectar conectividade, `SyncService` tenta enviar as operações pendentes. Depois de um PATCH aceito, detalhe e dashboard são reconciliados com a `Demanda` devolvida pelo backend antes de a operação ser concluída; assim, normalizações e decisões do servidor substituem corretamente o estado otimista local.

Para evitar envio redundante, a fila consolida a última operação pendente de uma mesma demanda antes da sincronização. O PATCH enviado para `/demandas/{id}` segue o contrato oficial: `tipo`, `representanteId`, `prazo`, `areaDeInteresse`, `status`, `situacaoDados`, `situacaoMapeamento` e `retrabalho`. A tela só oferece alteração de status, dados ou mapeamento para perfis administrativos (`SUPER_ADMIN` e `USUARIO_TECNICO_PRESCRICAO`), como no frontend oficial.

Falhas transitórias e `401` incrementam a tentativa e mantêm a operação pendente. Rejeições permanentes (`403`, `404`, `409`, `422` e demais `4xx`) mudam a operação para `failed`, aparecem na barra global e não entram em repetição infinita. Uma nova edição da mesma demanda substitui o payload rejeitado e reativa a operação para sincronização.

## Recurso nativo utilizado

GPS no detalhe da demanda. A captura funciona como evidência local de campo e fica separada do payload REST oficial para preservar o contrato atual do AUSTER.

## Como executar

Este workspace usa Flutter e Android SDK portáteis em `C:\auster-mobile-tools`, para não depender de instalação global nem tocar no sistema oficial:

```powershell
cd "C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\auster_agx_mobile"

C:\auster-mobile-tools\flutter\bin\flutter.bat pub get
C:\auster-mobile-tools\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para evitar falhas do analysis server com o caminho acentuado `Área de Trabalho`, também existe um junction ASCII:

```powershell
cd C:\auster-mobile-work\auster_agx_mobile
```

## Testar em um celular Android

1. Ative as opções do desenvolvedor e a depuração USB no aparelho.
2. Conecte computador e celular à mesma rede Wi-Fi e confirme o dispositivo com `adb devices`.
3. Descubra o IPv4 do computador com `ipconfig` e garanta que o backend aceite conexões da rede local.
4. Execute substituindo `IP_DO_COMPUTADOR` e `ID_DO_DISPOSITIVO` pelos valores reais:

```powershell
C:\auster-mobile-tools\flutter\bin\flutter.bat run -d ID_DO_DISPOSITIVO --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
```

Para gerar e instalar um APK release configurado para o celular:

```powershell
C:\auster-mobile-tools\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://api.exemplo.com
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

O APK precisa ter sido gerado com o `API_BASE_URL` acessível pelo celular; `10.0.2.2` funciona apenas no emulador Android. Para testar contra HTTP local, use `flutter run` em modo debug; o APK release exige HTTPS por padrão.

## Testes

```powershell
C:\auster-mobile-tools\flutter\bin\flutter.bat analyze
C:\auster-mobile-tools\flutter\bin\flutter.bat test
```

## Publicação no GitHub

O repositório acadêmico foi publicado em:

```text
https://github.com/Joloano/auster-agx-mobile
```

Para repetir a publicação em outro remoto ou recriar as issues versionadas:

```powershell
cd C:\auster-mobile-work\auster_agx_mobile
.\scripts\publish-github.ps1 -RepositoryFullName SEU_USUARIO/auster-agx-mobile -CreateRepo -CreateIssues
```

Para publicar em um repositório já existente:

```powershell
.\scripts\publish-github.ps1 -RepositoryFullName SEU_USUARIO/auster-agx-mobile -CreateIssues
```

## Demonstracao

1. Abrir app.
2. Login via API REST.
3. Receber JWT.
4. Trocar senha provisória quando `deveAlterarSenha` estiver ativo.
5. Ver dashboard/demandas.
6. Desligar internet.
7. Continuar vendo dados locais.
8. Alterar status, situação dos dados ou situação do mapeamento quando o perfil permitir.
9. Ver alteração pendente consolidada e card local atualizado.
10. Religar internet.
11. Sincronizar com o servidor.
12. Abrir detalhe com resumo, contexto, sensoriamento, cadeia e histórico.
13. Capturar GPS.

## Prints das telas

Capturas reais dos widgets Flutter, renderizadas em viewport mobile de 390 x 844 pontos com dados controlados de demonstração:

<p>
  <img src="docs/screenshots/mobile-login.png" alt="Tela de login do AusterAgX Mobile" width="180">
  <img src="docs/screenshots/mobile-troca-senha.png" alt="Tela de troca obrigatória de senha do AusterAgX Mobile" width="180">
  <img src="docs/screenshots/mobile-dashboard.png" alt="Dashboard mobile com resumo e demandas recentes" width="180">
  <img src="docs/screenshots/mobile-demandas.png" alt="Lista mobile de demandas agrupadas por status" width="180">
  <img src="docs/screenshots/mobile-detalhe-demanda.png" alt="Detalhe mobile da demanda com status e GPS" width="180">
</p>

## Entrega consolidada

- Login, refresh token, logout e troca obrigatória de senha temporária conforme o AUSTER oficial.
- Dashboard mobile com resumo operacional, cards de demandas, grupos de status e métricas de área.
- Lista e detalhe de demandas com cache offline, histórico de status, sensoriamentos, culturas e cadeia origem/derivadas.
- Atualização de status, situação dos dados e situação do mapeamento com as mesmas regras de transição do backend.
- Fila offline persistente, consolidada por demanda, com sincronização automática quando a conexão volta.
- Captura GPS local no detalhe da demanda usando permissões nativas Android.
- README, modelo ER do brModelo, investigação de API, issues versionadas e prints mobile mantidos no próprio repositório.

## Limitações conhecidas

- A localização GPS permanece no banco local porque o AUSTER oficial não possui um endpoint específico para associá-la à demanda. O backend não foi alterado nem recebeu campos inventados.
- A estratégia de conflito offline consolida a última alteração pendente por demanda. Mesclagem distribuída e versionamento de registros exigiriam suporte contratual do servidor.
- A entrega foi validada no Android. Uma publicação iOS ainda exige configuração, assinatura e validação em ambiente Apple.

## Possíveis melhorias

- Sincronizar capturas GPS quando existir um endpoint oficial aprovado para esse contrato.
- Adicionar testes de integração contra um ambiente controlado do backend e uma suíte automatizada em dispositivo físico.
- Criar pipelines de assinatura, distribuição interna e validação também para iOS.
- Avaliar sincronização periódica em segundo plano após definir requisitos de bateria, rede e política operacional.

## Premissas de integridade do AUSTER oficial

- O app mobile consome endpoints REST existentes e não altera tabelas, migrations ou regras do sistema oficial.
- O payload enviado ao backend respeita os DTOs já aceitos por `/auth`, `/dashboard` e `/demandas`.
- Dados locais existem para operação mobile/offline e não substituem a base transacional do AUSTER.
- O build validado é Android, usando Flutter e Android SDK portáteis em `C:\auster-mobile-tools`.
