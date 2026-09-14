# Issues do MVP

O `gh` esta instalado, mas nao autenticado nesta maquina. Por isso as issues foram criadas como arquivos locais versionados em `docs/issues`.

Quando houver um repositorio GitHub do app academico e `gh auth login` estiver concluido, criar as issues reais com:

```powershell
cd "C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\auster_agx_mobile"

gh issue create --title "Login REST com JWT" --body-file "docs/issues/001-login-jwt.md"
gh issue create --title "Dashboard e demandas mobile" --body-file "docs/issues/002-dashboard-demandas.md"
gh issue create --title "Offline-first e fila de sincronizacao" --body-file "docs/issues/003-offline-sync.md"
gh issue create --title "Registrar localizacao via GPS" --body-file "docs/issues/004-gps-demanda.md"
```

Nao use o repositorio oficial do AusterAgX como destino dessas issues.
