# Modelagem de dados do AusterAgX Mobile

Este diretório separa três visões que possuem responsabilidades diferentes:

1. **Conceitual:** entidades de negócio, relacionamentos e cardinalidades mínimas e máximas.
2. **Lógica do backend:** tabelas relacionais, PKs, FKs, unicidade e nulabilidade usadas pela API.
3. **Física do mobile:** sete tabelas SQLite usadas como cache offline pelo aplicativo Android.

O backend oficial foi utilizado somente como fonte de verdade. Nenhuma regra de negócio ou estrutura do servidor foi duplicada no aplicativo.

## Artefatos principais

| Visão | Visualização | Fonte editável | Apoio |
|---|---|---|---|
| Conceitual do domínio | [PNG](auster-agx-conceitual.png) ou [SVG](auster-agx-conceitual.svg) | [DOT](auster-agx-conceitual.dot) | [grafo JointJS para o brModelo Web](auster-agx-brmodelo-web.json) |
| Lógica relacional | [PNG](auster-agx-logico.png) ou [SVG](auster-agx-logico.svg) | [DOT](auster-agx-logico.dot) | [matriz auditada](auster-agx-cardinalidades.md) |
| Física do cache Android | [PNG](auster-agx-mobile-fisico.png) | [brModelo `.brM3`](auster-agx-mobile-fisico.brM3) | [XML](auster-agx-mobile-fisico.xml) |
| Catálogo de entidades | [Mermaid ER](auster-agx-dominio.md) | Markdown | [diagrama de classes](../diagrama-classes.md) |

## Escopo auditado

- 28 entidades persistentes.
- 36 associações JPA.
- 5 relacionamentos adicionais definidos por FK nas migrations.
- 41 relacionamentos conceituais.
- 35 tabelas lógicas, incluindo 7 estruturas associativas ou de coleção.
- 48 referências lógicas por chave estrangeira.

As entidades de referência podem aparecer em mais de um painel visual para evitar linhas atravessando módulos. Isso não cria entidades duplicadas no modelo semântico.

## Convenções de modelagem

- `(0,1)` representa participação opcional e unitária.
- `(1,1)` representa participação obrigatória e unitária.
- `(0,N)` representa participação opcional e múltipla.
- Linha contínua no conceitual representa associação JPA.
- Linha tracejada no conceitual representa FK existente na migration sem associação de objeto equivalente.
- Linha tracejada no lógico identifica uma FK anulável.
- `PK`, `FK`, `UK` e `NN` significam chave primária, chave estrangeira, unicidade e `NOT NULL`.

Cardinalidades obrigatórias são determinadas por `NOT NULL`; relacionamentos um para um dependem também de `UNIQUE`. A modelagem não presume restrições que não existem no schema.

## Regeneração

O gerador valida contagens, identificadores, referências, cardinalidades, nulabilidade e unicidade antes de escrever os artefatos:

```powershell
node scripts/gerar-modelos-er.mjs
```

O comando acima recria DOT, SVG, JSON e a matriz de auditoria sem dependências externas. A opção `--render` também atualiza os PNGs quando o pacote `sharp` está disponível em `node_modules` ou em `ER_TOOL_NODE_MODULES`:

```powershell
node scripts/gerar-modelos-er.mjs --render
```
