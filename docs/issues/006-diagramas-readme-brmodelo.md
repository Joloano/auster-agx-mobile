# Issue 006 — Diagramas conceitual e lógico do README no padrão brModelo

## Objetivo

Apresentar a modelagem de dados no README com apenas dois diagramas, o Modelo Conceitual (MER) e o Modelo Lógico (DER), na notação visual do brModelo usada nos demais projetos acadêmicos.

## Motivação

A seção atual exibe três modelos (conceitual do domínio inteiro, lógico com 35 tabelas e físico do cache SQLite) em grafos densos gerados por Graphviz. O resultado é difícil de ler no GitHub e não segue a notação cobrada na disciplina: entidades com atributos em pirulito, relacionamentos em losango e tabelas relacionais com ícones de chave.

## Escopo

O recorte é o subdomínio que o aplicativo mobile consome pela API: `USUARIO`, `CLIENTE`, `CLIENTE_FAZENDA`, `FAZENDA`, `TALHAO`, `GRUPO`, `CULTURA`, `PEDIDO`, `DEMANDA`, `DEMANDA_STATUS_HISTORICO` e `SENSORIAMENTO_REMOTO`.

## Critérios de aceite

- MER na notação de Chen do brModelo: atributos em pirulito, identificador preenchido, relacionamentos em losango e cardinalidades mínimas e máximas.
- DER no estilo do modelo lógico do brModelo: PK, FK e tabelas associativas das relações N:N.
- Entidades, atributos, relacionamentos e cardinalidades derivados do modelo já validado em `scripts/gerar-modelos-er.mjs`, sem redigitação manual.
- Diagramas versionados em SVG e PNG e regenerados pelo mesmo comando dos demais artefatos.
- README exibe somente os dois diagramas e aponta para a documentação completa em `docs/modelo-er/`.
- Os modelos completos (28 entidades, 35 tabelas e cache SQLite) continuam disponíveis em `docs/modelo-er/`.

## Fora do escopo

- Alterar schema, migrations ou código Dart.

## Status

Concluída em 21 de setembro de 2026.
