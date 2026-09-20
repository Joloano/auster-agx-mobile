# Instalação do AusterAgX Mobile

Este guia cobre a preparação do aplicativo Flutter, a conexão com a API AusterAgX existente, a execução em emulador ou celular Android e a geração de pacotes de distribuição.

> Este repositório contém somente o cliente mobile. O backend oficial deve estar disponível separadamente; não é necessário copiar regras de negócio nem banco transacional para executar o aplicativo.

## Pré-requisitos

- Git.
- Flutter com Dart compatível com `sdk: >=3.3.0 <4.0.0`.
- Android SDK e um emulador ou dispositivo Android.
- JDK 17 para o build Android.
- Uma instância acessível da API AusterAgX.
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

## Configurar a API

O aplicativo lê a configuração em tempo de compilação por `--dart-define`.

| Variável | Padrão | Finalidade |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:8080` | Origem da API, sem caminho, query ou credenciais |
| `API_TIMEOUT_MS` | `10000` | Timeout HTTP em milissegundos |
| `ALLOW_INSECURE_HTTP` | `true` em debug; `false` em release | Libera HTTP explicitamente para desenvolvimento |

Endereços usuais:

| Ambiente | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8080` |
| Celular físico na mesma rede | `http://IP_DO_COMPUTADOR:8080` |
| Produção | `https://api.exemplo.com` |

O arquivo `.env.example` documenta os valores locais, mas o aplicativo não carrega `.env` em tempo de execução. Passe as opções por `--dart-define`.

## Executar no emulador Android

1. Inicie a API AusterAgX na porta configurada.
2. Abra um emulador Android.
3. Confira o identificador com `flutter devices`.
4. Execute:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` é o endereço do computador host visto pelo emulador Android padrão. `localhost` dentro do emulador aponta para o próprio aparelho virtual.

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

## Gerar e instalar APK de desenvolvimento

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8080
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

O manifesto Android libera tráfego HTTP apenas no build `debug`. Para produção, use HTTPS.

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
```

Quando as dependências já estiverem resolvidas e não for desejado executar `pub get` novamente:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

## Solução de problemas

### Flutter informa que plugins exigem links simbólicos

Habilite o Modo de Desenvolvedor do Windows e execute novamente `flutter pub get`.

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
