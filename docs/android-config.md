# Configuracao Android

As pastas Android/iOS ja foram geradas no projeto academico com o template oficial do Flutter. O Flutter e o Android SDK portateis estao em:

- `C:\auster-mobile-tools\flutter`
- `C:\auster-mobile-tools\android-sdk`

Para usar o projeto:

```powershell
cd C:\auster-mobile-work\auster_agx_mobile
C:\auster-mobile-tools\flutter\bin\flutter.bat pub get
```

`android/app/src/main/AndroidManifest.xml` contem permissoes de internet, estado de rede e localizacao:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Essas permissoes sao necessarias para `geolocator` e `permission_handler`.

Para Android Emulator, rode apontando para a API local do host:

```powershell
C:\auster-mobile-tools\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para celular fisico, substitua por `http://IP_DA_MAQUINA:8080`.

Builds verificados:

```powershell
C:\auster-mobile-tools\flutter\bin\flutter.bat build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
C:\auster-mobile-tools\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Artefatos gerados:

- `build\app\outputs\flutter-apk\app-debug.apk`
- `build\app\outputs\flutter-apk\app-release.apk`
