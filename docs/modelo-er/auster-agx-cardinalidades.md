# Auditoria de cardinalidades do AusterAgX

Este documento registra a revisão do modelo de dados usado como referência pelo aplicativo mobile. A fonte de verdade foi o mapeamento JPA do backend oficial, complementado pelas migrations Flyway para nulabilidade, unicidade, chaves estrangeiras e tabelas associativas. O backend não foi modificado.

## Escopo validado

- **28 entidades persistentes** do domínio.
- **36 associações JPA** entre entidades.
- **5 relacionamentos físicos adicionais** com `usuario`, declarados por FK nas migrations e representados no conceitual com linha tracejada.
- **41 relacionamentos conceituais** no total.
- **35 tabelas lógicas**, sendo 28 entidades e 7 estruturas associativas ou de coleção.
- **48 referências lógicas** por chave estrangeira.

## Notação

| Símbolo | Significado |
|---|---|
| `(0,1)` | participação opcional, no máximo uma ocorrência |
| `(1,1)` | participação obrigatória, exatamente uma ocorrência |
| `(0,N)` | participação opcional, várias ocorrências |

A cardinalidade exibida junto a uma entidade indica quantas ocorrências daquela entidade podem participar para uma ocorrência do lado oposto. Exemplo: `DEMANDA (0,N) — (1,1) PEDIDO` significa que um pedido pode possuir zero ou muitas demandas, enquanto cada demanda pertence obrigatoriamente a um único pedido.

## Matriz conceitual auditada

| # | Entidade A | Card. A | Relacionamento | Entidade B | Card. B | Implementação | Fonte |
|---:|---|:---:|---|---|:---:|---|---|
| 01 | `CLIENTE` | **(0,N)** | ADMINISTRADO POR | `USUARIO` | **(1,1)** | cliente.usuario_id NOT NULL | JPA |
| 02 | `CLIENTE_FAZENDA` | **(0,N)** | VINCULA CLIENTE | `CLIENTE` | **(1,1)** | cliente_fazenda.cliente_id NOT NULL | JPA |
| 03 | `CLIENTE_FAZENDA` | **(0,N)** | VINCULA FAZENDA | `FAZENDA` | **(1,1)** | cliente_fazenda.fazenda_id NOT NULL | JPA |
| 04 | `COLABORADOR` | **(0,N)** | ATUA PARA | `CLIENTE` | **(0,1)** | colaborador.cliente_id NULL | JPA |
| 05 | `COLABORADOR` | **(0,N)** | ATUA EM | `FAZENDA` | **(0,N)** | tabela colaborador_fazenda | JPA |
| 06 | `COLABORADOR` | **(0,N)** | VINCULA CONTA | `USUARIO` | **(0,1)** | colaborador.usuario_id NULL | JPA |
| 07 | `FAZENDA` | **(0,N)** | PERTENCE A CLIENTE | `CLIENTE` | **(0,1)** | fazenda.cliente_proprietario_id NULL | JPA |
| 08 | `FEEDBACK` | **(0,N)** | CRIADO POR | `USUARIO` | **(1,1)** | feedback.usuario_id NOT NULL | JPA |
| 09 | `TALHAO` | **(0,N)** | PERTENCE A FAZENDA | `FAZENDA` | **(1,1)** | talhao.fazenda_id NOT NULL | JPA |
| 10 | `GRUPO` | **(0,N)** | AGRUPA TALHAO | `TALHAO` | **(0,N)** | tabela grupo_talhao | JPA |
| 11 | `CULTIVO` | **(0,N)** | OCORRE NO TALHAO | `TALHAO` | **(1,1)** | cultivo.talhao_id NOT NULL | JPA |
| 12 | `CULTIVO` | **(0,1)** | UTILIZA CULTURA | `CULTURA` | **(1,1)** | cultivo.cultura_id NOT NULL UNIQUE | JPA |
| 13 | `CULTURA_ANTECESSORA` | **(0,N)** | OCORREU NO TALHAO | `TALHAO` | **(1,1)** | cultura_antecessora.talhao_id NOT NULL | JPA |
| 14 | `CULTURA_ANTECESSORA` | **(0,N)** | REFERENCIA CULTURA | `CULTURA` | **(1,1)** | cultura_antecessora.cultura_id NOT NULL | JPA |
| 15 | `DADOS_SOLO` | **(0,N)** | DESCREVE SOLO | `TALHAO` | **(1,1)** | dados_solo.talhao_id NOT NULL | JPA |
| 16 | `ESTADIO_FENOLOGICO` | **(0,N)** | PERTENCE A CULTURA | `CULTURA` | **(0,1)** | estadio_fenologico.cultura_id NULL | JPA |
| 17 | `FAZENDA` | **(0,N)** | PRODUZ CULTURA | `CULTURA` | **(0,N)** | tabela fazenda_cultura | JPA |
| 18 | `FAZENDA` | **(0,N)** | UTILIZA EQUIPAMENTO | `EQUIPAMENTO` | **(0,N)** | tabela fazenda_equipamento | JPA |
| 19 | `PEDIDO` | **(0,N)** | SOLICITADO POR | `CLIENTE` | **(1,1)** | pedido.cliente_id NOT NULL | JPA |
| 20 | `DEMANDA` | **(0,N)** | PERTENCE A PEDIDO | `PEDIDO` | **(1,1)** | demanda.pedido_id NOT NULL | JPA |
| 21 | `DEMANDA` | **(0,N)** | ORIGINA RETRABALHO | `DEMANDA` | **(0,1)** | demanda.demanda_origem_id NULL | JPA |
| 22 | `DEMANDA` | **(0,N)** | REPRESENTADA POR | `COLABORADOR` | **(0,1)** | demanda.representante_id NULL | JPA |
| 23 | `DEMANDA` | **(0,N)** | ABRANGE GRUPO | `GRUPO` | **(0,N)** | tabela demanda_grupo | JPA |
| 24 | `DEMANDA` | **(0,N)** | UTILIZA MAPEAMENTO | `SENSORIAMENTO_REMOTO` | **(0,N)** | tabela demanda_sensoriamento_remoto | JPA |
| 25 | `DEMANDA_STATUS_HISTORICO` | **(0,N)** | REGISTRA STATUS | `DEMANDA` | **(1,1)** | demanda_status_historico.demanda_id NOT NULL | JPA |
| 26 | `SENSORIAMENTO_REMOTO` | **(0,N)** | RESPONSAVEL POR | `COLABORADOR` | **(0,1)** | sensoriamento_remoto.piloto_id NULL | JPA |
| 27 | `SENSORIAMENTO_REMOTO` | **(0,N)** | DERIVA DE | `SENSORIAMENTO_REMOTO` | **(0,1)** | sensoriamento_remoto.mapeamento_origem_id NULL | JPA |
| 28 | `ADUBACAO` | **(0,N)** | DETALHA DEMANDA | `DEMANDA` | **(1,1)** | adubacao.demanda_id NOT NULL | JPA |
| 29 | `ADUBACAO` | **(0,N)** | APLICA NO ESTADIO | `ESTADIO_FENOLOGICO` | **(0,1)** | adubacao.estadio_fenologico_id NULL | JPA |
| 30 | `MANEJO_NITROGENIO` | **(0,1)** | CONFIGURA MANEJO | `DEMANDA` | **(1,1)** | manejo_nitrogenio.demanda_id NOT NULL UNIQUE | JPA |
| 31 | `MANEJO_NITROGENIO` | **(0,N)** | USA EQUIPAMENTO | `EQUIPAMENTO` | **(0,1)** | manejo_nitrogenio.equipamento_aplicacao_id NULL | JPA |
| 32 | `PRESCRICAO_SMART_BRAKE` | **(0,1)** | CONFIGURA PRESCRICAO | `DEMANDA` | **(1,1)** | prescricao_smart_brake.demanda_id NOT NULL UNIQUE | JPA |
| 33 | `PRESCRICAO_SMART_BRAKE` | **(0,N)** | APLICA NO ESTADIO | `ESTADIO_FENOLOGICO` | **(0,1)** | prescricao_smart_brake.estadio_fenologico_id NULL | JPA |
| 34 | `PRESCRICAO_SMART_BRAKE` | **(0,N)** | USA EQUIPAMENTO | `EQUIPAMENTO` | **(0,1)** | prescricao_smart_brake.equipamento_aplicacao_id NULL | JPA |
| 35 | `PRESCRICAO_SMART_SEEDING` | **(0,1)** | CONFIGURA SEMEADURA | `DEMANDA` | **(1,1)** | prescricao_smart_seeding.demanda_id NOT NULL UNIQUE | JPA |
| 36 | `PRESCRICAO_SMART_SEEDING` | **(0,N)** | USA SEMEADORA | `EQUIPAMENTO` | **(0,1)** | prescricao_smart_seeding.modelo_semeadora_id NULL | JPA |
| 37 | `ARQUIVO_UPLOAD` | **(0,N)** | ENVIA ARQUIVO | `USUARIO` | **(1,1)** | arquivo_upload.usuario_id NOT NULL | Flyway |
| 38 | `AUDIT_LOG` | **(0,N)** | REGISTRA AUDITORIA | `USUARIO` | **(0,1)** | audit_log.usuario_id NULL | Flyway |
| 39 | `GOOGLE_DRIVE_CREDENTIAL` | **(0,1)** | POSSUI CREDENCIAL | `USUARIO` | **(1,1)** | google_drive_credential.usuario_id PK/FK | Flyway |
| 40 | `PASSWORD_RESET_TOKEN` | **(0,N)** | SOLICITA REDEFINICAO | `USUARIO` | **(1,1)** | password_reset_token.usuario_id NOT NULL | Flyway |
| 41 | `REFRESH_TOKEN` | **(0,N)** | MANTEM SESSAO | `USUARIO` | **(1,1)** | refresh_token.usuario_id NOT NULL | Flyway |

## Tabelas associativas

| Tabela | Colunas de vínculo | Chave primária física |
|---|---|---|
| `colaborador_fazenda` | `colaborador_id`, `fazenda_id` | `colaborador_id` + `fazenda_id` |
| `grupo_talhao` | `grupo_id`, `talhao_id` | sem PK composta |
| `fazenda_cultura` | `fazenda_id`, `cultura_id` | sem PK composta |
| `fazenda_equipamento` | `fazenda_id`, `equipamento_id` | sem PK composta |
| `cultura_tipo_demanda` | `cultura_id`, `tipo` | `cultura_id` + `tipo` |
| `demanda_grupo` | `demanda_id`, `grupo_id` | sem PK composta |
| `demanda_sensoriamento_remoto` | `demanda_id`, `sensoriamento_remoto_id` | `demanda_id` + `sensoriamento_remoto_id` |

As tabelas `demanda_grupo`, `grupo_talhao`, `fazenda_cultura` e `fazenda_equipamento` não possuem PK composta nas migrations atuais. O modelo preserva essa característica em vez de inventar uma restrição inexistente.

## Regras aplicadas

1. FK com `NOT NULL` produz participação `(1,1)` no lado referenciado.
2. FK anulável produz participação `(0,1)` no lado referenciado.
3. FK com `UNIQUE` limita a entidade dependente a `(0,1)` para cada registro principal.
4. Coleções JPA e tabelas associativas permanecem `(0,N)`; o banco não exige pelo menos um item.
5. IDs de auditoria sem FK, como `demanda_status_historico.alterado_por_id` e `audit_log.entidade_id`, continuam atributos de snapshot e não viram relacionamentos artificiais.
6. `cultura_tipo_demanda` é uma coleção de valores da cultura no modelo lógico, não uma entidade de negócio no conceitual.
7. As autorreferências de demanda e sensoriamento distinguem o registro de origem, opcional, dos registros derivados, potencialmente numerosos.

## Artefatos

- [Modelo conceitual em DOT](auster-agx-conceitual.dot)
- [Modelo conceitual em SVG](auster-agx-conceitual.svg)
- [Modelo conceitual em PNG](auster-agx-conceitual.png)
- [Modelo lógico em DOT](auster-agx-logico.dot)
- [Modelo lógico em SVG](auster-agx-logico.svg)
- [Modelo lógico em PNG](auster-agx-logico.png)
- [Grafo JointJS para o brModelo Web](auster-agx-brmodelo-web.json)
- [Catálogo semântico completo](auster-agx-dominio.md)
