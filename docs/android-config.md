# Configuracao Android

Quando o Flutter CLI estiver funcionando, gere as pastas nativas dentro do projeto academico:

```powershell
cd "C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\auster_agx_mobile"
flutter create .
```

Depois confirme que `android/app/src/main/AndroidManifest.xml` contem permissoes de localizacao:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Essas permissoes sao necessarias para `geolocator` e `permission_handler`.

Para Android Emulator, rode apontando para a API local do host:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para celular fisico, substitua por `http://IP_DA_MAQUINA:8080`.
