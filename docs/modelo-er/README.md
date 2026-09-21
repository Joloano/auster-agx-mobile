# Modelagem de dados do AusterAgX Mobile

Este diretório separa três visões que possuem responsabilidades diferentes:

1. **Conceitual:** entidades de negócio, relacionamentos e cardinalidades mínimas e máximas.
2. **Lógica do backend:** tabelas relacionais, PKs, FKs, unicidade e nulabilidade usadas pela API.
3. **Física do mobile:** sete tabelas SQLite usadas como cache offline pelo aplicativo Android.

O backend oficial foi utilizado somente como fonte de verdade. Nenhuma regra de negócio ou estrutura do servidor foi duplicada no aplicativo.

## Diagramas do README

O README apresenta apenas dois diagramas, na notação visual do brModelo, restritos ao subdomínio que o aplicativo consome pela API: 11 entidades, 14 relacionamentos, 15 tabelas e 18 chaves estrangeiras.

| Diagrama | Visualização | Fonte |
|---|---|---|
| Modelo Conceitual (MER), notação de Chen | [PNG](auster-agx-mer.png) ou [SVG](auster-agx-mer.svg) | [`scripts/diagramas-readme.mjs`](../../scripts/diagramas-readme.mjs) |
| Modelo Lógico (DER) | [PNG](auster-agx-der.png) ou [SVG](auster-agx-der.svg) | [`scripts/diagramas-readme.mjs`](../../scripts/diagramas-readme.mjs) |

O conteúdo dos dois diagramas vem do mesmo modelo validado que gera os artefatos completos. A posição de cada entidade é fixa no script; atributos, colunas, chaves e cardinalidades nunca são redigitados. A geração falha se um relacionamento ou FK do recorte ficar sem traçado ou mudar de extremidades.

No MER, os atributos de endereço, geometria e observações estão resumidos; no DER eles aparecem como uma linha em itálico ao final da tabela. As colunas `representante_id` e `piloto_id` referenciam `colaborador`, que fica fora do recorte.

## Artefatos completos

| Visão | Visualização | Fonte editável | Apoio |
|---|---|---|---|
| Conceitual do domínio | [PNG](auster-agx-conceitual.png) ou [SVG](auster-agx-conceitual.svg) | [DOT](auster-agx-conceitual.dot) | [grafo JointJS para o brModelo Web](auster-agx-brmodelo-web.json) |
| Lógica relacional | [PNG](auster-agx-logico.png) ou [SVG](auster-agx-logico.svg) | [DOT](auster-agx-logico.dot) | [matriz auditada](auster-agx-cardinalidades.md) |
| Física do cache Android | [PNG](auster-agx-mobile-fisico.png) ou [ER textual](auster-agx-mobile-fisico.md) | [DDL](auster-agx-mobile-fisico.sql) gerado do código | [brModelo `.brM3`](auster-agx-mobile-fisico.brM3) e [XML](auster-agx-mobile-fisico.xml) |
| Catálogo de entidades | [Mermaid ER](auster-agx-dominio.md) | Markdown | [diagrama de classes](../diagrama-classes.md) |

## Escopo auditado

- 28 entidades persistentes.
- 36 associações JPA.
- 5 relacionamentos adicionais definidos por FK nas migrations.
- 41 relacionamentos conceituais.
- 35 tabelas lógicas, incluindo 7 estruturas associativas ou de coleção.
- 48 referências lógicas por chave estrangeira.
- 7 tabelas no cache SQLite do aplicativo, conferidas contra `lib/data/local/app_database.dart`.

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

## Modelo físico do cache

O DDL em [auster-agx-mobile-fisico.sql](auster-agx-mobile-fisico.sql) e o diagrama em [auster-agx-mobile-fisico.md](auster-agx-mobile-fisico.md) são extraídos de `lib/data/local/app_database.dart` pelo gerador. Nenhum dos dois é escrito à mão, e o gerador interrompe a execução quando o código diverge do modelo do brModelo em tabelas, colunas ou tipos. O PNG e o `.brM3` continuam sendo a vista para entrega acadêmica; o SQL e o Mermaid existem para permitir revisão em diff.

## Regeneração

O gerador valida contagens, identificadores, referências, cardinalidades, nulabilidade e unicidade do backend, confere o cache SQLite contra o código Dart e só então escreve os artefatos:

```powershell
node scripts/gerar-modelos-er.mjs
```

O comando acima recria DOT, SVG, JSON, a matriz de auditoria, o DDL, o ER textual do cache e os SVGs do MER e do DER do README sem dependências externas. A opção `--render` também atualiza os PNGs quando o pacote `sharp` está disponível em `node_modules` ou em `ER_TOOL_NODE_MODULES`:

```powershell
node scripts/gerar-modelos-er.mjs --render
```
