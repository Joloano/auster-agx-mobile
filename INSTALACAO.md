# Instalação do AusterAgX Mobile

Este guia cobre a preparação do aplicativo Flutter, a conexão com a API AusterAgX existente, a execução em emulador ou celular Android e a geração de pacotes de distribuição.

> Este repositório contém somente o cliente mobile. O backend AusterAgX mora no repositório oficial da AusterTec; o `docker-compose.yml` daqui apenas o constrói a partir de uma cópia local.

## Pré-requisitos

- Git.
- Flutter 3.38.4 ou superior (desenvolvido e validado na CI com 3.47.4), que traz o Dart 3.11+ exigido pelo `pubspec.lock`.
- Android SDK e um emulador ou dispositivo Android.
- JDK 17 para o build Android.
- Docker Desktop, para subir banco, API e massa de teste localmente.
- Cópia local do repositório `github.com/AusterTec/AusterAgX` (exige acesso da AusterTec) ou outra instância acessível da API.
- Projeto em um caminho sem acentos e fora de pastas sincronizadas, por exemplo `C:\dev\auster-agx-mobile`. Veja a [solução de problemas](#o-build-android-recusa-o-caminho-do-projeto).
- No Windows, Modo de Desenvolvedor habilitado para a criação dos links simbólicos usados pelos plugins Flutter.

Verifique o ambiente:

```powershell
flutter doctor -v
flutter devices
```

No Windows, o Modo de Desenvolvedor pode ser aberto em **Configurações > Sistema > Para desenvolvedores**. Sem suporte a links simbólicos, `flutter pub get`, builds e alguns comandos de análise podem falhar ao preparar plugins.

## Obter o projeto

```powershell
git clone https://github.com/Joloano/auster-agx-mobile.git
cd auster-agx-mobile
flutter pub get
```

## Subir o ambiente local

O `docker-compose.yml` sobe três serviços:

| Serviço | O que faz |
|---|---|
| `db` | Postgres 16 com PostGIS, publicado na porta `5440` para não conflitar com o compose do próprio backend |
| `api` | API AusterAgX construída a partir de `AUSTERAGX_BACKEND_DIR`, em `http://localhost:8080` |
| `seed` | Aplica o `init.sql` do backend somente quando o banco ainda não tem demandas |

Por padrão o backend é procurado em `..\AusterAgX-Mobile-Reference\backend`. Para outro caminho, copie o `.env.example` para `.env` e descomente `AUSTERAGX_BACKEND_DIR`.

O jeito mais curto é o script, que sobe o ambiente, espera a API e a massa de teste e executa o app:

```powershell
.\scripts\dev\subir-ambiente.ps1                  # emulador
.\scripts\dev\subir-ambiente.ps1 -Alvo celular    # APK apontando para o IP Wi-Fi
```

Se o PowerShell bloquear scripts, rode uma vez `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

Para controlar só o ambiente:

```powershell
docker compose up -d --build     # sobe banco, API e massa de teste
docker compose logs -f api       # acompanha a API
docker compose down              # para, preservando os dados
docker compose down -v           # apaga o banco; a massa de teste volta na próxima subida
```

O primeiro `--build` compila o backend com Maven e leva alguns minutos. A partir do segundo, use `-SemBuild` no script quando o backend não mudou.

Contas da massa de teste, todas com a senha `123456`:

| Usuário | Perfil |
|---|---|
| `matheus@austertec.com` | `SUPER_ADMIN` |
| `bruno.carvalho@austertec.com` | `USUARIO_TECNICO_PRESCRICAO` |
| `carla.nogueira@austertec.com` | `USUARIO_CONSULTOR_CTV` (somente consulta) |
| `ana.ferreira@austertec.com` | `USUARIO_GESTOR_ADMINISTRATIVO` |
| `diego.ramos@austertec.com` | `USUARIO_ASSISTENTE_ATV` |

Para testar a troca obrigatória de senha:

```powershell
docker compose exec db psql -U auster -d auster_agx -c "UPDATE usuario SET deve_alterar_senha = true WHERE email = 'diego.ramos@austertec.com';"
```

Quando algo não conectar, `.\scripts\dev\diagnosticar-api.ps1` confere API, login, massa de teste e dispositivos e diz em qual etapa está o problema.

## Configurar a API

O aplicativo lê a configuração em tempo de compilação por `--dart-define`.

| Variável | Padrão | Finalidade |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:8080` | Origem da API, sem caminho, query ou credenciais |
| `API_TIMEOUT_MS` | `30000` | Timeout HTTP em milissegundos |
| `ALLOW_INSECURE_HTTP` | `true` em debug; `false` em release | Libera HTTP explicitamente para desenvolvimento |

Endereços usuais:

| Ambiente | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8080` |
| Celular físico na mesma rede | `http://IP_DO_COMPUTADOR:8080` |
| Produção | `https://api.exemplo.com` |

O arquivo `.env.example` documenta os valores locais, mas o aplicativo não carrega `.env` em tempo de execução. Passe as opções por `--dart-define`.

O cliente repete uma única vez apenas leituras `GET`/`HEAD` que falhem por timeout, conexão ou indisponibilidade transitória. Requisições de escrita não são repetidas automaticamente. Se as duas tentativas de leitura falharem, use **Tentar novamente** na própria tela depois de restabelecer a API.

## Executar no emulador Android

Se `flutter emulators` não listar nenhum emulador, instale o pacote do emulador e uma imagem de sistema, e crie o AVD usado pelo script:

```powershell
$sdkbin = "$env:ANDROID_HOME\cmdline-tools\latest\bin"
& "$sdkbin\sdkmanager.bat" --licenses
& "$sdkbin\sdkmanager.bat" "emulator" "system-images;android-35;google_apis;x86_64"
& "$sdkbin\avdmanager.bat" create avd -n auster_test -k "system-images;android-35;google_apis;x86_64" -d pixel_7
emulator -accel-check
```

O `avdmanager` cria o AVD com `hw.keyboard=no` no `config.ini`. Com isso, o Android nem registra um teclado físico e o teclado do computador não digita nos campos do app. O `scripts/dev/subir-ambiente.ps1` corrige o arquivo e reinicia o emulador a frio quando precisa. Para corrigir à mão:

```powershell
$config = "$env:USERPROFILE\.android\avd\auster_test.avd\config.ini"
(Get-Content $config) -replace '^hw\.keyboard\s*=.*', 'hw.keyboard=yes' | Set-Content $config
emulator -avd auster_test -no-snapshot-load
```

Para conferir, `adb shell dumpsys input` deve listar um teclado físico, como `AT Translated Set 2 keyboard`.

Depois:

1. Inicie o ambiente local ou outra instância da API.
2. Abra o emulador com `flutter emulators --launch auster_test`.
3. Confira o identificador com `flutter devices`.
4. Execute:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` é o endereço do computador host visto pelo emulador Android padrão. `localhost` dentro do emulador aponta para o próprio aparelho virtual.

Prefira `10.0.2.2` a `adb reverse tcp:8080 tcp:8080`: o redirecionamento do adb atende bem uma requisição por vez, mas engasga quando o dashboard dispara várias em paralelo, e o app acusa timeout mesmo com a API respondendo rápido.

## Executar em celular Android

1. Ative **Opções do desenvolvedor** e **Depuração USB** no aparelho.
2. Conecte o celular por USB e autorize o computador.
3. Mantenha computador e celular na mesma rede Wi-Fi.
4. Localize o IPv4 do computador com `ipconfig`.
5. Garanta que a API aceite conexões da rede e que o firewall permita a porta usada.
6. Confirme o dispositivo:

```powershell
adb devices
flutter devices
```

7. Execute substituindo os valores:

```powershell
flutter run -d ID_DO_DISPOSITIVO --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
```

O endereço `10.0.2.2` funciona somente no emulador. Em celular físico, use um IP alcançável pelo aparelho.

### Liberar a API para a rede Wi-Fi

O celular acessa a API pelo IP do computador na rede local, então o Windows precisa aceitar conexões na porta `8080`. Em um PowerShell **como administrador**:

```powershell
Set-NetConnectionProfile -InterfaceAlias "Wi-Fi" -NetworkCategory Private
New-NetFirewallRule -DisplayName "AusterAgX API 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Private
```

Marque como privada apenas a rede de casa. Confira no navegador do celular: `http://IP_DO_COMPUTADOR:8080/actuator/health` deve mostrar `"status":"UP"`. Redes institucionais costumam isolar os aparelhos entre si; nesse caso, use o roteador do próprio celular.

## Gerar e instalar APK de desenvolvimento

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

O manifesto Android libera tráfego HTTP apenas no build `debug`. Para produção, use HTTPS.

Sem cabo ou sem depuração USB, gere só para arm64 (o APK cai para menos da metade do tamanho) e envie o arquivo para o celular por Drive, WhatsApp ou e-mail:

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
```

O endereço da API fica gravado no APK: se o IP do computador mudar, gere o APK de novo. O `subir-ambiente.ps1 -Alvo celular` faz esse build com o IP atual do Wi-Fi.

## Configurar assinatura de produção

O build `release` não reutiliza a chave de debug. Gere uma chave privada e mantenha-a fora do Git:

```powershell
New-Item -ItemType Directory -Force android\keystore
keytool -genkeypair -v -keystore android\keystore\auster-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android\key.properties.example android\key.properties
```

Preencha `android/key.properties`:

```properties
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_CHAVE
keyAlias=upload
storeFile=../keystore/auster-upload-key.jks
```

`android/key.properties` e arquivos `*.jks` são ignorados pelo Git. Guarde um backup seguro da chave: futuras atualizações do aplicativo dependem dela.

Gere os pacotes usando uma API HTTPS:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.exemplo.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.exemplo.com
```

Sem todas as propriedades ou sem o arquivo de chave, o build falha explicitamente e não produz um pacote release assinado como desenvolvimento.

## Validar o projeto

```powershell
flutter analyze
flutter test
node scripts/gerar-modelos-er.mjs
git status --short docs/modelo-er
```

A última linha deve sair vazia: é a mesma verificação que a CI faz em cada push.

Quando as dependências já estiverem resolvidas e não for desejado executar `pub get` novamente:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

## Solução de problemas

### Flutter informa que plugins exigem links simbólicos

Habilite o Modo de Desenvolvedor do Windows e execute novamente `flutter pub get`.

### O build Android recusa o caminho do projeto

`Your project path contains non-ASCII characters` aparece quando o projeto está em uma pasta com acento, como `Área de Trabalho`. A solução definitiva é mover o projeto para um caminho só com ASCII e fora do OneDrive, por exemplo `C:\dev\auster-agx-mobile`. Como paliativo, desative a verificação só na sua máquina, sem alterar o repositório:

```powershell
Add-Content "$env:USERPROFILE\.gradle\gradle.properties" "`nandroid.overridePathCheck=true"
```

### O teclado não responde no emulador

1. No Device Manager do Android Studio, abra **Edit** no AVD, acesse **Show Advanced Settings** e mantenha **Enable keyboard input** habilitado.
2. Permita que o teclado virtual apareça mesmo quando o emulador detectar o teclado físico e selecione o Gboard:

```powershell
adb shell settings put secure show_ime_with_hard_keyboard 1
adb shell ime set com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME
```

3. Se aparecer `Process system isn't responding` ou `System UI isn't responding`, escolha **Wait**. Se o aviso retornar, execute **Cold Boot Now** no menu do AVD. Isso descarta somente o snapshot rápido e preserva aplicativos e dados.

Também é possível fazer o cold boot pelo terminal, substituindo o nome do AVD:

```powershell
emulator -avd NOME_DO_AVD -no-snapshot-load
```

Evite **Wipe Data** como primeira tentativa, pois ele apaga o estado do aparelho virtual e normalmente não é necessário para recuperar o teclado.

### O app acusa timeout no emulador, mas a API responde rápido

Remova redirecionamentos antigos com `adb reverse --remove-all` e rode o app com `API_BASE_URL=http://10.0.2.2:8080`. Aguarde a API terminar de iniciar e toque em **Tentar novamente**; não é necessário reiniciar o aplicativo. Se persistir, execute `.\scripts\dev\diagnosticar-api.ps1` para separar falha de rota, autenticação ou massa de teste.

### O `flutter run` perde a conexão logo após instalar

Mensagens como `Error connecting to the service protocol` ou `Lost connection to device` indicam o servidor do adb em estado ruim. Reinicie-o e rode de novo:

```powershell
adb kill-server
adb start-server
adb devices
```

### O `adb devices` não lista o celular

Confira, nesta ordem: **Depuração USB** ligada nas Opções do desenvolvedor, cabo em modo **Transferência de arquivos**, aviso "Permitir depuração USB?" aceito no celular, e um cabo que transmita dados. Se ainda assim não aparecer, instale o APK sem adb, como descrito acima.

### A API falha com `Migration checksum mismatch`

O volume do Postgres foi migrado com uma versão antiga de alguma migration. Em banco de desenvolvimento, recrie o volume: `docker compose down -v` e suba de novo. A massa de teste é reaplicada automaticamente.

### O backend rodado fora do Docker falha com `cannot find symbol`

`mvnw spring-boot:run -pl auster-erp` compila só o `auster-erp` e usa versões antigas de `auster-auth` e `auster-core` do `~/.m2`. Rode `.\mvnw.cmd install -DskipTests` na raiz do backend antes, ou use o `docker compose`, que compila os três módulos.

### O celular não alcança a API

- Confirme que celular e computador estão na mesma rede.
- Use o IPv4 do computador, não `localhost` nem `10.0.2.2`.
- Verifique se a API escuta em uma interface acessível pela rede.
- Libere a porta no firewall apenas para a rede necessária.
- Teste o endereço no navegador do celular.

### O login funciona no emulador, mas não no APK release

Builds release bloqueiam HTTP por padrão. Configure uma origem HTTPS válida. `API_BASE_URL` deve conter somente esquema, host e porta opcional.

### O build release pede configuração de assinatura

Copie `android/key.properties.example`, preencha as quatro propriedades obrigatórias e confirme se `storeFile` aponta para o arquivo `.jks` existente.

## Integridade do sistema oficial

- O mobile consome os contratos REST já existentes.
- Autorização, transições e validações de negócio permanecem no backend AusterAgX.
- SQLite local é cache operacional e fila offline, não uma réplica da base transacional.
- GPS permanece local porque não existe endpoint oficial de demanda para esse payload.
