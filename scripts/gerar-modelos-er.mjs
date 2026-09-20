import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDir, '..');
const outputDir = path.join(repositoryRoot, 'docs', 'modelo-er');

const domains = {
  organizacao: {
    label: 'ORGANIZAÇÃO, CLIENTES E ACESSO',
    fill: '#EAF4F1',
    border: '#5C7C73',
  },
  agronomia: {
    label: 'AGRONOMIA E ESTRUTURA PRODUTIVA',
    fill: '#EEF5E7',
    border: '#6D8060',
  },
  demandas: {
    label: 'PEDIDOS, DEMANDAS E SENSORIAMENTO',
    fill: '#EAF1F8',
    border: '#5D748A',
  },
  prescricoes: {
    label: 'MANEJO E PRESCRIÇÕES',
    fill: '#FFF4DF',
    border: '#8A744D',
  },
  infraestrutura: {
    label: 'INFRAESTRUTURA E SEGURANÇA',
    fill: '#F2F0F6',
    border: '#766D82',
  },
};

const column = (key, name, type, required = false) => ({
  key,
  name,
  type,
  required,
});

const entities = [
  {
    id: 'USUARIO', label: 'USUÁRIO', table: 'usuario', domain: 'organizacao', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('UK', 'email', 'VARCHAR(120)', true), column('', 'nome', 'VARCHAR(150)', true),
      column('', 'perfil', 'VARCHAR(30)', true), column('', 'senha_hash', 'VARCHAR(255)', true),
      column('', 'deve_alterar_senha', 'BOOLEAN', true), column('', 'ativo', 'BOOLEAN', true),
      column('', 'created_at', 'TIMESTAMP', true), column('', 'updated_at', 'TIMESTAMP'),
    ],
  },
  {
    id: 'CLIENTE', label: 'CLIENTE', table: 'cliente', domain: 'organizacao', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'usuario_id', 'BIGINT', true), column('', 'nome_fantasia', 'VARCHAR(150)', true),
      column('', 'razao_social', 'VARCHAR(150)'), column('', 'numero_documento', 'VARCHAR(18)', true),
      column('', 'tipo_documento', 'VARCHAR(4)', true), column('', 'email_faturamento', 'VARCHAR(120)', true),
      column('', 'ativo', 'BOOLEAN', true), column('', '...', 'dados cadastrais e endereço'),
    ],
  },
  {
    id: 'CLIENTE_FAZENDA', label: 'CLIENTE-FAZENDA', table: 'cliente_fazenda', domain: 'organizacao', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'cliente_id', 'BIGINT', true), column('FK', 'fazenda_id', 'BIGINT', true),
      column('', 'data_inicio', 'DATE', true), column('', 'data_fim', 'DATE'),
    ],
  },
  {
    id: 'FAZENDA', label: 'FAZENDA', table: 'fazenda', domain: 'organizacao', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'cliente_proprietario_id', 'BIGINT'), column('', 'nome', 'VARCHAR(150)', true),
      column('', 'area_ha', 'NUMERIC(12,4)'), column('', 'area_cultivavel', 'NUMERIC(12,4)'),
      column('', 'latitude', 'NUMERIC'), column('', 'longitude', 'NUMERIC'),
      column('', 'ativo', 'BOOLEAN', true), column('', '...', 'endereço e geometria'),
    ],
  },
  {
    id: 'COLABORADOR', label: 'COLABORADOR', table: 'colaborador', domain: 'organizacao', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'cliente_id', 'BIGINT'), column('FK', 'usuario_id', 'BIGINT'),
      column('', 'nome', 'VARCHAR(150)', true), column('', 'email', 'VARCHAR(120)'),
      column('', 'cargo', 'VARCHAR(100)'), column('', 'telefone', 'VARCHAR(30)'),
      column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'FEEDBACK', label: 'FEEDBACK', table: 'feedback', domain: 'organizacao', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'usuario_id', 'BIGINT', true), column('', 'tipo', 'VARCHAR(20)', true),
      column('', 'titulo', 'VARCHAR(150)', true), column('', 'descricao', 'TEXT', true),
      column('', 'issue_numero', 'INTEGER'), column('', 'anexo_chave', 'VARCHAR(255)'),
      column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'TALHAO', label: 'TALHÃO', table: 'talhao', domain: 'agronomia', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'fazenda_id', 'BIGINT', true), column('', 'codigo_lpt', 'VARCHAR(30)'),
      column('', 'nome', 'VARCHAR(100)'), column('', 'numero_talhao', 'INTEGER'),
      column('', 'area_ha', 'NUMERIC(12,4)'), column('', 'area_cultivavel', 'NUMERIC(12,4)'),
      column('', 'irrigacao', 'BOOLEAN', true), column('', '...', 'coordenadas e geometria'),
    ],
  },
  {
    id: 'GRUPO', label: 'GRUPO', table: 'grupo', domain: 'agronomia', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('', 'nome', 'VARCHAR(150)', true), column('', 'ativo', 'BOOLEAN', true),
      column('', 'created_at', 'TIMESTAMP', true), column('', 'updated_at', 'TIMESTAMP'),
    ],
  },
  {
    id: 'CULTURA', label: 'CULTURA', table: 'cultura', domain: 'agronomia', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('', 'nome', 'VARCHAR(150)', true),
      column('', 'grupo_cultura', 'VARCHAR(50)'), column('', 'precocidade', 'VARCHAR'),
      column('', 'ativo', 'BOOLEAN', true), column('', 'created_at', 'TIMESTAMP', true),
      column('', 'updated_at', 'TIMESTAMP'),
    ],
  },
  {
    id: 'CULTIVO', label: 'CULTIVO', table: 'cultivo', domain: 'agronomia', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'talhao_id', 'BIGINT', true), column('FK/UK', 'cultura_id', 'BIGINT', true),
      column('', 'data_semeadura', 'DATE'), column('', 'data_colheita', 'DATE'),
      column('', 'finalidade_cultivo', 'VARCHAR'), column('', 'produtividade_desejada', 'NUMERIC'),
      column('', 'ativo', 'BOOLEAN', true), column('', '...', 'produtividade e mapa'),
    ],
  },
  {
    id: 'CULTURA_ANTECESSORA', label: 'CULTURA ANTECESSORA', table: 'cultura_antecessora', domain: 'agronomia', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'talhao_id', 'BIGINT', true), column('FK', 'cultura_id', 'BIGINT', true),
      column('', 'safra', 'VARCHAR'), column('', 'ciclo', 'INTEGER'),
      column('', 'produtividade_media', 'NUMERIC'), column('', 'observacao', 'VARCHAR'),
      column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'DADOS_SOLO', label: 'DADOS DE SOLO', table: 'dados_solo', domain: 'agronomia', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'talhao_id', 'BIGINT', true), column('', 'data_cadastro', 'DATE', true),
      column('', 'media_argila', 'NUMERIC'), column('', 'media_mos', 'NUMERIC'),
      column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'ESTADIO_FENOLOGICO', label: 'ESTÁDIO FENOLÓGICO', table: 'estadio_fenologico', domain: 'agronomia', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('FK', 'cultura_id', 'BIGINT'),
      column('', 'nome', 'VARCHAR(100)', true), column('', 'ordem', 'INTEGER'),
      column('', 'efa', 'NUMERIC'), column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'EQUIPAMENTO', label: 'EQUIPAMENTO', table: 'equipamento', domain: 'agronomia', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('', 'nome', 'VARCHAR(150)', true),
      column('', 'comentario', 'VARCHAR'), column('', 'ativo', 'BOOLEAN', true),
      column('', 'created_at', 'TIMESTAMP', true), column('', 'updated_at', 'TIMESTAMP'),
    ],
  },
  {
    id: 'PEDIDO', label: 'PEDIDO', table: 'pedido', domain: 'demandas', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'cliente_id', 'BIGINT', true), column('', 'codigo', 'VARCHAR(20)', true),
      column('', 'apelido', 'VARCHAR'), column('', 'observacoes', 'VARCHAR'),
      column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'DEMANDA', label: 'DEMANDA', table: 'demanda', domain: 'demandas', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'pedido_id', 'BIGINT', true), column('FK', 'demanda_origem_id', 'BIGINT'),
      column('FK', 'representante_id', 'BIGINT'), column('', 'codigo_demanda', 'VARCHAR(20)', true),
      column('', 'tipo', 'VARCHAR(100)', true), column('', 'status', 'VARCHAR(50)', true),
      column('', 'situacao_dados', 'VARCHAR(50)', true), column('', 'situacao_mapeamento', 'VARCHAR(50)', true),
      column('', 'retrabalho', 'BOOLEAN', true), column('', '...', 'prazo, área e aplicação'),
    ],
  },
  {
    id: 'DEMANDA_STATUS_HISTORICO', label: 'HISTÓRICO DE STATUS', table: 'demanda_status_historico', domain: 'demandas', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('FK', 'demanda_id', 'BIGINT', true),
      column('', 'status_anterior', 'VARCHAR(50)'), column('', 'status_novo', 'VARCHAR(50)', true),
      column('', 'alterado_em', 'TIMESTAMP', true), column('', 'alterado_por_id', 'BIGINT', true),
      column('', 'alterado_por_nome', 'VARCHAR(150)', true),
    ],
  },
  {
    id: 'SENSORIAMENTO_REMOTO', label: 'SENSORIAMENTO REMOTO', table: 'sensoriamento_remoto', domain: 'demandas', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'piloto_id', 'BIGINT'), column('FK', 'mapeamento_origem_id', 'BIGINT'),
      column('', 'codigo_mapeamento', 'VARCHAR(20)', true), column('', 'fonte', 'VARCHAR(150)', true),
      column('', 'qualidade', 'VARCHAR(100)'), column('', 'data_imagem', 'DATE'),
      column('', 'status', 'VARCHAR(30)', true), column('', '...', 'satélite, imagem e observações'),
    ],
  },
  {
    id: 'ADUBACAO', label: 'ADUBAÇÃO', table: 'adubacao', domain: 'prescricoes', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK', 'demanda_id', 'BIGINT', true), column('FK', 'estadio_fenologico_id', 'BIGINT'),
      column('', 'tipo_adubacao', 'VARCHAR(20)', true), column('', 'nome_fertilizante', 'VARCHAR'),
      column('', 'data_estimada_aplicacao', 'DATE'), column('', 'taxa_aplicacao_irrigado', 'NUMERIC'),
      column('', 'taxa_aplicacao_sequeiro', 'NUMERIC'), column('', 'ativo', 'BOOLEAN', true),
    ],
  },
  {
    id: 'MANEJO_NITROGENIO', label: 'MANEJO DE NITROGÊNIO', table: 'manejo_nitrogenio', domain: 'prescricoes', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK/UK', 'demanda_id', 'BIGINT', true), column('FK', 'equipamento_aplicacao_id', 'BIGINT'),
      column('', 'total_insumo_disponivel', 'NUMERIC'), column('', 'restricao_taxa_media_ativa', 'BOOLEAN', true),
      column('', 'restricao_taxa_pontual_ativa', 'BOOLEAN', true), column('', 'testemunha_ativa', 'BOOLEAN', true),
      column('', 'ativo', 'BOOLEAN', true), column('', '...', 'limites e taxas'),
    ],
  },
  {
    id: 'PRESCRICAO_SMART_BRAKE', label: 'PRESCRIÇÃO SMART BRAKE', table: 'prescricao_smart_brake', domain: 'prescricoes', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK/UK', 'demanda_id', 'BIGINT', true), column('FK', 'estadio_fenologico_id', 'BIGINT'),
      column('FK', 'equipamento_aplicacao_id', 'BIGINT'), column('', 'tipo_restricao_taxa', 'VARCHAR(20)'),
      column('', 'produto_utilizado', 'VARCHAR(150)'), column('', 'taxa_zero', 'BOOLEAN', true),
      column('', 'ativo', 'BOOLEAN', true), column('', '...', 'taxas e testemunha'),
    ],
  },
  {
    id: 'PRESCRICAO_SMART_SEEDING', label: 'PRESCRIÇÃO SMART SEEDING', table: 'prescricao_smart_seeding', domain: 'prescricoes', publicId: true,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'public_id', 'UUID', true),
      column('FK/UK', 'demanda_id', 'BIGINT', true), column('FK', 'modelo_semeadora_id', 'BIGINT'),
      column('', 'distancia_entre_linhas', 'NUMERIC'), column('', 'peso_mil_sementes', 'NUMERIC'),
      column('', 'total_sementes_disponivel', 'NUMERIC'), column('', 'testemunha_ativa', 'BOOLEAN', true),
      column('', 'ativo', 'BOOLEAN', true), column('', '...', 'taxas e restrições'),
    ],
  },
  {
    id: 'ARQUIVO_UPLOAD', label: 'ARQUIVO DE UPLOAD', table: 'arquivo_upload', domain: 'infraestrutura', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('UK', 'chave', 'VARCHAR(255)', true),
      column('FK', 'usuario_id', 'BIGINT', true), column('', 'tipo', 'VARCHAR(30)', true),
      column('', 'created_at', 'TIMESTAMP', true),
    ],
  },
  {
    id: 'AUDIT_LOG', label: 'LOG DE AUDITORIA', table: 'audit_log', domain: 'infraestrutura', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('FK', 'usuario_id', 'BIGINT'),
      column('', 'usuario_public_id', 'UUID'), column('', 'entidade', 'VARCHAR(100)', true),
      column('', 'entidade_id', 'BIGINT', true), column('', 'entidade_public_id', 'UUID'),
      column('', 'acao', 'VARCHAR(20)', true), column('', 'valores_antigos', 'TEXT'),
      column('', 'valores_novos', 'TEXT'), column('', 'created_at', 'TIMESTAMP', true),
    ],
  },
  {
    id: 'GOOGLE_DRIVE_CREDENTIAL', label: 'CREDENCIAL GOOGLE DRIVE', table: 'google_drive_credential', domain: 'infraestrutura', publicId: false, keyName: 'usuario_id',
    columns: [
      column('PK/FK', 'usuario_id', 'BIGINT', true), column('', 'access_token', 'TEXT', true),
      column('', 'refresh_token', 'TEXT', true), column('', 'expira_em', 'TIMESTAMP', true),
      column('', 'created_at', 'TIMESTAMP', true), column('', 'updated_at', 'TIMESTAMP', true),
    ],
  },
  {
    id: 'PASSWORD_RESET_TOKEN', label: 'TOKEN DE REDEFINIÇÃO', table: 'password_reset_token', domain: 'infraestrutura', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('FK', 'usuario_id', 'BIGINT', true),
      column('UK', 'token_hash', 'VARCHAR(128)', true), column('', 'expires_at', 'TIMESTAMP', true),
      column('', 'usado', 'BOOLEAN', true), column('', 'created_at', 'TIMESTAMP', true),
    ],
  },
  {
    id: 'REFRESH_TOKEN', label: 'REFRESH TOKEN', table: 'refresh_token', domain: 'infraestrutura', publicId: false,
    columns: [
      column('PK', 'id', 'BIGINT', true), column('FK', 'usuario_id', 'BIGINT', true),
      column('UK', 'token_hash', 'VARCHAR(128)', true), column('', 'expires_at', 'TIMESTAMP', true),
      column('', 'revoked', 'BOOLEAN', true), column('', 'revoked_at', 'TIMESTAMP'),
      column('', 'created_at', 'TIMESTAMP', true),
    ],
  },
  {
    id: 'SEQUENCIA_CODIGO', label: 'SEQUÊNCIA DE CÓDIGO', table: 'sequencia_codigo', domain: 'infraestrutura', publicId: false, keyName: 'chave',
    columns: [column('PK', 'chave', 'VARCHAR(60)', true), column('', 'valor', 'INTEGER', true)],
  },
];

const associationTables = [
  {
    id: 'COLABORADOR_FAZENDA', label: 'COLABORADOR-FAZENDA', table: 'colaborador_fazenda', domain: 'organizacao', association: true,
    columns: [column('PK/FK', 'colaborador_id', 'BIGINT', true), column('PK/FK', 'fazenda_id', 'BIGINT', true)],
  },
  {
    id: 'GRUPO_TALHAO', label: 'GRUPO-TALHÃO', table: 'grupo_talhao', domain: 'agronomia', association: true,
    columns: [column('FK', 'grupo_id', 'BIGINT', true), column('FK', 'talhao_id', 'BIGINT', true)],
  },
  {
    id: 'FAZENDA_CULTURA', label: 'FAZENDA-CULTURA', table: 'fazenda_cultura', domain: 'agronomia', association: true,
    columns: [column('FK', 'fazenda_id', 'BIGINT', true), column('FK', 'cultura_id', 'BIGINT', true)],
  },
  {
    id: 'FAZENDA_EQUIPAMENTO', label: 'FAZENDA-EQUIPAMENTO', table: 'fazenda_equipamento', domain: 'agronomia', association: true,
    columns: [column('FK', 'fazenda_id', 'BIGINT', true), column('FK', 'equipamento_id', 'BIGINT', true)],
  },
  {
    id: 'CULTURA_TIPO_DEMANDA', label: 'TIPOS DE DEMANDA DA CULTURA', table: 'cultura_tipo_demanda', domain: 'agronomia', association: true,
    columns: [column('PK/FK', 'cultura_id', 'BIGINT', true), column('PK', 'tipo', 'VARCHAR(100)', true)],
  },
  {
    id: 'DEMANDA_GRUPO', label: 'DEMANDA-GRUPO', table: 'demanda_grupo', domain: 'demandas', association: true,
    columns: [column('FK', 'demanda_id', 'BIGINT', true), column('FK', 'grupo_id', 'BIGINT', true)],
  },
  {
    id: 'DEMANDA_SENSORIAMENTO_REMOTO', label: 'DEMANDA-SENSORIAMENTO', table: 'demanda_sensoriamento_remoto', domain: 'demandas', association: true,
    columns: [column('PK/FK', 'demanda_id', 'BIGINT', true), column('PK/FK', 'sensoriamento_remoto_id', 'BIGINT', true)],
  },
];

const relationship = (id, name, left, leftCardinality, right, rightCardinality, implementation, source = 'JPA') => ({
  id,
  name,
  left,
  leftCardinality,
  right,
  rightCardinality,
  implementation,
  source,
});

const relationships = [
  relationship('R01', 'ADMINISTRADO_POR', 'CLIENTE', '(0,N)', 'USUARIO', '(1,1)', 'cliente.usuario_id NOT NULL'),
  relationship('R02', 'VINCULA_CLIENTE', 'CLIENTE_FAZENDA', '(0,N)', 'CLIENTE', '(1,1)', 'cliente_fazenda.cliente_id NOT NULL'),
  relationship('R03', 'VINCULA_FAZENDA', 'CLIENTE_FAZENDA', '(0,N)', 'FAZENDA', '(1,1)', 'cliente_fazenda.fazenda_id NOT NULL'),
  relationship('R04', 'ATUA_PARA', 'COLABORADOR', '(0,N)', 'CLIENTE', '(0,1)', 'colaborador.cliente_id NULL'),
  relationship('R05', 'ATUA_EM', 'COLABORADOR', '(0,N)', 'FAZENDA', '(0,N)', 'tabela colaborador_fazenda'),
  relationship('R06', 'VINCULA_CONTA', 'COLABORADOR', '(0,N)', 'USUARIO', '(0,1)', 'colaborador.usuario_id NULL'),
  relationship('R07', 'PERTENCE_A_CLIENTE', 'FAZENDA', '(0,N)', 'CLIENTE', '(0,1)', 'fazenda.cliente_proprietario_id NULL'),
  relationship('R08', 'CRIADO_POR', 'FEEDBACK', '(0,N)', 'USUARIO', '(1,1)', 'feedback.usuario_id NOT NULL'),
  relationship('R09', 'PERTENCE_A_FAZENDA', 'TALHAO', '(0,N)', 'FAZENDA', '(1,1)', 'talhao.fazenda_id NOT NULL'),
  relationship('R10', 'AGRUPA_TALHAO', 'GRUPO', '(0,N)', 'TALHAO', '(0,N)', 'tabela grupo_talhao'),
  relationship('R11', 'OCORRE_NO_TALHAO', 'CULTIVO', '(0,N)', 'TALHAO', '(1,1)', 'cultivo.talhao_id NOT NULL'),
  relationship('R12', 'UTILIZA_CULTURA', 'CULTIVO', '(0,1)', 'CULTURA', '(1,1)', 'cultivo.cultura_id NOT NULL UNIQUE'),
  relationship('R13', 'OCORREU_NO_TALHAO', 'CULTURA_ANTECESSORA', '(0,N)', 'TALHAO', '(1,1)', 'cultura_antecessora.talhao_id NOT NULL'),
  relationship('R14', 'REFERENCIA_CULTURA', 'CULTURA_ANTECESSORA', '(0,N)', 'CULTURA', '(1,1)', 'cultura_antecessora.cultura_id NOT NULL'),
  relationship('R15', 'DESCREVE_SOLO', 'DADOS_SOLO', '(0,N)', 'TALHAO', '(1,1)', 'dados_solo.talhao_id NOT NULL'),
  relationship('R16', 'PERTENCE_A_CULTURA', 'ESTADIO_FENOLOGICO', '(0,N)', 'CULTURA', '(0,1)', 'estadio_fenologico.cultura_id NULL'),
  relationship('R17', 'PRODUZ_CULTURA', 'FAZENDA', '(0,N)', 'CULTURA', '(0,N)', 'tabela fazenda_cultura'),
  relationship('R18', 'UTILIZA_EQUIPAMENTO', 'FAZENDA', '(0,N)', 'EQUIPAMENTO', '(0,N)', 'tabela fazenda_equipamento'),
  relationship('R19', 'SOLICITADO_POR', 'PEDIDO', '(0,N)', 'CLIENTE', '(1,1)', 'pedido.cliente_id NOT NULL'),
  relationship('R20', 'PERTENCE_A_PEDIDO', 'DEMANDA', '(0,N)', 'PEDIDO', '(1,1)', 'demanda.pedido_id NOT NULL'),
  relationship('R21', 'ORIGINA_RETRABALHO', 'DEMANDA', '(0,N)', 'DEMANDA', '(0,1)', 'demanda.demanda_origem_id NULL'),
  relationship('R22', 'REPRESENTADA_POR', 'DEMANDA', '(0,N)', 'COLABORADOR', '(0,1)', 'demanda.representante_id NULL'),
  relationship('R23', 'ABRANGE_GRUPO', 'DEMANDA', '(0,N)', 'GRUPO', '(0,N)', 'tabela demanda_grupo'),
  relationship('R24', 'UTILIZA_MAPEAMENTO', 'DEMANDA', '(0,N)', 'SENSORIAMENTO_REMOTO', '(0,N)', 'tabela demanda_sensoriamento_remoto'),
  relationship('R25', 'REGISTRA_STATUS', 'DEMANDA_STATUS_HISTORICO', '(0,N)', 'DEMANDA', '(1,1)', 'demanda_status_historico.demanda_id NOT NULL'),
  relationship('R26', 'RESPONSAVEL_POR', 'SENSORIAMENTO_REMOTO', '(0,N)', 'COLABORADOR', '(0,1)', 'sensoriamento_remoto.piloto_id NULL'),
  relationship('R27', 'DERIVA_DE', 'SENSORIAMENTO_REMOTO', '(0,N)', 'SENSORIAMENTO_REMOTO', '(0,1)', 'sensoriamento_remoto.mapeamento_origem_id NULL'),
  relationship('R28', 'DETALHA_DEMANDA', 'ADUBACAO', '(0,N)', 'DEMANDA', '(1,1)', 'adubacao.demanda_id NOT NULL'),
  relationship('R29', 'APLICA_NO_ESTADIO', 'ADUBACAO', '(0,N)', 'ESTADIO_FENOLOGICO', '(0,1)', 'adubacao.estadio_fenologico_id NULL'),
  relationship('R30', 'CONFIGURA_MANEJO', 'MANEJO_NITROGENIO', '(0,1)', 'DEMANDA', '(1,1)', 'manejo_nitrogenio.demanda_id NOT NULL UNIQUE'),
  relationship('R31', 'USA_EQUIPAMENTO', 'MANEJO_NITROGENIO', '(0,N)', 'EQUIPAMENTO', '(0,1)', 'manejo_nitrogenio.equipamento_aplicacao_id NULL'),
  relationship('R32', 'CONFIGURA_PRESCRICAO', 'PRESCRICAO_SMART_BRAKE', '(0,1)', 'DEMANDA', '(1,1)', 'prescricao_smart_brake.demanda_id NOT NULL UNIQUE'),
  relationship('R33', 'APLICA_NO_ESTADIO', 'PRESCRICAO_SMART_BRAKE', '(0,N)', 'ESTADIO_FENOLOGICO', '(0,1)', 'prescricao_smart_brake.estadio_fenologico_id NULL'),
  relationship('R34', 'USA_EQUIPAMENTO', 'PRESCRICAO_SMART_BRAKE', '(0,N)', 'EQUIPAMENTO', '(0,1)', 'prescricao_smart_brake.equipamento_aplicacao_id NULL'),
  relationship('R35', 'CONFIGURA_SEMEADURA', 'PRESCRICAO_SMART_SEEDING', '(0,1)', 'DEMANDA', '(1,1)', 'prescricao_smart_seeding.demanda_id NOT NULL UNIQUE'),
  relationship('R36', 'USA_SEMEADORA', 'PRESCRICAO_SMART_SEEDING', '(0,N)', 'EQUIPAMENTO', '(0,1)', 'prescricao_smart_seeding.modelo_semeadora_id NULL'),
  relationship('R37', 'ENVIA_ARQUIVO', 'ARQUIVO_UPLOAD', '(0,N)', 'USUARIO', '(1,1)', 'arquivo_upload.usuario_id NOT NULL', 'Flyway'),
  relationship('R38', 'REGISTRA_AUDITORIA', 'AUDIT_LOG', '(0,N)', 'USUARIO', '(0,1)', 'audit_log.usuario_id NULL', 'Flyway'),
  relationship('R39', 'POSSUI_CREDENCIAL', 'GOOGLE_DRIVE_CREDENTIAL', '(0,1)', 'USUARIO', '(1,1)', 'google_drive_credential.usuario_id PK/FK', 'Flyway'),
  relationship('R40', 'SOLICITA_REDEFINICAO', 'PASSWORD_RESET_TOKEN', '(0,N)', 'USUARIO', '(1,1)', 'password_reset_token.usuario_id NOT NULL', 'Flyway'),
  relationship('R41', 'MANTEM_SESSAO', 'REFRESH_TOKEN', '(0,N)', 'USUARIO', '(1,1)', 'refresh_token.usuario_id NOT NULL', 'Flyway'),
];

const foreignKey = (child, columnName, parent, childCardinality = '(0,N)', parentCardinality = '(1,1)', options = {}) => ({
  child,
  columnName,
  parent,
  childCardinality,
  parentCardinality,
  ...options,
});

const logicalForeignKeys = [
  foreignKey('cliente', 'usuario_id', 'usuario'),
  foreignKey('cliente_fazenda', 'cliente_id', 'cliente'),
  foreignKey('cliente_fazenda', 'fazenda_id', 'fazenda'),
  foreignKey('colaborador', 'cliente_id', 'cliente', '(0,N)', '(0,1)'),
  foreignKey('colaborador', 'usuario_id', 'usuario', '(0,N)', '(0,1)'),
  foreignKey('colaborador_fazenda', 'colaborador_id', 'colaborador'),
  foreignKey('colaborador_fazenda', 'fazenda_id', 'fazenda'),
  foreignKey('fazenda', 'cliente_proprietario_id', 'cliente', '(0,N)', '(0,1)'),
  foreignKey('feedback', 'usuario_id', 'usuario'),
  foreignKey('talhao', 'fazenda_id', 'fazenda'),
  foreignKey('grupo_talhao', 'grupo_id', 'grupo'),
  foreignKey('grupo_talhao', 'talhao_id', 'talhao'),
  foreignKey('cultivo', 'talhao_id', 'talhao'),
  foreignKey('cultivo', 'cultura_id', 'cultura', '(0,1)', '(1,1)', { unique: true }),
  foreignKey('cultura_antecessora', 'talhao_id', 'talhao'),
  foreignKey('cultura_antecessora', 'cultura_id', 'cultura'),
  foreignKey('dados_solo', 'talhao_id', 'talhao'),
  foreignKey('estadio_fenologico', 'cultura_id', 'cultura', '(0,N)', '(0,1)'),
  foreignKey('fazenda_cultura', 'fazenda_id', 'fazenda'),
  foreignKey('fazenda_cultura', 'cultura_id', 'cultura'),
  foreignKey('fazenda_equipamento', 'fazenda_id', 'fazenda'),
  foreignKey('fazenda_equipamento', 'equipamento_id', 'equipamento'),
  foreignKey('cultura_tipo_demanda', 'cultura_id', 'cultura'),
  foreignKey('pedido', 'cliente_id', 'cliente'),
  foreignKey('demanda', 'pedido_id', 'pedido'),
  foreignKey('demanda', 'demanda_origem_id', 'demanda', '(0,N)', '(0,1)', { role: 'origem' }),
  foreignKey('demanda', 'representante_id', 'colaborador', '(0,N)', '(0,1)'),
  foreignKey('demanda_grupo', 'demanda_id', 'demanda'),
  foreignKey('demanda_grupo', 'grupo_id', 'grupo'),
  foreignKey('demanda_sensoriamento_remoto', 'demanda_id', 'demanda'),
  foreignKey('demanda_sensoriamento_remoto', 'sensoriamento_remoto_id', 'sensoriamento_remoto'),
  foreignKey('demanda_status_historico', 'demanda_id', 'demanda'),
  foreignKey('sensoriamento_remoto', 'piloto_id', 'colaborador', '(0,N)', '(0,1)'),
  foreignKey('sensoriamento_remoto', 'mapeamento_origem_id', 'sensoriamento_remoto', '(0,N)', '(0,1)', { role: 'origem' }),
  foreignKey('adubacao', 'demanda_id', 'demanda'),
  foreignKey('adubacao', 'estadio_fenologico_id', 'estadio_fenologico', '(0,N)', '(0,1)'),
  foreignKey('manejo_nitrogenio', 'demanda_id', 'demanda', '(0,1)', '(1,1)', { unique: true }),
  foreignKey('manejo_nitrogenio', 'equipamento_aplicacao_id', 'equipamento', '(0,N)', '(0,1)'),
  foreignKey('prescricao_smart_brake', 'demanda_id', 'demanda', '(0,1)', '(1,1)', { unique: true }),
  foreignKey('prescricao_smart_brake', 'estadio_fenologico_id', 'estadio_fenologico', '(0,N)', '(0,1)'),
  foreignKey('prescricao_smart_brake', 'equipamento_aplicacao_id', 'equipamento', '(0,N)', '(0,1)'),
  foreignKey('prescricao_smart_seeding', 'demanda_id', 'demanda', '(0,1)', '(1,1)', { unique: true }),
  foreignKey('prescricao_smart_seeding', 'modelo_semeadora_id', 'equipamento', '(0,N)', '(0,1)'),
  foreignKey('arquivo_upload', 'usuario_id', 'usuario'),
  foreignKey('audit_log', 'usuario_id', 'usuario', '(0,N)', '(0,1)'),
  foreignKey('google_drive_credential', 'usuario_id', 'usuario', '(0,1)', '(1,1)', { unique: true }),
  foreignKey('password_reset_token', 'usuario_id', 'usuario'),
  foreignKey('refresh_token', 'usuario_id', 'usuario'),
];

const tables = [...entities, ...associationTables];

function assertModel() {
  const entityIds = new Set(entities.map((entity) => entity.id));
  const tableNames = new Set(tables.map((table) => table.table));
  const relationshipIds = new Set(relationships.map((relation) => relation.id));
  const foreignKeyIds = new Set(logicalForeignKeys.map((fk) => `${fk.child}.${fk.columnName}->${fk.parent}`));
  const validCardinalities = new Set(['(0,1)', '(1,1)', '(0,N)']);

  if (entities.length !== 28) throw new Error(`Esperadas 28 entidades; obtidas ${entities.length}.`);
  if (relationships.length !== 41) throw new Error(`Esperados 41 relacionamentos conceituais; obtidos ${relationships.length}.`);
  if (tables.length !== 35) throw new Error(`Esperadas 35 tabelas lógicas; obtidas ${tables.length}.`);
  if (logicalForeignKeys.length !== 48) throw new Error(`Esperadas 48 referências lógicas; obtidas ${logicalForeignKeys.length}.`);
  if (entityIds.size !== entities.length) throw new Error('Existem identificadores de entidade duplicados.');
  if (tableNames.size !== tables.length) throw new Error('Existem nomes de tabela duplicados.');
  if (relationshipIds.size !== relationships.length) throw new Error('Existem identificadores de relacionamento duplicados.');
  if (foreignKeyIds.size !== logicalForeignKeys.length) throw new Error('Existem referências lógicas duplicadas.');
  if (relationships.filter((relation) => relation.source === 'JPA').length !== 36) {
    throw new Error('Esperadas 36 associações JPA.');
  }
  if (relationships.filter((relation) => relation.source === 'Flyway').length !== 5) {
    throw new Error('Esperadas 5 associações físicas adicionais das migrations.');
  }

  for (const relation of relationships) {
    if (!entityIds.has(relation.left) || !entityIds.has(relation.right)) {
      throw new Error(`Relacionamento ${relation.id} aponta para entidade inexistente.`);
    }
    if (!validCardinalities.has(relation.leftCardinality) || !validCardinalities.has(relation.rightCardinality)) {
      throw new Error(`Relacionamento ${relation.id} possui cardinalidade inválida.`);
    }
  }

  for (const fk of logicalForeignKeys) {
    if (!tableNames.has(fk.child) || !tableNames.has(fk.parent)) {
      throw new Error(`FK ${fk.child}.${fk.columnName} possui tabela inexistente.`);
    }
    const table = tables.find((candidate) => candidate.table === fk.child);
    const fkColumn = table.columns.find((candidate) => candidate.name === fk.columnName);
    if (!fkColumn) {
      throw new Error(`Coluna ${fk.child}.${fk.columnName} não está declarada.`);
    }
    if (!fkColumn.key.includes('FK')) {
      throw new Error(`Coluna ${fk.child}.${fk.columnName} não está marcada como FK.`);
    }
    const requiredParent = fk.parentCardinality === '(1,1)';
    if (fkColumn.required !== requiredParent) {
      throw new Error(`Nulabilidade de ${fk.child}.${fk.columnName} diverge da cardinalidade ${fk.parentCardinality}.`);
    }
    if (fk.unique && !fkColumn.key.includes('UK') && !fkColumn.key.includes('PK')) {
      throw new Error(`FK única ${fk.child}.${fk.columnName} não está marcada como UK ou PK.`);
    }
  }
}

function escapeDot(value) {
  return String(value).replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function graphId(value) {
  return value.toLowerCase().replaceAll(/[^a-z0-9_]/g, '_');
}

function conceptualDot() {
  const lines = [
    'digraph AusterConceitual {',
    '  graph [bgcolor="#FFFFFF", pad="0.35", margin="0", rankdir="LR", newrank=true, splines=polyline, overlap=false, nodesep="0.42", ranksep="1.15", fontname="Arial", fontsize=24, fontcolor="#173D35", label="MODELO CONCEITUAL DO DOMÍNIO AUSTERAGX\\n28 entidades · 41 relacionamentos auditados · cardinalidade mínima e máxima", labelloc="t", labeljust="c"];',
    '  node [fontname="Arial", fontsize=10, color="#273632", fontcolor="#17211E", penwidth=1.15];',
    '  edge [fontname="Arial", fontsize=9, color="#4B5955", fontcolor="#17211E", penwidth=1.0, arrowsize=0.55];',
  ];

  for (const [domainId, domain] of Object.entries(domains)) {
    lines.push(`  subgraph cluster_${domainId} {`);
    lines.push(`    label="${escapeDot(domain.label)}"; color="${domain.border}"; fillcolor="${domain.fill}"; style="rounded,filled"; penwidth=1.1; fontname="Arial"; fontsize=12; fontcolor="#273632"; margin=18;`);
    for (const entity of entities.filter((candidate) => candidate.domain === domainId)) {
      lines.push(`    ${entity.id} [shape=box, style="rounded,filled", fillcolor="#FFFFFF", color="${domain.border}", width=2.1, height=0.52, label="${escapeDot(entity.label)}"];`);
    }
    lines.push('  }');
  }

  for (const relation of relationships) {
    const physical = relation.source === 'Flyway';
    lines.push(`  ${relation.id} [shape=diamond, style="filled${physical ? ',dashed' : ''}", fillcolor="${physical ? '#F7F4FA' : '#FFFFFF'}", color="${physical ? '#766D82' : '#4B5955'}", width=1.48, height=0.68, fontsize=8.5, margin=0.03, label="${escapeDot(relation.name.replaceAll('_', '\n'))}"];`);
    const attributes = physical ? 'style=dashed, color="#766D82"' : '';
    const selfRelation = relation.left === relation.right ? ', constraint=false' : '';
    lines.push(`  ${relation.left} -> ${relation.id} [dir=none, label="${relation.leftCardinality}"${attributes ? `, ${attributes}` : ''}${selfRelation}];`);
    lines.push(`  ${relation.id} -> ${relation.right} [dir=none, label="${relation.rightCardinality}"${attributes ? `, ${attributes}` : ''}${selfRelation}];`);
  }

  lines.push('  legenda [shape=plain, label=<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="4" CELLPADDING="3"><TR><TD ALIGN="LEFT"><B>Leitura:</B> a cardinalidade junto à entidade indica quantas ocorrências dela participam para uma ocorrência do lado oposto.</TD></TR><TR><TD ALIGN="LEFT">Linha contínua: associação JPA · linha tracejada: FK física declarada em migration.</TD></TR></TABLE>>];');
  lines.push('}');
  return `${lines.join('\n')}\n`;
}

function tableLabel(table) {
  const domain = domains[table.domain];
  const rows = table.columns.map((item, index) => {
    const background = index % 2 === 0 ? '#FFFFFF' : '#F8FAFA';
    const keyColor = item.key.includes('PK') ? '#8A5A00' : item.key.includes('FK') ? '#1E6F5C' : item.key.includes('UK') ? '#365F91' : '#68736F';
    return `<TR><TD BGCOLOR="${background}" ALIGN="LEFT"><FONT COLOR="${keyColor}"><B>${escapeHtml(item.key || '')}</B></FONT></TD><TD BGCOLOR="${background}" ALIGN="LEFT">${escapeHtml(item.name)}</TD><TD BGCOLOR="${background}" ALIGN="LEFT"><FONT COLOR="#56635F">${escapeHtml(item.type)}</FONT></TD><TD BGCOLOR="${background}" ALIGN="CENTER">${item.required ? 'NN' : ''}</TD></TR>`;
  });

  return `<<TABLE BORDER="1" COLOR="${domain.border}" CELLBORDER="0" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#FFFFFF"><TR><TD COLSPAN="4" BGCOLOR="${table.association ? '#DDE9E5' : domain.fill}" ALIGN="CENTER"><B>${escapeHtml(table.table)}</B></TD></TR><TR><TD BGCOLOR="#F0F3F2"><B>Chave</B></TD><TD BGCOLOR="#F0F3F2"><B>Coluna</B></TD><TD BGCOLOR="#F0F3F2"><B>Tipo</B></TD><TD BGCOLOR="#F0F3F2"><B>Req.</B></TD></TR>${rows.join('')}</TABLE>>`;
}

function logicalDot() {
  const lines = [
    'digraph AusterLogico {',
    '  graph [bgcolor="#FFFFFF", pad="0.4", margin="0", rankdir="LR", newrank=true, splines=polyline, overlap=false, nodesep="0.52", ranksep="1.65", fontname="Arial", fontsize=24, fontcolor="#173D35", label="MODELO LÓGICO RELACIONAL DO AUSTERAGX\\n35 tabelas · 48 referências · PK, FK, UK e nulabilidade", labelloc="t", labeljust="c", compound=true];',
    '  node [shape=plain, fontname="Arial", fontsize=9.5];',
    '  edge [fontname="Arial", fontsize=8.5, color="#4B5955", fontcolor="#273632", penwidth=0.95, arrowsize=0.52, labeldistance=1.6, labelangle=22];',
  ];

  for (const [domainId, domain] of Object.entries(domains)) {
    lines.push(`  subgraph cluster_logico_${domainId} {`);
    lines.push(`    label="${escapeDot(domain.label)}"; color="${domain.border}"; fillcolor="#FBFCFC"; style="rounded,filled"; penwidth=1.0; fontname="Arial"; fontsize=12; fontcolor="#273632"; margin=22;`);
    for (const table of tables.filter((candidate) => candidate.domain === domainId)) {
      lines.push(`    ${graphId(table.table)} [label=${tableLabel(table)}];`);
    }
    lines.push('  }');
  }

  for (const fk of logicalForeignKeys) {
    const child = graphId(fk.child);
    const parent = graphId(fk.parent);
    const selfReference = child === parent ? ', constraint=false' : '';
    lines.push(`  ${child} -> ${parent} [dir=none, label="${escapeDot(fk.columnName)}\\n${fk.childCardinality} : ${fk.parentCardinality}"${selfReference}];`);
  }

  lines.push('  legenda_logica [shape=plain, label=<<TABLE BORDER="1" COLOR="#AAB5B1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="5"><TR><TD BGCOLOR="#F0F3F2"><B>Legenda</B></TD></TR><TR><TD ALIGN="LEFT">PK: chave primária · FK: chave estrangeira · UK: unicidade · NN: NOT NULL</TD></TR><TR><TD ALIGN="LEFT">A cardinalidade na origem indica filhos por pai; no destino, pais por filho.</TD></TR><TR><TD ALIGN="LEFT">A visão destaca chaves e atributos operacionais; o catálogo semântico mantém os demais campos.</TD></TR></TABLE>>];');
  lines.push('}');
  return `${lines.join('\n')}\n`;
}

const logicalModules = [
  {
    id: 'organizacao', title: '1. ORGANIZAÇÃO, CLIENTES E ACESSO', x: 30, y: 100, width: 2200, height: 950,
    fkStart: 0, fkEnd: 9,
    positions: {
      usuario: [55, 90], cliente: [495, 90], cliente_fazenda: [935, 90], fazenda: [1375, 90],
      feedback: [55, 560], colaborador: [495, 560], colaborador_fazenda: [935, 560],
    },
  },
  {
    id: 'agronomia', title: '2. AGRONOMIA E ESTRUTURA PRODUTIVA', x: 2260, y: 100, width: 3060, height: 950,
    fkStart: 9, fkEnd: 23,
    positions: {
      fazenda: [35, 90], talhao: [465, 90], cultivo: [895, 90], cultura: [1325, 90],
      estadio_fenologico: [1755, 90], equipamento: [2185, 90],
      grupo: [35, 560], grupo_talhao: [465, 560], dados_solo: [895, 560],
      cultura_antecessora: [1325, 560], cultura_tipo_demanda: [1755, 560],
      fazenda_cultura: [2185, 560], fazenda_equipamento: [2615, 560],
    },
  },
  {
    id: 'demandas', title: '3. PEDIDOS, DEMANDAS E SENSORIAMENTO', x: 30, y: 1080, width: 2640, height: 950,
    fkStart: 23, fkEnd: 34,
    positions: {
      cliente: [35, 90], pedido: [465, 90], demanda: [895, 90], demanda_status_historico: [1325, 90],
      sensoriamento_remoto: [1755, 90], colaborador: [2185, 90], grupo: [465, 590],
      demanda_grupo: [895, 590], demanda_sensoriamento_remoto: [1535, 590],
    },
  },
  {
    id: 'prescricoes', title: '4. MANEJO E PRESCRIÇÕES', x: 2700, y: 1080, width: 2620, height: 950,
    fkStart: 34, fkEnd: 43,
    positions: {
      demanda: [895, 90], estadio_fenologico: [1755, 90], equipamento: [2185, 90],
      adubacao: [35, 560], manejo_nitrogenio: [465, 560], prescricao_smart_brake: [895, 560],
      prescricao_smart_seeding: [1325, 560],
    },
  },
  {
    id: 'infraestrutura', title: '5. INFRAESTRUTURA E SEGURANÇA', x: 1345, y: 2060, width: 2640, height: 950,
    fkStart: 43, fkEnd: 48,
    positions: {
      usuario: [1080, 90], arquivo_upload: [35, 560], audit_log: [465, 560],
      google_drive_credential: [895, 560], password_reset_token: [1325, 560],
      refresh_token: [1755, 560], sequencia_codigo: [2185, 560],
    },
  },
];

const logicalTableWidth = 390;
const logicalHeaderHeight = 34;
const logicalColumnHeaderHeight = 24;
const logicalRowHeight = 22;

function logicalTableHeight(table) {
  return logicalHeaderHeight + logicalColumnHeaderHeight + table.columns.length * logicalRowHeight;
}

function logicalTableSvg(table, x, y) {
  const domain = domains[table.domain];
  const height = logicalTableHeight(table);
  const titleSize = table.table.length > 25 ? 12 : 14;
  const parts = [
    `<g id="table-${escapeHtml(table.table)}">`,
    `<rect x="${x}" y="${y}" width="${logicalTableWidth}" height="${height}" rx="5" fill="#FFFFFF" stroke="${domain.border}" stroke-width="1.3"/>`,
    `<rect x="${x}" y="${y}" width="${logicalTableWidth}" height="${logicalHeaderHeight}" rx="5" fill="${table.association ? '#DDE9E5' : domain.fill}"/>`,
    `<text x="${x + logicalTableWidth / 2}" y="${y + 22}" text-anchor="middle" font-size="${titleSize}" font-weight="700" fill="#17211E">${escapeHtml(table.table)}</text>`,
    `<rect x="${x}" y="${y + logicalHeaderHeight}" width="${logicalTableWidth}" height="${logicalColumnHeaderHeight}" fill="#F0F3F2"/>`,
    `<text x="${x + 8}" y="${y + 51}" font-size="10" font-weight="700">Chave</text>`,
    `<text x="${x + 60}" y="${y + 51}" font-size="10" font-weight="700">Coluna</text>`,
    `<text x="${x + 228}" y="${y + 51}" font-size="10" font-weight="700">Tipo</text>`,
    `<text x="${x + 360}" y="${y + 51}" font-size="10" font-weight="700">Req.</text>`,
  ];

  table.columns.forEach((item, index) => {
    const rowY = y + logicalHeaderHeight + logicalColumnHeaderHeight + index * logicalRowHeight;
    const textY = rowY + 15;
    const background = index % 2 === 0 ? '#FFFFFF' : '#F8FAFA';
    const keyColor = item.key.includes('PK') ? '#8A5A00' : item.key.includes('FK') ? '#1E6F5C' : item.key.includes('UK') ? '#365F91' : '#68736F';
    const type = item.type.length > 21 ? `${item.type.slice(0, 20)}…` : item.type;
    parts.push(`<rect x="${x + 1}" y="${rowY}" width="${logicalTableWidth - 2}" height="${logicalRowHeight}" fill="${background}"/>`);
    parts.push(`<text x="${x + 8}" y="${textY}" font-size="10" font-weight="700" fill="${keyColor}">${escapeHtml(item.key)}</text>`);
    parts.push(`<text x="${x + 60}" y="${textY}" font-size="10.5" fill="#17211E">${escapeHtml(item.name)}</text>`);
    parts.push(`<text x="${x + 228}" y="${textY}" font-size="9.5" fill="#56635F">${escapeHtml(type)}</text>`);
    parts.push(`<text x="${x + 366}" y="${textY}" text-anchor="middle" font-size="9.5" fill="#56635F">${item.required ? 'NN' : ''}</text>`);
  });

  parts.push(`<line x1="${x + 52}" y1="${y + logicalHeaderHeight}" x2="${x + 52}" y2="${y + height}" stroke="#D7DEDB"/>`);
  parts.push(`<line x1="${x + 220}" y1="${y + logicalHeaderHeight}" x2="${x + 220}" y2="${y + height}" stroke="#D7DEDB"/>`);
  parts.push(`<line x1="${x + 344}" y1="${y + logicalHeaderHeight}" x2="${x + 344}" y2="${y + height}" stroke="#D7DEDB"/>`);
  parts.push('</g>');
  return parts.join('');
}

function edgeLabelSvg(text, x, y, fontSize = 10) {
  const width = Math.max(44, text.length * fontSize * 0.58 + 10);
  return `<g><rect x="${x - width / 2}" y="${y - 12}" width="${width}" height="17" rx="2" fill="#FFFFFF" fill-opacity="0.92"/><text x="${x}" y="${y}" text-anchor="middle" font-size="${fontSize}" font-weight="600" fill="#273632">${escapeHtml(text)}</text></g>`;
}

function logicalEdgeSvg(fk, childBox, parentBox, edgeIndex) {
  const childCenter = { x: childBox.x + logicalTableWidth / 2, y: childBox.y + childBox.height / 2 };
  const parentCenter = { x: parentBox.x + logicalTableWidth / 2, y: parentBox.y + parentBox.height / 2 };
  const optional = fk.parentCardinality === '(0,1)';
  const dash = optional ? ' stroke-dasharray="7 5"' : '';

  if (fk.child === fk.parent) {
    const startX = childBox.x + logicalTableWidth;
    const startY = childBox.y + childBox.height * 0.38;
    const endY = childBox.y + childBox.height * 0.7;
    const loopX = startX + 120 + (edgeIndex % 3) * 18;
    const path = `M ${startX} ${startY} L ${loopX} ${startY} L ${loopX} ${endY} L ${startX} ${endY}`;
    return `<g><path d="${path}" fill="none" stroke="#52615C" stroke-width="1.25"${dash}/>${edgeLabelSvg(fk.childCardinality, startX + 34, startY - 6)}${edgeLabelSvg(fk.parentCardinality, startX + 34, endY + 15)}${edgeLabelSvg(fk.columnName, loopX, (startY + endY) / 2)}</g>`;
  }

  const horizontal = Math.abs(parentCenter.x - childCenter.x) >= Math.abs(parentCenter.y - childCenter.y);
  const laneOffset = ((edgeIndex % 5) - 2) * 12;
  let start;
  let end;
  let points;
  let labelPoint;

  if (horizontal) {
    const movingRight = parentCenter.x > childCenter.x;
    start = { x: movingRight ? childBox.x + logicalTableWidth : childBox.x, y: childCenter.y + laneOffset };
    end = { x: movingRight ? parentBox.x : parentBox.x + logicalTableWidth, y: parentCenter.y + laneOffset };
    const midX = (start.x + end.x) / 2 + laneOffset;
    points = `${start.x},${start.y} ${midX},${start.y} ${midX},${end.y} ${end.x},${end.y}`;
    labelPoint = { x: midX, y: (start.y + end.y) / 2 - 8 };
  } else {
    const movingDown = parentCenter.y > childCenter.y;
    start = { x: childCenter.x + laneOffset, y: movingDown ? childBox.y + childBox.height : childBox.y };
    end = { x: parentCenter.x + laneOffset, y: movingDown ? parentBox.y : parentBox.y + parentBox.height };
    const midY = (start.y + end.y) / 2 + laneOffset;
    points = `${start.x},${start.y} ${start.x},${midY} ${end.x},${midY} ${end.x},${end.y}`;
    labelPoint = { x: (start.x + end.x) / 2, y: midY - 7 };
  }

  const childLabel = horizontal
    ? { x: start.x + (end.x > start.x ? 34 : -34), y: start.y - 7 }
    : { x: start.x + 34, y: start.y + (end.y > start.y ? 16 : -8) };
  const parentLabel = horizontal
    ? { x: end.x + (end.x > start.x ? -34 : 34), y: end.y - 7 }
    : { x: end.x + 34, y: end.y + (end.y > start.y ? -8 : 16) };

  return `<g><polyline points="${points}" fill="none" stroke="#52615C" stroke-width="1.25" stroke-linejoin="round"${dash}/>${edgeLabelSvg(fk.childCardinality, childLabel.x, childLabel.y)}${edgeLabelSvg(fk.parentCardinality, parentLabel.x, parentLabel.y)}${edgeLabelSvg(fk.columnName, labelPoint.x, labelPoint.y, 9.5)}</g>`;
}

function logicalSvg() {
  const width = 5350;
  const height = 3160;
  const parts = [
    `<?xml version="1.0" encoding="UTF-8"?>`,
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    '<rect width="100%" height="100%" fill="#FFFFFF"/>',
    '<g font-family="Arial, sans-serif">',
    '<text x="2675" y="40" text-anchor="middle" font-size="26" font-weight="700" fill="#173D35">MODELO LÓGICO RELACIONAL DO AUSTERAGX</text>',
    '<text x="2675" y="68" text-anchor="middle" font-size="14" fill="#49665F">35 tabelas · 48 referências · PK, FK, UK, nulabilidade e cardinalidades auditadas</text>',
  ];

  let coveredForeignKeys = 0;
  for (const module of logicalModules) {
    const domain = domains[module.id];
    parts.push(`<g id="module-${module.id}">`);
    parts.push(`<rect x="${module.x}" y="${module.y}" width="${module.width}" height="${module.height}" rx="8" fill="#FCFDFD" stroke="${domain.border}" stroke-width="1.5"/>`);
    parts.push(`<rect x="${module.x}" y="${module.y}" width="${module.width}" height="50" rx="8" fill="${domain.fill}" stroke="${domain.border}" stroke-width="1.5"/>`);
    parts.push(`<text x="${module.x + 18}" y="${module.y + 31}" font-size="17" font-weight="700" fill="#273632">${escapeHtml(module.title)}</text>`);

    const boxes = new Map();
    for (const [tableName, coordinates] of Object.entries(module.positions)) {
      const table = tables.find((candidate) => candidate.table === tableName);
      if (!table) throw new Error(`Tabela ${tableName} não existe no módulo ${module.id}.`);
      boxes.set(tableName, {
        x: module.x + coordinates[0],
        y: module.y + coordinates[1],
        height: logicalTableHeight(table),
        table,
      });
    }

    const moduleForeignKeys = logicalForeignKeys.slice(module.fkStart, module.fkEnd);
    coveredForeignKeys += moduleForeignKeys.length;
    moduleForeignKeys.forEach((fk, index) => {
      const childBox = boxes.get(fk.child);
      const parentBox = boxes.get(fk.parent);
      if (!childBox || !parentBox) throw new Error(`Módulo ${module.id} não posicionou ${fk.child} ou ${fk.parent}.`);
      parts.push(logicalEdgeSvg(fk, childBox, parentBox, index));
    });

    for (const box of boxes.values()) {
      parts.push(logicalTableSvg(box.table, box.x, box.y));
    }
    parts.push('</g>');
  }

  if (coveredForeignKeys !== logicalForeignKeys.length) {
    throw new Error(`A vista lógica cobriu ${coveredForeignKeys} de ${logicalForeignKeys.length} FKs.`);
  }

  parts.push('<g id="logical-legend">');
  parts.push('<rect x="1350" y="3030" width="2650" height="92" rx="6" fill="#F8FAF9" stroke="#AAB5B1"/>');
  parts.push('<text x="1380" y="3058" font-size="13" font-weight="700" fill="#273632">LEGENDA</text>');
  parts.push('<text x="1380" y="3082" font-size="12" fill="#44514D">PK: chave primária · FK: chave estrangeira · UK: unicidade · NN: NOT NULL</text>');
  parts.push('<text x="1380" y="3105" font-size="12" fill="#44514D">Em cada ligação: cardinalidade junto à tabela filha : cardinalidade junto à tabela pai. Linha tracejada indica FK opcional.</text>');
  parts.push('</g></g></svg>');
  return parts.join('');
}

const conceptualModules = [
  {
    id: 'organizacao', title: '1. ORGANIZAÇÃO, CLIENTES E ACESSO', x: 30, y: 100, width: 2200, height: 950,
    relationshipStart: 0, relationshipEnd: 8,
    positions: {
      USUARIO: [80, 145], CLIENTE: [600, 145], CLIENTE_FAZENDA: [1120, 145], FAZENDA: [1640, 145],
      FEEDBACK: [80, 680], COLABORADOR: [600, 680],
    },
    relationshipPositions: {
      R01: [390, 140], R02: [910, 140], R03: [1430, 140], R04: [650, 420],
      R05: [1240, 675], R06: [390, 540], R07: [1230, 350], R08: [130, 430],
    },
  },
  {
    id: 'agronomia', title: '2. AGRONOMIA E ESTRUTURA PRODUTIVA', x: 2260, y: 100, width: 3060, height: 950,
    relationshipStart: 8, relationshipEnd: 18,
    positions: {
      FAZENDA: [55, 145], TALHAO: [555, 145], CULTIVO: [1055, 145], CULTURA: [1555, 145],
      ESTADIO_FENOLOGICO: [2055, 145], EQUIPAMENTO: [2555, 145], GRUPO: [55, 680],
      DADOS_SOLO: [555, 680], CULTURA_ANTECESSORA: [1055, 680],
    },
    relationshipPositions: {
      R09: [390, 140], R10: [250, 440], R11: [890, 140], R12: [1390, 140],
      R13: [880, 510], R14: [1390, 675], R15: [605, 440], R16: [1890, 140],
      R17: [1130, 350], R18: [1640, 500],
    },
  },
  {
    id: 'demandas', title: '3. PEDIDOS, DEMANDAS E SENSORIAMENTO', x: 30, y: 1080, width: 2640, height: 950,
    relationshipStart: 18, relationshipEnd: 27,
    positions: {
      CLIENTE: [45, 145], PEDIDO: [465, 145], DEMANDA: [885, 145], DEMANDA_STATUS_HISTORICO: [1305, 145],
      SENSORIAMENTO_REMOTO: [1725, 145], COLABORADOR: [2145, 145], GRUPO: [885, 680],
    },
    relationshipPositions: {
      R19: [325, 140], R20: [745, 140], R21: [980, 330], R22: [1510, 365],
      R23: [930, 500], R24: [1510, 140], R25: [1165, 140], R26: [2005, 140], R27: [1770, 405],
    },
  },
  {
    id: 'prescricoes', title: '4. MANEJO E PRESCRIÇÕES', x: 2700, y: 1080, width: 2620, height: 950,
    relationshipStart: 27, relationshipEnd: 36,
    positions: {
      DEMANDA: [1000, 145], ESTADIO_FENOLOGICO: [1800, 145], EQUIPAMENTO: [2250, 145],
      ADUBACAO: [45, 790], MANEJO_NITROGENIO: [485, 790], PRESCRICAO_SMART_BRAKE: [925, 790],
      PRESCRICAO_SMART_SEEDING: [1365, 790],
    },
    relationshipPositions: {
      R28: [520, 470], R29: [900, 570], R30: [790, 430], R31: [1410, 570],
      R32: [1050, 430], R33: [1510, 570], R34: [1760, 630], R35: [1320, 430], R36: [1960, 520],
    },
  },
  {
    id: 'infraestrutura', title: '5. INFRAESTRUTURA E SEGURANÇA', x: 1345, y: 2060, width: 2640, height: 950,
    relationshipStart: 36, relationshipEnd: 41,
    positions: {
      USUARIO: [1190, 145], ARQUIVO_UPLOAD: [45, 680], AUDIT_LOG: [465, 680],
      GOOGLE_DRIVE_CREDENTIAL: [885, 680], PASSWORD_RESET_TOKEN: [1305, 680],
      REFRESH_TOKEN: [1725, 680], SEQUENCIA_CODIGO: [2145, 680],
    },
    relationshipPositions: { R37: [260, 420], R38: [680, 420], R39: [1100, 420], R40: [1420, 420], R41: [1740, 420] },
  },
];

const conceptualEntityWidth = 260;
const conceptualEntityHeight = 54;
const conceptualRelationshipWidth = 166;
const conceptualRelationshipHeight = 78;

function conceptualEntitySvg(entity, x, y) {
  const domain = domains[entity.domain];
  const titleSize = entity.label.length > 22 ? 12 : 14;
  const keyName = entity.keyName ?? 'id';
  const parts = [
    `<g id="entity-${escapeHtml(entity.id)}">`,
    `<rect x="${x}" y="${y}" width="${conceptualEntityWidth}" height="${conceptualEntityHeight}" rx="5" fill="#FFFFFF" stroke="${domain.border}" stroke-width="1.4"/>`,
    `<text x="${x + conceptualEntityWidth / 2}" y="${y + 33}" text-anchor="middle" font-size="${titleSize}" font-weight="700" fill="#17211E">${escapeHtml(entity.label)}</text>`,
    `<ellipse cx="${x + 92}" cy="${y - 35}" rx="30" ry="15" fill="#17211E"/>`,
    `<text x="${x + 92}" y="${y - 57}" text-anchor="middle" font-size="10" font-weight="700" fill="#17211E">${escapeHtml(keyName)}</text>`,
    `<line x1="${x + 92}" y1="${y - 20}" x2="${x + 110}" y2="${y}" stroke="#52615C" stroke-width="1"/>`,
  ];
  if (entity.publicId) {
    parts.push(`<ellipse cx="${x + 168}" cy="${y - 35}" rx="30" ry="15" fill="#FFFFFF" stroke="#52615C" stroke-width="1.1"/>`);
    parts.push(`<text x="${x + 168}" y="${y - 57}" text-anchor="middle" font-size="9.5" fill="#17211E">publicId (UK)</text>`);
    parts.push(`<line x1="${x + 168}" y1="${y - 20}" x2="${x + 150}" y2="${y}" stroke="#52615C" stroke-width="1"/>`);
  }
  parts.push('</g>');
  return parts.join('');
}

function wrapRelationshipName(name) {
  const words = name.split('_');
  if (words.length <= 2) return [words.join(' ')];
  if (words.length === 3) return [words.slice(0, 2).join(' '), words[2]];
  const middle = Math.ceil(words.length / 2);
  return [words.slice(0, middle).join(' '), words.slice(middle).join(' ')];
}

function conceptualRelationshipSvg(relation, x, y) {
  const physical = relation.source === 'Flyway';
  const centerX = x + conceptualRelationshipWidth / 2;
  const centerY = y + conceptualRelationshipHeight / 2;
  const points = `${centerX},${y} ${x + conceptualRelationshipWidth},${centerY} ${centerX},${y + conceptualRelationshipHeight} ${x},${centerY}`;
  const labels = wrapRelationshipName(relation.name);
  const textStartY = centerY - ((labels.length - 1) * 7) + 4;
  const parts = [
    `<polygon points="${points}" fill="${physical ? '#F7F4FA' : '#FFFFFF'}" stroke="${physical ? '#766D82' : '#52615C'}" stroke-width="1.25"${physical ? ' stroke-dasharray="7 5"' : ''}/>`
  ];
  labels.forEach((label, index) => {
    parts.push(`<text x="${centerX}" y="${textStartY + index * 14}" text-anchor="middle" font-size="9" font-weight="600" fill="#273632">${escapeHtml(label)}</text>`);
  });
  return parts.join('');
}

function conceptualArmSvg(entityBox, relationBox, cardinality, armIndex, selfArm = false, physical = false) {
  const entityCenter = { x: entityBox.x + conceptualEntityWidth / 2, y: entityBox.y + conceptualEntityHeight / 2 };
  const relationCenter = { x: relationBox.x + conceptualRelationshipWidth / 2, y: relationBox.y + conceptualRelationshipHeight / 2 };
  const dash = physical ? ' stroke-dasharray="7 5"' : '';
  if (selfArm) {
    const sideX = entityBox.x + conceptualEntityWidth;
    const startY = entityBox.y + (armIndex === 0 ? 16 : 40);
    const pathX = Math.max(sideX + 90 + armIndex * 24, relationBox.x + conceptualRelationshipWidth + 30);
    const endY = relationCenter.y + (armIndex === 0 ? -13 : 13);
    const path = `M ${sideX} ${startY} L ${pathX} ${startY} L ${pathX} ${endY} L ${relationBox.x + conceptualRelationshipWidth} ${endY}`;
    return `<g><path d="${path}" fill="none" stroke="#52615C" stroke-width="1.2"${dash}/>${edgeLabelSvg(cardinality, sideX + 38, startY - 7)}</g>`;
  }

  const dx = relationCenter.x - entityCenter.x;
  const dy = relationCenter.y - entityCenter.y;
  let start;
  if (Math.abs(dx) >= Math.abs(dy)) {
    start = { x: dx > 0 ? entityBox.x + conceptualEntityWidth : entityBox.x, y: entityCenter.y };
  } else {
    start = { x: entityCenter.x, y: dy > 0 ? entityBox.y + conceptualEntityHeight : entityBox.y };
  }
  const end = relationCenter;
  const labelX = start.x + (end.x - start.x) * 0.28;
  const labelY = start.y + (end.y - start.y) * 0.28 - 7;
  return `<g><line x1="${start.x}" y1="${start.y}" x2="${end.x}" y2="${end.y}" stroke="#52615C" stroke-width="1.2"${dash}/>${edgeLabelSvg(cardinality, labelX, labelY)}</g>`;
}

function conceptualSvg() {
  const width = 5350;
  const height = 3160;
  const parts = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    '<rect width="100%" height="100%" fill="#FFFFFF"/>',
    '<g font-family="Arial, sans-serif">',
    '<text x="2675" y="40" text-anchor="middle" font-size="26" font-weight="700" fill="#173D35">MODELO CONCEITUAL DO DOMÍNIO AUSTERAGX</text>',
    '<text x="2675" y="68" text-anchor="middle" font-size="14" fill="#49665F">28 entidades · 36 associações JPA · 5 FKs físicas · cardinalidades mínimas e máximas</text>',
  ];

  let coveredRelationships = 0;
  for (const module of conceptualModules) {
    const domain = domains[module.id];
    parts.push(`<g id="conceptual-module-${module.id}">`);
    parts.push(`<rect x="${module.x}" y="${module.y}" width="${module.width}" height="${module.height}" rx="8" fill="#FCFDFD" stroke="${domain.border}" stroke-width="1.5"/>`);
    parts.push(`<rect x="${module.x}" y="${module.y}" width="${module.width}" height="50" rx="8" fill="${domain.fill}" stroke="${domain.border}" stroke-width="1.5"/>`);
    parts.push(`<text x="${module.x + 18}" y="${module.y + 31}" font-size="17" font-weight="700" fill="#273632">${escapeHtml(module.title)}</text>`);

    const boxes = new Map();
    for (const [entityId, coordinates] of Object.entries(module.positions)) {
      const entity = entities.find((candidate) => candidate.id === entityId);
      if (!entity) throw new Error(`Entidade ${entityId} não existe no módulo conceitual ${module.id}.`);
      boxes.set(entityId, { x: module.x + coordinates[0], y: module.y + coordinates[1], entity });
    }

    const moduleRelationships = relationships.slice(module.relationshipStart, module.relationshipEnd);
    coveredRelationships += moduleRelationships.length;
    for (const relation of moduleRelationships) {
      const leftBox = boxes.get(relation.left);
      const rightBox = boxes.get(relation.right);
      const relationCoordinates = module.relationshipPositions[relation.id];
      if (!leftBox || !rightBox || !relationCoordinates) {
        throw new Error(`Módulo ${module.id} não posicionou o relacionamento ${relation.id}.`);
      }
      const relationBox = { x: module.x + relationCoordinates[0], y: module.y + relationCoordinates[1] };
      const selfRelation = relation.left === relation.right;
      const physical = relation.source === 'Flyway';
      parts.push(conceptualArmSvg(leftBox, relationBox, relation.leftCardinality, 0, selfRelation, physical));
      parts.push(conceptualArmSvg(rightBox, relationBox, relation.rightCardinality, 1, selfRelation, physical));
      parts.push(conceptualRelationshipSvg(relation, relationBox.x, relationBox.y));
    }

    for (const box of boxes.values()) {
      parts.push(conceptualEntitySvg(box.entity, box.x, box.y));
    }
    parts.push('</g>');
  }

  if (coveredRelationships !== relationships.length) {
    throw new Error(`A vista conceitual cobriu ${coveredRelationships} de ${relationships.length} relacionamentos.`);
  }

  parts.push('<g id="conceptual-legend">');
  parts.push('<rect x="1280" y="3030" width="2790" height="92" rx="6" fill="#F8FAF9" stroke="#AAB5B1"/>');
  parts.push('<text x="1310" y="3058" font-size="13" font-weight="700" fill="#273632">LEGENDA</text>');
  parts.push('<text x="1310" y="3082" font-size="12" fill="#44514D">Retângulo: entidade · losango: relacionamento · elipse preenchida: PK · elipse vazia: UK</text>');
  parts.push('<text x="1310" y="3105" font-size="12" fill="#44514D">Linha contínua: associação JPA · linha tracejada: FK física de migration · cardinalidade no formato (mínimo, máximo)</text>');
  parts.push('</g></g></svg>');
  return parts.join('');
}

function brModeloGraph() {
  const domainOrder = Object.keys(domains);
  const graphWidth = 4240;
  const panelHeight = 460;
  const panelGap = 70;
  const panelTop = 130;
  const positions = new Map();
  const cells = [];

  cells.push({
    type: 'standard.Rectangle',
    id: 'title',
    position: { x: 40, y: 24 },
    size: { width: graphWidth, height: 46 },
    attrs: { body: { fill: 'none', stroke: 'none' }, label: { text: 'MODELO CONCEITUAL DO DOMÍNIO AUSTERAGX', fontSize: 26, fontWeight: 700, fill: '#173D35' } },
    z: 1,
  });

  domainOrder.forEach((domainId, domainIndex) => {
    const domain = domains[domainId];
    const domainEntities = entities.filter((entity) => entity.domain === domainId);
    const y = panelTop + domainIndex * (panelHeight + panelGap);
    const panelId = `domain:${domainId}`;
    cells.push({
      type: 'standard.Rectangle', id: `${panelId}:panel`, position: { x: 40, y },
      size: { width: graphWidth, height: panelHeight },
      attrs: { body: { fill: '#FFFFFF', stroke: domain.border, strokeWidth: 1.2, rx: 5, ry: 5 }, label: { text: '' } }, z: 0,
    });
    cells.push({
      type: 'standard.Rectangle', id: `${panelId}:header`, position: { x: 40, y },
      size: { width: graphWidth, height: 58 },
      attrs: { body: { fill: domain.fill, stroke: domain.border, strokeWidth: 1.2, rx: 5, ry: 5 }, label: { text: domain.label, fontSize: 17, fontWeight: 700, fill: '#273632' } }, z: 1,
    });

    const spacing = graphWidth / (domainEntities.length + 1);
    domainEntities.forEach((entity, entityIndex) => {
      const x = Math.round(40 + spacing * (entityIndex + 1) - 95);
      const entityY = y + 220;
      positions.set(entity.id, { x, y: entityY });
      cells.push({
        type: 'erd.Entity', id: `entity:${entity.id}`, position: { x, y: entityY },
        size: { width: 190, height: 52 }, attrs: { text: { text: entity.label } }, z: 4,
      });

      const keyName = entity.keyName ?? 'id';
      const keyId = `attribute:${entity.id}:${keyName}`;
      cells.push({
        type: 'erd.Key', id: keyId, position: { x: x + 48, y: entityY - 74 },
        size: { width: 60, height: 30 }, attrs: { text: { text: keyName } }, z: 5,
      });
      cells.push({
        type: 'erd.Link', id: `attribute-link:${entity.id}:${keyName}`, source: { id: keyId }, target: { id: `entity:${entity.id}` },
        vertices: [], labels: [], attrs: { line: { stroke: '#333333', strokeWidth: 1.2 } }, z: 2,
      });

      if (entity.publicId) {
        const publicId = `attribute:${entity.id}:publicId`;
        cells.push({
          type: 'erd.Attribute', id: publicId, position: { x: x + 116, y: entityY - 74 },
          size: { width: 84, height: 30 }, attrs: { text: { text: 'publicId (UK)' } }, z: 5,
        });
        cells.push({
          type: 'erd.Link', id: `attribute-link:${entity.id}:publicId`, source: { id: publicId }, target: { id: `entity:${entity.id}` },
          vertices: [], labels: [], attrs: { line: { stroke: '#333333', strokeWidth: 1.2 } }, z: 2,
        });
      }
    });
  });

  relationships.forEach((relation, index) => {
    const left = positions.get(relation.left);
    const right = positions.get(relation.right);
    const selfRelation = relation.left === relation.right;
    const offset = ((index % 5) - 2) * 32;
    const relationPosition = selfRelation
      ? { x: left.x + 248, y: left.y + 82 + offset }
      : { x: Math.round((left.x + right.x) / 2) + offset, y: Math.round((left.y + right.y) / 2) + offset };
    const relationId = `relation:${relation.id}`;
    const physical = relation.source === 'Flyway';
    cells.push({
      type: 'erd.Relationship', id: relationId, position: relationPosition,
      size: { width: 180, height: 72 }, attrs: { text: { text: relation.name }, body: physical ? { strokeDasharray: '7 5' } : {} }, z: 4,
    });

    const link = (side, entityId, cardinality, labelOffset) => ({
      type: 'erd.Link', id: `link:${relation.id}:${side}`, source: { id: `entity:${entityId}` }, target: { id: relationId },
      vertices: [],
      labels: [{
        position: { distance: 0.28, offset: labelOffset },
        attrs: { text: { text: cardinality.replace('N', 'n'), fill: '#111111', fontFamily: 'Arial', fontSize: 13, fontWeight: 700, stroke: '#FFFFFF', strokeWidth: 5, paintOrder: 'stroke' } },
      }],
      attrs: { line: { stroke: physical ? '#766D82' : '#333333', strokeWidth: 1.3, strokeDasharray: physical ? '7 5' : '' } }, z: 2,
    });

    cells.push(link('left', relation.left, relation.leftCardinality, -18));
    cells.push(link('right', relation.right, relation.rightCardinality, 18));
  });

  return {
    cells,
    metadata: {
      format: 'brModelo Web / JointJS graph',
      source: 'Entidades JPA e migrations Flyway do backend AusterAgX',
      entities: entities.length,
      documentedAttributes: 299,
      conceptualRelationships: relationships.length,
      jpaAssociations: relationships.filter((relation) => relation.source === 'JPA').length,
      physicalForeignKeysAdded: relationships.filter((relation) => relation.source === 'Flyway').length,
      cardinalityNotation: '(mínimo, máximo)',
      audited: true,
    },
  };
}

function cardinalityDocument() {
  const relationshipRows = relationships.map((relation, index) => (
    `| ${String(index + 1).padStart(2, '0')} | \`${relation.left}\` | **${relation.leftCardinality}** | ${relation.name.replaceAll('_', ' ')} | \`${relation.right}\` | **${relation.rightCardinality}** | ${relation.implementation} | ${relation.source} |`
  ));

  const associationRows = associationTables.map((table) => {
    const primaryKeyColumns = table.columns.filter((item) => item.key.includes('PK')).map((item) => `\`${item.name}\``);
    const primaryKey = primaryKeyColumns.length > 0 ? primaryKeyColumns.join(' + ') : 'sem PK composta';
    return `| \`${table.table}\` | ${table.columns.map((item) => `\`${item.name}\``).join(', ')} | ${primaryKey} |`;
  });

  return `# Auditoria de cardinalidades do AusterAgX

Este documento registra a revisão do modelo de dados usado como referência pelo aplicativo mobile. A fonte de verdade foi o mapeamento JPA do backend oficial, complementado pelas migrations Flyway para nulabilidade, unicidade, chaves estrangeiras e tabelas associativas. O backend não foi modificado.

## Escopo validado

- **28 entidades persistentes** do domínio.
- **36 associações JPA** entre entidades.
- **5 relacionamentos físicos adicionais** com \`usuario\`, declarados por FK nas migrations e representados no conceitual com linha tracejada.
- **41 relacionamentos conceituais** no total.
- **35 tabelas lógicas**, sendo 28 entidades e 7 estruturas associativas ou de coleção.
- **48 referências lógicas** por chave estrangeira.

## Notação

| Símbolo | Significado |
|---|---|
| \`(0,1)\` | participação opcional, no máximo uma ocorrência |
| \`(1,1)\` | participação obrigatória, exatamente uma ocorrência |
| \`(0,N)\` | participação opcional, várias ocorrências |

A cardinalidade exibida junto a uma entidade indica quantas ocorrências daquela entidade podem participar para uma ocorrência do lado oposto. Exemplo: \`DEMANDA (0,N) — (1,1) PEDIDO\` significa que um pedido pode possuir zero ou muitas demandas, enquanto cada demanda pertence obrigatoriamente a um único pedido.

## Matriz conceitual auditada

| # | Entidade A | Card. A | Relacionamento | Entidade B | Card. B | Implementação | Fonte |
|---:|---|:---:|---|---|:---:|---|---|
${relationshipRows.join('\n')}

## Tabelas associativas

| Tabela | Colunas de vínculo | Chave primária física |
|---|---|---|
${associationRows.join('\n')}

As tabelas \`demanda_grupo\`, \`grupo_talhao\`, \`fazenda_cultura\` e \`fazenda_equipamento\` não possuem PK composta nas migrations atuais. O modelo preserva essa característica em vez de inventar uma restrição inexistente.

## Regras aplicadas

1. FK com \`NOT NULL\` produz participação \`(1,1)\` no lado referenciado.
2. FK anulável produz participação \`(0,1)\` no lado referenciado.
3. FK com \`UNIQUE\` limita a entidade dependente a \`(0,1)\` para cada registro principal.
4. Coleções JPA e tabelas associativas permanecem \`(0,N)\`; o banco não exige pelo menos um item.
5. IDs de auditoria sem FK, como \`demanda_status_historico.alterado_por_id\` e \`audit_log.entidade_id\`, continuam atributos de snapshot e não viram relacionamentos artificiais.
6. \`cultura_tipo_demanda\` é uma coleção de valores da cultura no modelo lógico, não uma entidade de negócio no conceitual.
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
`;
}

async function renderSvg(svgFileName, pngFileName) {
  const require = createRequire(import.meta.url);
  const configuredPaths = (process.env.ER_TOOL_NODE_MODULES ?? '')
    .split(path.delimiter)
    .filter(Boolean);
  const searchPaths = [...configuredPaths, path.join(repositoryRoot, 'node_modules')];
  let sharpEntry;
  try {
    sharpEntry = require.resolve('sharp', { paths: searchPaths });
  } catch (error) {
    throw new Error('Para usar --render, disponibilize sharp em ER_TOOL_NODE_MODULES.', { cause: error });
  }
  const sharp = require(sharpEntry);
  const svg = fs.readFileSync(path.join(outputDir, svgFileName));
  await sharp(svg, { density: 96, limitInputPixels: false })
    .resize({ width: 6400, withoutEnlargement: true })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(path.join(outputDir, pngFileName));
}

async function main() {
  assertModel();
  fs.mkdirSync(outputDir, { recursive: true });
  fs.writeFileSync(path.join(outputDir, 'auster-agx-conceitual.dot'), conceptualDot(), 'utf8');
  fs.writeFileSync(path.join(outputDir, 'auster-agx-conceitual.svg'), conceptualSvg(), 'utf8');
  fs.writeFileSync(path.join(outputDir, 'auster-agx-logico.dot'), logicalDot(), 'utf8');
  fs.writeFileSync(path.join(outputDir, 'auster-agx-logico.svg'), logicalSvg(), 'utf8');
  fs.writeFileSync(path.join(outputDir, 'auster-agx-brmodelo-web.json'), `${JSON.stringify(brModeloGraph(), null, 2)}\n`, 'utf8');
  fs.writeFileSync(path.join(outputDir, 'auster-agx-cardinalidades.md'), cardinalityDocument(), 'utf8');

  if (process.argv.includes('--render')) {
    await renderSvg('auster-agx-conceitual.svg', 'auster-agx-conceitual.png');
    await renderSvg('auster-agx-logico.svg', 'auster-agx-logico.png');
  }

  console.log(`Modelo validado: ${entities.length} entidades, ${relationships.length} relacionamentos, ${tables.length} tabelas e ${logicalForeignKeys.length} FKs.`);
}

await main();
