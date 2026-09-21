# Issues do MVP

As issues deste projeto são versionadas como arquivos Markdown neste diretório. O histórico fica no próprio repositório, junto do código que as resolve, e não depende de autenticação do `gh` na máquina de desenvolvimento.

| Issue | Tema | Status |
|---|---|---|
| [001](001-login-jwt.md) | Login REST com JWT | Concluída |
| [002](002-dashboard-demandas.md) | Dashboard e demandas mobile | Concluída |
| [003](003-offline-sync.md) | Offline-first e fila de sincronização | Concluída |
| [004](004-gps-demanda.md) | Registrar localização via GPS | Concluída |
| [005](005-revisao-documentacao-modelagem.md) | Revisão da documentação e dos modelos de dados | Concluída |
| [006](006-diagramas-readme-brmodelo.md) | Diagramas conceitual e lógico do README no padrão brModelo | Concluída |
| [007](007-infraestrutura-desenvolvimento.md) | Licença, ambiente com um comando, scripts versionados e CI | Concluída |
| [008](008-ci-node24-ubuntu-fixo.md) | CI em Node.js 24 e com imagem do Ubuntu fixa | Em andamento |

## Publicar no GitHub Issues

Com o `gh` instalado e autenticado (`gh auth login`), as mesmas issues podem ser espelhadas no repositório acadêmico:

```powershell
cd "C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\auster_agx_mobile"

gh issue create --repo Joloano/auster-agx-mobile --title "Login REST com JWT" --body-file "docs/issues/001-login-jwt.md"
gh issue create --repo Joloano/auster-agx-mobile --title "Dashboard e demandas mobile" --body-file "docs/issues/002-dashboard-demandas.md"
gh issue create --repo Joloano/auster-agx-mobile --title "Offline-first e fila de sincronização" --body-file "docs/issues/003-offline-sync.md"
gh issue create --repo Joloano/auster-agx-mobile --title "Registrar localização via GPS" --body-file "docs/issues/004-gps-demanda.md"
gh issue create --repo Joloano/auster-agx-mobile --title "Revisão da documentação e dos modelos de dados" --body-file "docs/issues/005-revisao-documentacao-modelagem.md"
gh issue create --repo Joloano/auster-agx-mobile --title "Diagramas conceitual e lógico do README no padrão brModelo" --body-file "docs/issues/006-diagramas-readme-brmodelo.md"
gh issue create --repo Joloano/auster-agx-mobile --title "Licença, ambiente com um comando, scripts versionados e CI" --body-file "docs/issues/007-infraestrutura-desenvolvimento.md"
gh issue create --repo Joloano/auster-agx-mobile --title "CI em Node.js 24 e com imagem do Ubuntu fixa" --body-file "docs/issues/008-ci-node24-ubuntu-fixo.md"
```

O destino é sempre `Joloano/auster-agx-mobile`. O repositório oficial do AusterAgX nunca é usado como destino dessas issues.

## Convenção de novas issues

- Arquivo `NNN-slug-curto.md`, numeração sequencial.
- Seções `Objetivo`, `Critérios de aceite` e, quando houver, `Decisão` ou `Fora do escopo`.
- Uma linha `Status` ao final, atualizada quando a issue é concluída.
- A tabela acima é atualizada no mesmo commit que cria a issue.
