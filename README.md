<p align="center">
  <img src="assets/branding/auster-logo-bicolor.png" alt="AUSTER Tecnologia" width="420">
</p>

# AusterAgX Mobile — App Android Flutter offline-first

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-validado-3DDC84?logo=android&logoColor=white)
![Riverpod](https://img.shields.io/badge/estado-Riverpod-00ADEF)
![API REST](https://img.shields.io/badge/integra%C3%A7%C3%A3o-API%20REST-0261BD)
![Offline first](https://img.shields.io/badge/opera%C3%A7%C3%A3o-offline--first-00A36C)
[![CI](https://github.com/Joloano/auster-agx-mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/Joloano/auster-agx-mobile/actions/workflows/ci.yml)
![Versão](https://img.shields.io/badge/vers%C3%A3o-0.1.0%2B1-lightgrey)
[![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-blue)](LICENSE)

Aplicativo **Android em Flutter/Dart** para acompanhamento operacional de demandas agrícolas do AusterAgX. Oferece autenticação JWT, dashboard, consulta e atualização autorizada de demandas, cache SQLite isolado por usuário, fila de sincronização e captura local de GPS.

O cliente mobile reutiliza a **API AusterAgX existente**. Autorização, transições de status e validações de negócio continuam no backend oficial; o aplicativo não duplica a base transacional nem cria regras paralelas.

---

## Sumário

- [Preview](#preview)
- [Tecnologias](#tecnologias)
- [Principais funcionalidades](#principais-funcionalidades)
- [Perfis de acesso](#perfis-de-acesso)
- [Arquitetura](#arquitetura)
- [Modelagem do banco de dados](#modelagem-do-banco-de-dados)
- [Pré-requisitos](#pré-requisitos)
- [Como rodar](#como-rodar)
- [Documentação técnica](#documentação-técnica)
- [Testes automatizados](#testes-automatizados)
- [Demonstração acadêmica](#demonstração-acadêmica)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Segurança e integridade](#segurança-e-integridade)
- [Licença e autoria](#licença-e-autoria)

---

## Preview

Capturas reais dos widgets Flutter em viewport mobile de 390 × 844 pontos, usando dados controlados de demonstração.

| Dashboard operacional | Demandas por etapa e status |
|:---:|:---:|
| <img src="docs/screenshots/mobile-dashboard.png" alt="Dashboard operacional do AusterAgX Mobile" width="280"> | <img src="docs/screenshots/mobile-demandas.png" alt="Lista de demandas do AusterAgX Mobile" width="280"> |

<details>
<summary><strong>Ver o fluxo completo de telas</strong></summary>

<p align="center">
  <img src="docs/screenshots/mobile-login.png" alt="Login do AusterAgX Mobile" width="190">
  <img src="docs/screenshots/mobile-troca-senha.png" alt="Troca obrigatória de senha" width="190">
  <img src="docs/screenshots/mobile-detalhe-demanda.png" alt="Detalhe de demanda com status e GPS" width="190">
</p>

</details>

---

## Tecnologias

| Camada | Tecnologias |
|---|---|
| **Mobile** | Flutter / Dart, Material 3, internacionalização nativa do Flutter |
| **Estado e DI** | Riverpod para estado assíncrono, sessão e injeção de dependências |
| **Navegação** | GoRouter com `StatefulShellRoute.indexedStack` |
| **API** | Dio, REST, JWT com access token e refresh token rotativo |
| **Persistência** | SQLite via `sqlite3` e `sqlite3_flutter_libs`, cache por usuário e fila offline |
| **Segurança** | `flutter_secure_storage`, validação de origem da API e assinatura release obrigatória |
| **Conectividade** | `connectivity_plus`, política de falhas transitórias e sincronização automática |
| **Recursos nativos** | `geolocator` e `permission_handler` para captura GPS e permissões Android |
| **Interface** | Identidade AUSTER, logo oficial, Inter e Bebas Neue |
| **Qualidade** | `flutter_test`, Mocktail, Flutter Lints, 47 testes automatizados e CI no GitHub Actions |
| **Modelagem** | brModelo Web, brModelo desktop e Mermaid |
| **Ambiente** | Docker Compose (Postgres/PostGIS, API AusterAgX e massa de teste) e scripts PowerShell |

---

## Principais funcionalidades

1. **Autenticação e sessão**
   - Login por e-mail e senha em `POST /auth/login`.
   - JWT armazenado no cofre seguro do sistema, nunca em preferências simples ou no SQLite.
   - Renovação coordenada de token para impedir múltiplos refreshes concorrentes.
   - Logout com revogação do refresh token no backend.
   - Restauração offline somente depois de uma sessão validada anteriormente.

2. **Troca obrigatória de senha**
   - Bloqueio da navegação operacional quando `deveAlterarSenha = true`.
   - Envio do contrato oficial para `POST /auth/change-password`.
   - Atualização imediata da sessão após a confirmação da nova senha.

3. **Dashboard operacional**
   - Resumo de clientes, fazendas, talhões e vínculos.
   - Métricas de área e cobertura por talhões.
   - Maiores fazendas e demandas recentes.
   - Mesmos agrupamentos operacionais usados pelo painel AusterAgX.

4. **Demandas**
   - Listagem agrupada em `Listada`, `A seguir`, `Coleta de dados`, `Andamento`, `Entregue` e `Cancelada`.
   - Detalhe agregado com pedido, cliente, fazendas, grupos, talhões, culturas e sensoriamentos.
   - Histórico de status, demanda de origem e demandas derivadas.
   - Atualização de status, situação dos dados e situação do mapeamento para perfis autorizados.

5. **Operação offline**
   - Cache local de dashboard, lista, detalhe, histórico e regras de transição.
   - Leitura local quando não há conectividade ou ocorre falha HTTP transitória.
   - Um arquivo SQLite por usuário, identificado por hash, para impedir exposição entre contas.
   - Erros definitivos de autorização ou contrato permanecem visíveis e não são mascarados pelo cache.

6. **Fila de sincronização**
   - Escritas offline otimistas com indicador global de estado.
   - Consolidação da última alteração pendente por demanda.
   - Reconciliação dos caches com a resposta oficial após um `PATCH` aceito.
   - Repetição de falhas transitórias e bloqueio de rejeições permanentes para evitar loops.

7. **Recurso nativo de GPS**
   - Captura de latitude, longitude, precisão e horário no detalhe da demanda.
   - Permissão solicitada em tempo de execução.
   - Registro mantido localmente, pois a API atual não oferece endpoint de demanda para esse payload.

8. **Segurança e mensagens de erro**
   - Diferencia sessão expirada, acesso negado, validação, indisponibilidade, timeout e limite de requisições.
   - Não expõe stack traces ou detalhes internos do servidor ao usuário.
   - HTTP local liberado apenas em debug; release exige HTTPS por padrão.

9. **Identidade visual AUSTER**
   - Logo bicolor oficial, azul `#0261BD` e verde `#00B37B`.
   - Bebas Neue nos títulos e Inter no restante da interface.
   - Launcher Android gerado a partir do símbolo oficial.

---

## Perfis de acesso

| Perfil | Comportamento no aplicativo |
|---|---|
| `SUPER_ADMIN` | Consulta e alteração operacional de demandas |
| `USUARIO_TECNICO_PRESCRICAO` | Consulta e alteração operacional de demandas |
| `USUARIO_CONSULTOR_CTV` | Consulta conforme a carteira autorizada pelo backend |
| `USUARIO_ASSISTENTE_ATV` | Consulta conforme a autorização recebida da API |
| `USUARIO_GESTOR_ADMINISTRATIVO` | Consulta conforme a autorização recebida da API |

Somente `SUPER_ADMIN` e `USUARIO_TECNICO_PRESCRICAO` recebem ações de alteração de status, dados e mapeamento. A API continua sendo a autoridade final: ausência de autenticação resulta em `401` e falta de permissão em `403`.

---

## Arquitetura

A organização separa infraestrutura técnica, contratos de dados, regras de acesso, estado de interface e funcionalidades. O fluxo principal é **tela → provider/controller → repositório → API e SQLite**.

```text
lib/
  app/                         configuração do aplicativo
  routes/                      navegação e proteção de rotas
  core/
    auth/                      eventos e perfis da sessão
    config/                    configuração por dart-define
    errors/                    erros de domínio e mensagens seguras
    network/                   conectividade e política de falhas
  data/
    local/                     SQLite e isolamento por usuário
    models/                    DTOs e modelos imutáveis
    repositorios/              coordenação API/cache
    services/                  clientes REST, tokens, GPS e usuário
    sync/                      fila e serviço de sincronização
  features/
    authentication/            login e troca de senha
    dashboard/                 visão geral operacional
    demandas/                  lista e detalhe
    location/                  captura de localização
    shell/                     navegação principal
  widgets/                     componentes AUSTER compartilhados
```

O shell usa `StatefulShellRoute.indexedStack` para manter pilhas independentes entre Dashboard e Demandas. A barra global de sincronização fica em `lib/widgets/sync_status_bar.dart`.

O aplicativo consome `/demandas/status-fluxo` para obter transições e pré-requisitos. Dessa forma, a ordem do processo não é codificada novamente no cliente.

---

## Modelagem do banco de dados

Modelagem conceitual e lógica na notação do **brModelo**, restrita ao subdomínio que o aplicativo consome pela API AusterAgX. Os diagramas são gerados por [`scripts/gerar-modelos-er.mjs`](scripts/gerar-modelos-er.mjs) a partir do modelo auditado sobre o mapeamento JPA e as migrations Flyway do backend.

### Modelo Conceitual (MER)

Entidades (`USUARIO`, `CLIENTE`, `CLIENTE_FAZENDA`, `FAZENDA`, `TALHAO`, `GRUPO`, `CULTURA`, `PEDIDO`, `DEMANDA`, `DEMANDA_STATUS_HISTORICO`, `SENSORIAMENTO_REMOTO`), atributos principais e cardinalidades (1:N, as N:N `fazenda × cultura`, `grupo × talhão`, `demanda × grupo` e `demanda × sensoriamento`, e os autorrelacionamentos de retrabalho e remapeamento).

![Modelo Conceitual (MER)](docs/modelo-er/auster-agx-mer.png)

### Modelo Lógico (DER)

Esquema relacional com PKs, FKs, as tabelas associativas das relações N:N (`fazenda_cultura`, `grupo_talhao`, `demanda_grupo` e `demanda_sensoriamento_remoto`) e as FKs autorreferentes `demanda_origem_id` e `mapeamento_origem_id`. As colunas `representante_id` e `piloto_id` referenciam `colaborador`, que fica fora deste recorte.

![Modelo Lógico (DER)](docs/modelo-er/auster-agx-der.png)

Modelo completo do domínio (28 entidades e 35 tabelas), matriz de cardinalidades e cache SQLite do aplicativo em [docs/modelo-er/README.md](docs/modelo-er/README.md).

---

## Pré-requisitos

| Requisito | Versão | Observação |
|---|---|---|
| Flutter SDK | 3.38.4 ou superior, canal stable | Desenvolvido e validado na CI com 3.47.4 |
| Dart SDK | 3.11 ou superior | Acompanha o Flutter; exigido pelas dependências do `pubspec.lock` |
| Android SDK | API 21 ou superior | Android Studio ou command-line tools |
| JDK | 17 | Exigido pelo Android Gradle Plugin |
| Node.js | 18 ou superior | Somente para regenerar os modelos ER |
| Docker Desktop | Com Docker Compose v2 | Sobe banco, API e massa de teste localmente |
| Backend AusterAgX | Cópia local de `github.com/AusterTec/AusterAgX` | Exige acesso da AusterTec; o código não é versionado aqui |

---

## Como rodar

> O passo a passo completo para Windows, emulador, celular físico, APK e assinatura está em [INSTALACAO.md](INSTALACAO.md).

### Preparação

```powershell
git clone https://github.com/Joloano/auster-agx-mobile.git
cd auster-agx-mobile
flutter pub get
```

### Ambiente completo com um comando

Com a cópia do backend em `..\AusterAgX-Mobile-Reference\backend` (ou outro caminho em `AUSTERAGX_BACKEND_DIR`, no `.env`):

```powershell
.\scripts\dev\subir-ambiente.ps1                  # banco + API + massa de teste + app no emulador
.\scripts\dev\subir-ambiente.ps1 -Alvo celular    # mesmo ambiente + APK apontando para o IP Wi-Fi
.\scripts\dev\diagnosticar-api.ps1                # confere API, login, massa de teste e dispositivos
```

Para subir só o ambiente, sem o app: `docker compose up -d --build`. A massa de teste do backend é aplicada apenas quando o banco está vazio, e a API fica em `http://localhost:8080`.

| Usuário (senha `123456`) | Perfil | No aplicativo |
|---|---|---|
| `matheus@austertec.com` | `SUPER_ADMIN` | Consulta e altera status, dados e mapeamento |
| `bruno.carvalho@austertec.com` | `USUARIO_TECNICO_PRESCRICAO` | Consulta e altera status, dados e mapeamento |
| `carla.nogueira@austertec.com` | `USUARIO_CONSULTOR_CTV` | Somente consulta |

### App mobile no emulador Android

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Se o Pixel 8 não aceitar digitação, habilite **Enable keyboard input** nas configurações avançadas do AVD e execute:

```powershell
adb shell settings put secure show_ime_with_hard_keyboard 1
adb shell ime set com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME
```

ANRs de `System UI` após um Quick Boot indicam snapshot instável. Use **Cold Boot Now** no Device Manager antes de recriar ou apagar o AVD. O procedimento completo está em [Solução de problemas](INSTALACAO.md#o-teclado-não-responde-no-emulador).

### App mobile em celular físico

```powershell
flutter devices
flutter run -d ID_DO_DISPOSITIVO --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
```

Computador, celular e API devem estar na mesma rede. `10.0.2.2` funciona apenas no emulador Android.

### Configuração da API

| Opção | Descrição |
|---|---|
| `API_BASE_URL` | Origem HTTP(S) do backend; padrão `http://10.0.2.2:8080` |
| `API_TIMEOUT_MS` | Timeout HTTP em milissegundos; padrão `30000` |
| `ALLOW_INSECURE_HTTP` | `true` em debug e `false` em release por padrão |

O valor de `API_BASE_URL` deve ser uma origem sem caminho, query, fragmento ou credenciais. O app não embarca usuários de demonstração: as contas acima vêm da massa de teste do backend. Se a senha for provisória, a troca será exigida automaticamente.

Falhas transitórias em leituras `GET`/`HEAD` recebem uma única nova tentativa automática. Escritas e sincronizações não são repetidas pelo cliente HTTP, evitando operações duplicadas; quando uma leitura ainda falhar, Dashboard, Demandas e Detalhe oferecem **Tentar novamente** sem exigir que o aplicativo seja reiniciado.

### APK de desenvolvimento

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Distribuição

Builds release exigem HTTPS e assinatura privada configurada. Consulte [a seção de assinatura do guia](INSTALACAO.md#configurar-assinatura-de-produção) antes de gerar APK ou Android App Bundle.

---

## Documentação técnica

- **Instalação, emulador, celular e assinatura:** [INSTALACAO.md](INSTALACAO.md)
- **Endpoints, DTOs, autorização e regras do backend:** [docs/investigacao-api.md](docs/investigacao-api.md)
- **Diagrama de classes do domínio:** [docs/diagrama-classes.md](docs/diagrama-classes.md)
- **Modelagem conceitual, lógica e física:** [docs/modelo-er/README.md](docs/modelo-er/README.md)
- **Decisões de segurança da primeira fase:** [docs/fase-1-seguranca.md](docs/fase-1-seguranca.md)
- **Configuração e permissões Android:** [docs/android-config.md](docs/android-config.md)
- **Issues acadêmicas versionadas:** [docs/issues/README.md](docs/issues/README.md)
- **Issues do repositório:** [GitHub Issues](https://github.com/Joloano/auster-agx-mobile/issues)

---

## Testes automatizados

Baseline validada em **23 de setembro de 2026**:

- `flutter analyze --no-pub`: **nenhuma ocorrência**.
- `flutter test --no-pub`: **47 testes aprovados**.

```powershell
flutter analyze
flutter test
```

A suíte cobre configuração segura da API, SQLite, isolamento de usuário, fila offline, tradução de erros, retry seguro de leituras, recuperação visual, refresh JWT, sincronização, repositórios, mapeamento dos DTOs reais e proteção das rotas/widgets de autenticação.

A [CI](.github/workflows/ci.yml) roda em todo push para `main` e em pull requests: `flutter analyze`, `flutter test` e a regeneração dos modelos de dados, que falha se algum artefato de `docs/modelo-er` estiver desatualizado.

---

## Demonstração acadêmica

1. Abrir o aplicativo.
2. Autenticar pela API REST e receber JWT.
3. Trocar a senha quando o backend marcar a credencial como provisória.
4. Consultar dashboard e demandas.
5. Abrir o detalhe agregado de uma demanda.
6. Desligar a internet e continuar consultando os dados locais.
7. Alterar status, dados ou mapeamento com um perfil autorizado.
8. Conferir a operação pendente e o estado otimista no app.
9. Restabelecer a conexão e sincronizar com o servidor.
10. Capturar a localização GPS no detalhe da demanda.

---

## Estrutura do repositório

```text
.github/workflows/    integração contínua: análise, testes e modelos em dia
android/              projeto, permissões, ícones e assinatura Android
assets/               logo oficial e fontes AUSTER
docs/                 contratos, segurança, issues, diagramas e screenshots
docs/modelo-er/       modelos conceitual, lógico e físico e seus artefatos
docs/issues/          issues do MVP versionadas junto do código
lib/                  código Dart do aplicativo
scripts/              gerador dos modelos ER e publicação do repositório
scripts/dev/          subida do ambiente local e diagnóstico da API
test/                 testes unitários e de widgets
.env.example          opções do app e do docker compose
.gitattributes        normalização de quebras de linha e arquivos binários
analysis_options.yaml regras de lint aplicadas ao código Dart
docker-compose.yml    banco, API AusterAgX e massa de teste para desenvolvimento
INSTALACAO.md         guia completo de ambiente e execução
LICENSE               licença MIT do código
NOTICE                o que fica fora da licença: marca, API e fontes
README.md             apresentação e documentação principal
pubspec.yaml          dependências, assets e metadados Flutter
```

O repositório contém um único sistema, o aplicativo, por isso o projeto Flutter fica na raiz, como gera o `flutter create`. O backend não é copiado para cá: o `docker-compose.yml` constrói a API a partir da cópia local do repositório oficial da AusterTec.

---

## Segurança e integridade

- O mobile não altera tabelas, migrations ou regras do AusterAgX oficial.
- DTOs enviados respeitam os contratos aceitos por `/auth`, `/dashboard` e `/demandas`.
- Transições são obtidas de `/demandas/status-fluxo` e novamente validadas pelo servidor.
- Tokens e perfil mínimo ficam no armazenamento seguro do sistema.
- Bancos, filas e capturas GPS são isolados por usuário no dispositivo.
- Segredos de assinatura, bancos locais e arquivos `.env` não entram no Git.
- Builds release falham quando a assinatura privada não está configurada.

---

## Licença e autoria

Projeto acadêmico desenvolvido por **Joloano** ([@Joloano](https://github.com/Joloano)) no Colégio Politécnico da UFSM.

O código deste repositório é distribuído sob a [licença MIT](LICENSE). A licença cobre somente o código e a documentação escritos para o projeto: a marca AUSTER, a identidade visual, os ícones, a API AusterAgX e as fontes sob SIL OFL 1.1 ficam fora dela, como detalha o [NOTICE](NOTICE). Nenhum dado real de cliente é versionado aqui.
