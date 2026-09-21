// Diagramas da seção de modelagem do README, na notação visual do brModelo.
//
// Recebe o modelo já validado por gerar-modelos-er.mjs e desenha somente o
// recorte que o aplicativo consome pela API. Posições são fixas para manter o
// traçado estável entre regenerações; o conteúdo (atributos, colunas, chaves e
// cardinalidades) vem sempre do modelo, nunca é redigitado aqui.

const FONTE = "'DejaVu Sans', Verdana, Arial, sans-serif";

// Larguras aproximadas da DejaVu Sans Bold, em frações do em.
const LARGURAS = {
  a: 0.675, b: 0.716, c: 0.593, d: 0.716, e: 0.678, f: 0.435, g: 0.716, h: 0.712,
  i: 0.343, j: 0.343, k: 0.665, l: 0.343, m: 1.042, n: 0.712, o: 0.687, p: 0.716,
  q: 0.716, r: 0.493, s: 0.595, t: 0.478, u: 0.712, v: 0.652, w: 0.924, x: 0.645,
  y: 0.652, z: 0.582, _: 0.5, ' ': 0.348, '(': 0.457, ')': 0.457, ',': 0.38,
  '.': 0.38, '…': 1.0, '-': 0.415,
};

function larguraTexto(texto, tamanho) {
  let total = 0;
  for (const caractere of texto.normalize('NFD').replace(/[̀-ͯ]/g, '')) {
    const minuscula = caractere.toLowerCase();
    const base = LARGURAS[minuscula] ?? 0.696;
    total += caractere !== minuscula ? base * 1.12 : base;
  }
  return total * tamanho;
}

function escapar(valor) {
  return String(valor)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function cardinalidade(valor) {
  return valor.replace('N', 'n');
}

function pontos(lista) {
  return lista.map(([x, y]) => `${x},${y}`).join(' ');
}

// ---------------------------------------------------------------------------
// Recorte
// ---------------------------------------------------------------------------

export const ENTIDADES_DO_RECORTE = [
  'USUARIO',
  'CLIENTE',
  'CLIENTE_FAZENDA',
  'FAZENDA',
  'TALHAO',
  'GRUPO',
  'CULTURA',
  'PEDIDO',
  'DEMANDA',
  'DEMANDA_STATUS_HISTORICO',
  'SENSORIAMENTO_REMOTO',
];

const ASSOCIATIVAS_DO_RECORTE = [
  'grupo_talhao',
  'fazenda_cultura',
  'demanda_grupo',
  'demanda_sensoriamento_remoto',
];

function entidadesDoRecorte(entities) {
  const porId = new Map(entities.map((entidade) => [entidade.id, entidade]));
  return ENTIDADES_DO_RECORTE.map((id) => {
    const entidade = porId.get(id);
    if (!entidade) throw new Error(`Entidade ${id} do recorte não existe no modelo.`);
    return entidade;
  });
}

// ---------------------------------------------------------------------------
// Modelo conceitual (MER, notação de Chen do brModelo)
// ---------------------------------------------------------------------------

const MER = {
  alturaEntidade: 56,
  larguraMinima: 132,
  passoLinha: 8,
  passoAtributo: 19,
  raio: 6.5,
  alturaLosango: 44,
  fonteEntidade: 13,
  fonteAtributo: 12,
  fonteRelacionamento: 12,
  fonteCardinalidade: 12,
};

// Posição (canto superior esquerdo) de cada entidade e lado dos atributos.
const LAYOUT_MER = {
  USUARIO: { x: 60, y: 240, atributos: 'acima' },
  CLIENTE: { x: 420, y: 240, atributos: 'acima' },
  PEDIDO: { x: 780, y: 240, atributos: 'acima' },
  DEMANDA: { x: 1140, y: 240, atributos: 'acima', largura: 150 },
  DEMANDA_STATUS_HISTORICO: { x: 1500, y: 240, atributos: 'acima' },
  CLIENTE_FAZENDA: { x: 160, y: 440, atributos: 'acima' },
  CULTURA: { x: 60, y: 640, atributos: 'abaixo' },
  FAZENDA: { x: 420, y: 640, atributos: 'abaixo' },
  TALHAO: { x: 780, y: 640, atributos: 'abaixo' },
  GRUPO: { x: 1140, y: 640, atributos: 'abaixo' },
  SENSORIAMENTO_REMOTO: { x: 1500, y: 640, atributos: 'abaixo' },
};

function geometriaEntidades(entidades) {
  const caixas = new Map();
  for (const entidade of entidades) {
    const layout = LAYOUT_MER[entidade.id];
    if (!layout) throw new Error(`Sem posição no MER para ${entidade.id}.`);
    const largura = Math.max(
      layout.largura ?? 0,
      MER.larguraMinima,
      Math.ceil(larguraTexto(entidade.table, MER.fonteEntidade) + 44),
    );
    caixas.set(entidade.id, {
      ...layout,
      largura,
      altura: MER.alturaEntidade,
      entidade,
    });
  }
  return caixas;
}

function atributosConceituais(entidade) {
  return entidade.columns
    .filter((coluna) => coluna.name !== '...' && !coluna.key.includes('FK'))
    .map((coluna) => ({
      nome: coluna.name.replaceAll('_', ' '),
      identificador: coluna.key.includes('PK'),
    }));
}

function losango(cx, cy, nome) {
  const largura = Math.ceil(larguraTexto(nome, MER.fonteRelacionamento) + 56);
  const meia = largura / 2;
  const altura = MER.alturaLosango / 2;
  return {
    cx,
    cy,
    largura,
    vertices: {
      left: [cx - meia, cy],
      right: [cx + meia, cy],
      top: [cx, cy - altura],
      bottom: [cx, cy + altura],
    },
    svg: [
      `<polygon points="${pontos([[cx, cy - altura], [cx + meia, cy], [cx, cy + altura], [cx - meia, cy]])}" class="losango"/>`,
      `<text x="${cx}" y="${cy + 4.5}" class="relacionamento">${escapar(nome)}</text>`,
    ].join(''),
  };
}

// Rótulo de cardinalidade junto à entidade, conforme a direção da perna.
function rotuloCardinalidade(inicio, proximo, texto, lado = 'direita') {
  const [x, y] = inicio;
  const [nx, ny] = proximo;
  if (ny === y) {
    const paraDireita = nx > x;
    return `<text x="${paraDireita ? x + 7 : x - 7}" y="${y - 7}" class="cardinalidade" text-anchor="${paraDireita ? 'start' : 'end'}">${escapar(texto)}</text>`;
  }
  const paraBaixo = ny > y;
  const xTexto = lado === 'esquerda' ? x - 7 : x + 7;
  const ancora = lado === 'esquerda' ? 'end' : 'start';
  return `<text x="${xTexto}" y="${paraBaixo ? y + 17 : y - 8}" class="cardinalidade" text-anchor="${ancora}">${escapar(texto)}</text>`;
}

function perna(pontosPerna, textoCardinalidade, lado) {
  return [
    `<polyline points="${pontos(pontosPerna)}" class="linha"/>`,
    rotuloCardinalidade(pontosPerna[0], pontosPerna[1], textoCardinalidade, lado),
  ].join('');
}

function relacionamentosMer(caixas, relationships) {
  const doRecorte = relationships.filter(
    (relacao) => caixas.has(relacao.left) && caixas.has(relacao.right),
  );
  const c = (id) => caixas.get(id);
  const meio = (caixa) => caixa.y + caixa.altura / 2;
  const svg = [];
  const desenhados = new Set();

  const buscar = (id, esquerda, direita) => {
    const relacao = doRecorte.find((item) => item.id === id);
    if (!relacao) throw new Error(`Relacionamento ${id} não encontrado no recorte.`);
    if (relacao.left !== esquerda || relacao.right !== direita) {
      throw new Error(`Relacionamento ${id} mudou de extremidades: ${relacao.left} x ${relacao.right}.`);
    }
    desenhados.add(id);
    return relacao;
  };

  // Relacionamentos horizontais entre entidades vizinhas na mesma linha.
  const horizontal = (id, nome, entidadeEsquerda, entidadeDireita, cardEsquerda, cardDireita) => {
    const a = c(entidadeEsquerda);
    const b = c(entidadeDireita);
    const y = meio(a);
    const inicio = [a.x + a.largura, y];
    const fim = [b.x, y];
    const forma = losango((inicio[0] + fim[0]) / 2, y, nome);
    svg.push(perna([inicio, forma.vertices.left], cardEsquerda));
    svg.push(perna([fim, forma.vertices.right], cardDireita));
    svg.push(forma.svg);
  };

  let r = buscar('R01', 'CLIENTE', 'USUARIO');
  horizontal('R01', 'administra', 'USUARIO', 'CLIENTE', cardinalidade(r.rightCardinality), cardinalidade(r.leftCardinality));
  r = buscar('R19', 'PEDIDO', 'CLIENTE');
  horizontal('R19', 'solicita', 'CLIENTE', 'PEDIDO', cardinalidade(r.rightCardinality), cardinalidade(r.leftCardinality));
  r = buscar('R20', 'DEMANDA', 'PEDIDO');
  horizontal('R20', 'compõe', 'PEDIDO', 'DEMANDA', cardinalidade(r.rightCardinality), cardinalidade(r.leftCardinality));
  r = buscar('R17', 'FAZENDA', 'CULTURA');
  horizontal('R17', 'cultiva', 'CULTURA', 'FAZENDA', cardinalidade(r.rightCardinality), cardinalidade(r.leftCardinality));
  r = buscar('R09', 'TALHAO', 'FAZENDA');
  horizontal('R09', 'contém', 'FAZENDA', 'TALHAO', cardinalidade(r.rightCardinality), cardinalidade(r.leftCardinality));
  r = buscar('R10', 'GRUPO', 'TALHAO');
  horizontal('R10', 'agrupa', 'TALHAO', 'GRUPO', cardinalidade(r.rightCardinality), cardinalidade(r.leftCardinality));

  // DEMANDA -> DEMANDA_STATUS_HISTORICO: sai acima do meio para liberar o autorrelacionamento.
  {
    r = buscar('R25', 'DEMANDA_STATUS_HISTORICO', 'DEMANDA');
    const a = c('DEMANDA');
    const b = c('DEMANDA_STATUS_HISTORICO');
    const y = a.y + 16;
    const inicio = [a.x + a.largura, y];
    const fim = [b.x, y];
    const forma = losango((inicio[0] + fim[0]) / 2, y, 'registra');
    svg.push(perna([inicio, forma.vertices.left], cardinalidade(r.rightCardinality)));
    svg.push(perna([fim, forma.vertices.right], cardinalidade(r.leftCardinality)));
    svg.push(forma.svg);
  }

  // CLIENTE x FAZENDA (proprietária), vertical.
  {
    r = buscar('R07', 'FAZENDA', 'CLIENTE');
    const cliente = c('CLIENTE');
    const fazenda = c('FAZENDA');
    const x = cliente.x + 100;
    const forma = losango(x, 468, 'possui');
    svg.push(perna([[x, cliente.y + cliente.altura], forma.vertices.top], cardinalidade(r.rightCardinality)));
    svg.push(perna([[x, fazenda.y], forma.vertices.bottom], cardinalidade(r.leftCardinality)));
    svg.push(forma.svg);
  }

  // CLIENTE_FAZENDA (vínculo contratual) com CLIENTE e com FAZENDA.
  {
    const vinculo = c('CLIENTE_FAZENDA');
    const cliente = c('CLIENTE');
    const fazenda = c('FAZENDA');
    const xLosango = 378;
    const xEntrada = cliente.x + 30;
    const direitaVinculo = vinculo.x + vinculo.largura;

    r = buscar('R02', 'CLIENTE_FAZENDA', 'CLIENTE');
    let forma = losango(xLosango, 362, 'vincula');
    svg.push(perna([[direitaVinculo, vinculo.y + 14], [xLosango, vinculo.y + 14], forma.vertices.bottom], cardinalidade(r.leftCardinality)));
    svg.push(perna([[xEntrada, cliente.y + cliente.altura], [xEntrada, forma.cy], forma.vertices.right], cardinalidade(r.rightCardinality)));
    svg.push(forma.svg);

    r = buscar('R03', 'CLIENTE_FAZENDA', 'FAZENDA');
    forma = losango(xLosango, 572, 'vincula');
    svg.push(perna([[direitaVinculo, vinculo.y + 42], [xLosango, vinculo.y + 42], forma.vertices.top], cardinalidade(r.leftCardinality)));
    svg.push(perna([[xEntrada, fazenda.y], [xEntrada, forma.cy], forma.vertices.right], cardinalidade(r.rightCardinality)));
    svg.push(forma.svg);
  }

  // DEMANDA x GRUPO (N:N), vertical.
  {
    r = buscar('R23', 'DEMANDA', 'GRUPO');
    const demanda = c('DEMANDA');
    const grupo = c('GRUPO');
    const x = demanda.x + 14;
    const forma = losango(x, 468, 'abrange');
    svg.push(perna([[x, demanda.y + demanda.altura], forma.vertices.top], cardinalidade(r.leftCardinality), 'esquerda'));
    svg.push(perna([[x, grupo.y], forma.vertices.bottom], cardinalidade(r.rightCardinality), 'esquerda'));
    svg.push(forma.svg);
  }

  // DEMANDA x SENSORIAMENTO_REMOTO (N:N).
  {
    r = buscar('R24', 'DEMANDA', 'SENSORIAMENTO_REMOTO');
    const demanda = c('DEMANDA');
    const sensoriamento = c('SENSORIAMENTO_REMOTO');
    const xSaida = demanda.x + 74;
    const y = 520;
    const forma = losango(1420, y, 'utiliza');
    const xEntrada = sensoriamento.x + 40;
    svg.push(perna([[xSaida, demanda.y + demanda.altura], [xSaida, y], forma.vertices.left], cardinalidade(r.leftCardinality)));
    svg.push(perna([[xEntrada, sensoriamento.y], [xEntrada, y], forma.vertices.right], cardinalidade(r.rightCardinality)));
    svg.push(forma.svg);
  }

  // Autorrelacionamento de DEMANDA (retrabalho).
  {
    r = buscar('R21', 'DEMANDA', 'DEMANDA');
    const demanda = c('DEMANDA');
    const forma = losango(1360, 396, 'retrabalho');
    const xBase = demanda.x + demanda.largura - 16;
    svg.push(perna([[xBase, demanda.y + demanda.altura], [xBase, forma.cy], forma.vertices.left], cardinalidade(r.leftCardinality)));
    svg.push(perna([[demanda.x + demanda.largura, demanda.y + 44], [forma.cx, demanda.y + 44], forma.vertices.top], cardinalidade(r.rightCardinality)));
    svg.push(forma.svg);
  }

  // Autorrelacionamento de SENSORIAMENTO_REMOTO (remapeamento).
  {
    r = buscar('R27', 'SENSORIAMENTO_REMOTO', 'SENSORIAMENTO_REMOTO');
    const sensoriamento = c('SENSORIAMENTO_REMOTO');
    const direita = sensoriamento.x + sensoriamento.largura;
    const forma = losango(direita + 74, sensoriamento.y + 120, 'deriva');
    svg.push(perna([[direita, sensoriamento.y + 14], [forma.cx, sensoriamento.y + 14], forma.vertices.top], cardinalidade(r.leftCardinality)));
    svg.push(perna([[direita, sensoriamento.y + 42], [direita + 14, sensoriamento.y + 42], [direita + 14, forma.cy], forma.vertices.left], cardinalidade(r.rightCardinality)));
    svg.push(forma.svg);
  }

  const faltando = doRecorte.filter((relacao) => !desenhados.has(relacao.id)).map((relacao) => relacao.id);
  if (faltando.length > 0) {
    throw new Error(`Relacionamentos do recorte sem traçado no MER: ${faltando.join(', ')}.`);
  }
  return { svg: svg.join('\n'), total: desenhados.size };
}

function entidadeMer(caixa) {
  const { x, y, largura, altura, entidade, atributos: lado } = caixa;
  const atributos = atributosConceituais(entidade);
  const n = atributos.length;
  const partes = [];

  atributos.forEach((atributo, i) => {
    // Acima: o primeiro atributo fica no topo e na linha mais à esquerda.
    // Abaixo: o primeiro fica junto da entidade, na linha mais à direita.
    // Nos dois casos nenhum rótulo cruza as linhas dos demais atributos.
    let xLinha;
    let yCirculo;
    let yBorda;
    if (lado === 'acima') {
      xLinha = x + 12 + i * MER.passoLinha;
      yCirculo = y - 22 - (n - 1 - i) * MER.passoAtributo;
      yBorda = y;
    } else {
      xLinha = x + 12 + (n - 1 - i) * MER.passoLinha;
      yCirculo = y + altura + 22 + i * MER.passoAtributo;
      yBorda = y + altura;
    }
    const pontoFim = lado === 'acima' ? yCirculo + MER.raio : yCirculo - MER.raio;
    partes.push(`<line x1="${xLinha}" y1="${yBorda}" x2="${xLinha}" y2="${pontoFim}" class="linha"/>`);
    partes.push(`<circle cx="${xLinha}" cy="${yCirculo}" r="${MER.raio}" class="${atributo.identificador ? 'identificador' : 'atributo'}"/>`);
    partes.push(`<text x="${xLinha + MER.raio + 5}" y="${yCirculo + 4.5}" class="nome-atributo">${escapar(atributo.nome)}</text>`);
  });

  partes.push(`<rect x="${x}" y="${y}" width="${largura}" height="${altura}" class="entidade"/>`);
  partes.push(`<text x="${x + largura / 2}" y="${y + altura / 2 + 5}" class="nome-entidade">${escapar(entidade.table)}</text>`);
  return partes.join('\n');
}

export function conceptualReadmeSvg({ entities, relationships }) {
  const entidades = entidadesDoRecorte(entities);
  const caixas = geometriaEntidades(entidades);
  const relacionamentos = relacionamentosMer(caixas, relationships);
  const largura = 1880;
  const altura = 880;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${largura}" height="${altura}" viewBox="0 0 ${largura} ${altura}" role="img" aria-labelledby="titulo descricao">
<title id="titulo">Modelo conceitual (MER) do AusterAgX Mobile</title>
<desc id="descricao">Notação de Chen no padrão do brModelo: ${entidades.length} entidades e ${relacionamentos.total} relacionamentos do subdomínio consumido pelo aplicativo.</desc>
<style>
  .linha { fill: none; stroke: #000; stroke-width: 1.1; }
  .entidade { fill: #fff; stroke: #000; stroke-width: 1.1; }
  .losango { fill: #fff; stroke: #000; stroke-width: 1.1; }
  .atributo { fill: #fff; stroke: #000; stroke-width: 1.1; }
  .identificador { fill: #000; stroke: #000; stroke-width: 1.1; }
  text { font-family: ${FONTE}; font-weight: bold; fill: #000; }
  .nome-entidade { font-size: ${MER.fonteEntidade}px; text-anchor: middle; }
  .nome-atributo { font-size: ${MER.fonteAtributo}px; }
  .relacionamento { font-size: ${MER.fonteRelacionamento}px; text-anchor: middle; }
  .cardinalidade { font-size: ${MER.fonteCardinalidade}px; }
</style>
<rect width="100%" height="100%" fill="#fff"/>
${relacionamentos.svg}
${[...caixas.values()].map(entidadeMer).join('\n')}
</svg>
`;
  return svg;
}

// ---------------------------------------------------------------------------
// Modelo lógico (DER, estilo do modelo lógico do brModelo)
// ---------------------------------------------------------------------------

const DER = {
  largura: 232,
  cabecalho: 28,
  linha: 22,
  rodape: 24,
  folga: 8,
  fonteTitulo: 13,
  fonteColuna: 11.5,
  fonteCardinalidade: 12,
};

const COLUNAS_DER = [40, 404, 768, 1132, 1496];
const LINHAS_DER = [40, 470, 840];

const LAYOUT_DER = {
  usuario: [0, 0],
  cliente: [1, 0],
  pedido: [2, 0],
  demanda: [3, 0],
  demanda_status_historico: [4, 0],
  cliente_fazenda: [0, 1],
  fazenda: [1, 1],
  talhao: [2, 1],
  demanda_grupo: [3, 1],
  demanda_sensoriamento_remoto: [4, 1],
  cultura: [0, 2],
  fazenda_cultura: [1, 2],
  grupo_talhao: [2, 2],
  grupo: [3, 2],
  sensoriamento_remoto: [4, 2],
};

function posicaoDer(nome) {
  const [coluna, linha] = LAYOUT_DER[nome];
  return [COLUNAS_DER[coluna], LINHAS_DER[linha]];
}

function larguraTabela(tabela) {
  const titulo = larguraTexto(tabela.table, DER.fonteTitulo) + 40;
  const colunas = Math.max(
    ...tabela.columns.map((coluna) =>
      coluna.name === '...'
        ? larguraTexto(`… ${coluna.type}`, DER.fonteColuna - 0.5) * 0.92 + 44
        : larguraTexto(coluna.name, DER.fonteColuna) + 52,
    ),
  );
  return Math.ceil(Math.max(DER.largura, titulo, colunas));
}

function alturaTabela(tabela) {
  return DER.cabecalho + DER.folga + tabela.columns.length * DER.linha + 4 + DER.rodape;
}

function iconeChave(x, y, cor) {
  // Chave pequena: argola + haste + dentes, no estilo dos ícones do brModelo.
  return `<g transform="translate(${x},${y})" fill="${cor}" stroke="${cor}"><circle cx="0" cy="-3" r="3.2" stroke-width="1.2" fill="none"/><rect x="-0.9" y="0" width="1.8" height="8" stroke="none"/><rect x="0.9" y="4.2" width="2.6" height="1.6" stroke="none"/><rect x="0.9" y="6.6" width="2" height="1.4" stroke="none"/></g>`;
}

function tabelaDer(tabela) {
  const [x, y] = posicaoDer(tabela.table);
  const altura = alturaTabela(tabela);
  const largura = larguraTabela(tabela);
  const idGradiente = `g-${tabela.table}`;
  const partes = [];
  partes.push(`<g filter="url(#sombra)">`);
  partes.push(`<rect x="${x}" y="${y}" width="${largura}" height="${altura}" rx="9" class="corpo"/>`);
  partes.push(`</g>`);
  partes.push(`<defs><linearGradient id="${idGradiente}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#c2c2c2"/><stop offset="1" stop-color="#d9d9d9"/></linearGradient></defs>`);
  partes.push(`<path d="M${x},${y + 9} a9,9 0 0 1 9,-9 h${largura - 18} a9,9 0 0 1 9,9 v${DER.cabecalho - 9} h-${largura} z" fill="url(#${idGradiente})"/>`);
  partes.push(`<line x1="${x}" y1="${y + DER.cabecalho}" x2="${x + largura}" y2="${y + DER.cabecalho}" class="divisoria"/>`);
  partes.push(`<text x="${x + largura / 2}" y="${y + 19}" class="titulo">${escapar(tabela.table)}</text>`);

  tabela.columns.forEach((coluna, i) => {
    const yLinha = y + DER.cabecalho + DER.folga + i * DER.linha + 15;
    if (coluna.name === '...') {
      partes.push(`<text x="${x + 30}" y="${yLinha}" class="resumo">… ${escapar(coluna.type)}</text>`);
      return;
    }
    const chave = coluna.key;
    if (chave.includes('FK')) partes.push(iconeChave(x + 16, yLinha - 6, '#2e8b2e'));
    else if (chave.includes('PK')) partes.push(iconeChave(x + 16, yLinha - 6, '#111'));
    partes.push(`<text x="${x + 30}" y="${yLinha}" class="coluna">${escapar(coluna.name)}</text>`);
  });

  const yRodape = y + altura - DER.rodape;
  partes.push(`<line x1="${x}" y1="${yRodape}" x2="${x + largura}" y2="${yRodape}" class="divisoria"/>`);
  const temPk = tabela.columns.some((coluna) => coluna.key.includes('PK'));
  const temFk = tabela.columns.some((coluna) => coluna.key.includes('FK'));
  let xIcone = x + 12;
  if (temPk) {
    partes.push(`<g transform="translate(${xIcone},${yRodape + 12}) rotate(-90)">${iconeChave(0, 0, '#111').replace(/<g transform="translate\(0,0\)"/, '<g')}</g>`);
    partes.push(`<rect x="${xIcone + 7}" y="${yRodape + 10}" width="6" height="3" fill="#e0a100"/>`);
    xIcone += 26;
  }
  if (temFk) {
    partes.push(`<line x1="${xIcone - 6}" y1="${yRodape}" x2="${xIcone - 6}" y2="${y + altura}" class="divisoria"/>`);
    partes.push(`<g transform="translate(${xIcone + 2},${yRodape + 12}) rotate(-90)">${iconeChave(0, 0, '#2e8b2e').replace(/<g transform="translate\(0,0\)"/, '<g')}</g>`);
  }
  return { svg: partes.join('\n'), caixa: { x, y, largura, altura } };
}

function seta(ponta, direcao) {
  // Seta aberta na ponta da tabela filha, como no brModelo.
  const [x, y] = ponta;
  const t = 7;
  const a = 4;
  const mapa = {
    left: [[x + t, y - a], [x, y], [x + t, y + a]],
    right: [[x - t, y - a], [x, y], [x - t, y + a]],
    up: [[x - a, y + t], [x, y], [x + a, y + t]],
    down: [[x - a, y - t], [x, y], [x + a, y - t]],
  };
  return `<polyline points="${pontos(mapa[direcao])}" class="linha-der"/>`;
}

function direcaoChegada(anterior, ponta) {
  const [ax, ay] = anterior;
  const [px, py] = ponta;
  if (ay === py) return px < ax ? 'left' : 'right';
  return py < ay ? 'up' : 'down';
}

function rotuloDer(ponta, proximo, texto, abaixo = false) {
  const [x, y] = ponta;
  const [nx, ny] = proximo;
  if (ny === y) {
    const paraDireita = nx > x;
    if (Math.abs(nx - x) < 50) {
      // Perna curta de autorrelacionamento: o rótulo vai depois da dobra.
      return `<text x="${nx + 7}" y="${y + 4.5}" class="cardinalidade" text-anchor="start">${escapar(texto)}</text>`;
    }
    const yTexto = abaixo ? y + 17 : y - 7;
    return `<text x="${paraDireita ? x + 10 : x - 10}" y="${yTexto}" class="cardinalidade" text-anchor="${paraDireita ? 'start' : 'end'}">${escapar(texto)}</text>`;
  }
  const paraBaixo = ny > y;
  return `<text x="${x + 8}" y="${paraBaixo ? y + 18 : y - 9}" class="cardinalidade" text-anchor="start">${escapar(texto)}</text>`;
}

// Traçado de cada FK: pontos da tabela filha até a tabela referenciada.
function tracadosDer(caixas) {
  const k = (nome) => caixas.get(nome);
  const direita = (nome) => k(nome).x + k(nome).largura;
  const base = (nome) => k(nome).y + k(nome).altura;
  return {
    'cliente.usuario_id': [[k('cliente').x, 110], [direita('usuario'), 110]],
    'pedido.cliente_id': [[k('pedido').x, 110], [direita('cliente'), 110]],
    'demanda.pedido_id': [[k('demanda').x, 110], [direita('pedido'), 110]],
    'demanda_status_historico.demanda_id': [[k('demanda_status_historico').x, 110], [direita('demanda'), 110]],
    'demanda.demanda_origem_id': [[direita('demanda'), 196], [direita('demanda') + 30, 196], [direita('demanda') + 30, 150], [direita('demanda'), 150]],
    'cliente_fazenda.cliente_id': [[k('cliente_fazenda').x + 170, k('cliente_fazenda').y], [k('cliente_fazenda').x + 170, 420], [k('cliente').x + 40, 420], [k('cliente').x + 40, base('cliente')]],
    'cliente_fazenda.fazenda_id': [[direita('cliente_fazenda'), 560], [k('fazenda').x, 560]],
    'fazenda.cliente_proprietario_id': [[k('fazenda').x + 150, k('fazenda').y], [k('fazenda').x + 150, base('cliente')]],
    'talhao.fazenda_id': [[k('talhao').x, 560], [direita('fazenda'), 560]],
    'fazenda_cultura.fazenda_id': [[k('fazenda_cultura').x + 116, k('fazenda_cultura').y], [k('fazenda_cultura').x + 116, base('fazenda')]],
    'fazenda_cultura.cultura_id': [[k('fazenda_cultura').x, 900], [direita('cultura'), 900]],
    'grupo_talhao.talhao_id': [[k('grupo_talhao').x + 116, k('grupo_talhao').y], [k('grupo_talhao').x + 116, base('talhao')]],
    'grupo_talhao.grupo_id': [[direita('grupo_talhao'), 900], [k('grupo').x, 900]],
    'demanda_grupo.demanda_id': [[k('demanda_grupo').x + 116, k('demanda_grupo').y], [k('demanda_grupo').x + 116, base('demanda')]],
    'demanda_grupo.grupo_id': [[k('demanda_grupo').x + 116, base('demanda_grupo')], [k('demanda_grupo').x + 116, k('grupo').y]],
    'demanda_sensoriamento_remoto.demanda_id': [[k('demanda_sensoriamento_remoto').x + 40, k('demanda_sensoriamento_remoto').y], [k('demanda_sensoriamento_remoto').x + 40, 440], [k('demanda').x + 190, 440], [k('demanda').x + 190, base('demanda')]],
    'demanda_sensoriamento_remoto.sensoriamento_remoto_id': [[k('demanda_sensoriamento_remoto').x + 116, base('demanda_sensoriamento_remoto')], [k('demanda_sensoriamento_remoto').x + 116, k('sensoriamento_remoto').y]],
    'sensoriamento_remoto.mapeamento_origem_id': [[direita('sensoriamento_remoto'), 990], [direita('sensoriamento_remoto') + 30, 990], [direita('sensoriamento_remoto') + 30, 940], [direita('sensoriamento_remoto'), 940]],
  };
}

export function logicalReadmeSvg({ entities, associationTables, logicalForeignKeys }) {
  const entidades = entidadesDoRecorte(entities);
  const associativas = ASSOCIATIVAS_DO_RECORTE.map((nome) => {
    const tabela = associationTables.find((item) => item.table === nome);
    if (!tabela) throw new Error(`Tabela associativa ${nome} não existe no modelo.`);
    return tabela;
  });
  const tabelas = [...entidades, ...associativas];
  const nomes = new Set(tabelas.map((tabela) => tabela.table));

  const desenhadas = tabelas.map((tabela) => {
    if (!LAYOUT_DER[tabela.table]) throw new Error(`Sem posição no DER para ${tabela.table}.`);
    return { tabela, ...tabelaDer(tabela) };
  });
  const caixas = new Map(desenhadas.map((item) => [item.tabela.table, item.caixa]));
  const tracados = tracadosDer(caixas);

  const fks = logicalForeignKeys.filter((fk) => nomes.has(fk.child) && nomes.has(fk.parent));
  const ligacoes = [];
  const usados = new Set();
  for (const fk of fks) {
    const chave = `${fk.child}.${fk.columnName}`;
    const trajeto = tracados[chave];
    if (!trajeto) throw new Error(`FK ${chave} sem traçado no DER.`);
    usados.add(chave);
    const inicio = trajeto[0];
    const fim = trajeto[trajeto.length - 1];
    ligacoes.push(`<polyline points="${pontos(trajeto)}" class="linha-der"/>`);
    ligacoes.push(seta(inicio, direcaoChegada(trajeto[1], inicio)));
    ligacoes.push(rotuloDer(inicio, trajeto[1], cardinalidade(fk.childCardinality)));
    ligacoes.push(rotuloDer(fim, trajeto[trajeto.length - 2], cardinalidade(fk.parentCardinality), true));
  }
  const sobrando = Object.keys(tracados).filter((chave) => !usados.has(chave));
  if (sobrando.length > 0) {
    throw new Error(`Traçados sem FK correspondente no modelo: ${sobrando.join(', ')}.`);
  }

  const largura = Math.max(...desenhadas.map(({ caixa }) => caixa.x + caixa.largura)) + 90;
  const altura = Math.max(...desenhadas.map(({ caixa }) => caixa.y + caixa.altura)) + 40;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${largura}" height="${altura}" viewBox="0 0 ${largura} ${altura}" role="img" aria-labelledby="titulo descricao">
<title id="titulo">Modelo lógico (DER) do AusterAgX Mobile</title>
<desc id="descricao">Estilo do modelo lógico do brModelo: ${tabelas.length} tabelas e ${fks.length} chaves estrangeiras do subdomínio consumido pelo aplicativo.</desc>
<defs>
  <filter id="sombra" x="-5%" y="-5%" width="110%" height="110%"><feDropShadow dx="0" dy="1" stdDeviation="1.2" flood-color="#000" flood-opacity="0.18"/></filter>
</defs>
<style>
  .corpo { fill: #f7f7f7; stroke: #a8a8a8; stroke-width: 1; }
  .divisoria { stroke: #c8c8c8; stroke-width: 1; }
  .linha-der { fill: none; stroke: #111; stroke-width: 1.1; }
  text { font-family: ${FONTE}; font-weight: bold; fill: #1c1c1c; }
  .titulo { font-size: ${DER.fonteTitulo}px; text-anchor: middle; }
  .coluna { font-size: ${DER.fonteColuna}px; }
  .resumo { font-size: ${DER.fonteColuna - 0.5}px; font-weight: normal; font-style: italic; fill: #6b6b6b; }
  .cardinalidade { font-size: ${DER.fonteCardinalidade}px; fill: #000; }
</style>
<rect width="100%" height="100%" fill="#fff"/>
${ligacoes.join('\n')}
${desenhadas.map((item) => item.svg).join('\n')}
</svg>
`;
}
