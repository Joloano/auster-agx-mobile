# Configuração Android

As pastas Android e iOS foram geradas com o template oficial do Flutter. O guia completo de ambiente, emulador, celular físico e assinatura está em [`INSTALACAO.md`](../INSTALACAO.md).

Para preparar o projeto:

```powershell
git clone https://github.com/Joloano/auster-agx-mobile.git
cd auster-agx-mobile
flutter pub get
```

`android/app/src/main/AndroidManifest.xml` contém permissões de internet, estado de rede e localização:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Essas permissões são necessárias para `geolocator` e `permission_handler`.

## Tráfego HTTP de desenvolvimento

O manifesto principal não libera tráfego HTTP. A permissão `android:usesCleartextTraffic="true"` existe somente em `android/app/src/debug/AndroidManifest.xml`, portanto APIs locais em HTTP funcionam apenas no build `debug`.

Para Android Emulator, rode apontando para a API local do host:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para celular físico, substitua por `http://IP_DA_MAQUINA:8080`.

## Builds

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build apk --release --dart-define=API_BASE_URL=https://api.exemplo.com
```

O build release exige HTTPS por padrão e uma assinatura privada configurada em `android/key.properties`. Consulte o guia de instalação antes de distribuir o pacote.

Artefatos gerados:

- `build\app\outputs\flutter-apk\app-debug.apk`
- `build\app\outputs\flutter-apk\app-release.apk`
