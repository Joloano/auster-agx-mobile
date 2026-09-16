const statusDemandaLabels = {
  'LISTADA': 'Listada',
  'AGENDADA': 'Agendada',
  'LIBERADO_PARA_PRESCRICAO': 'Liberado para prescrição',
  'PREPARACAO_DE_DADOS': 'Preparação de dados',
  'PRESCRICAO_EM_ANDAMENTO': 'Prescrição em andamento',
  'PRESCRICAO_EM_REVISAO': 'Prescrição em revisão',
  'LIBERADO_PARA_ENTREGA': 'Liberado para a entrega',
  'ENTREGUE': 'Entregue',
  'CANCELADA': 'Cancelada',
};

const situacaoDadosLabels = {
  'DADOS_INCOMPLETOS': 'Dados incompletos',
  'DADOS_PREENCHIDOS': 'Dados preenchidos',
};

const situacaoDadosValues = ['DADOS_INCOMPLETOS', 'DADOS_PREENCHIDOS'];

const situacaoMapeamentoLabels = {
  'SEM_IMAGENS': 'Sem imagens',
  'AGENDADO': 'Agendado',
  'EM_ANDAMENTO': 'Em andamento',
  'IMAGENS_DISPONIVEIS': 'Imagens disponíveis',
};

const situacaoMapeamentoValues = [
  'SEM_IMAGENS',
  'AGENDADO',
  'EM_ANDAMENTO',
  'IMAGENS_DISPONIVEIS',
];

const tipoDemandaLabels = {
  'SMART_N': 'Smart-N',
  'SMART_BRAKE': 'Smart-Brake',
  'SMART_SEEDING': 'Smart-Seeding',
};

const grupoOperacionalLabels = {
  'LISTADA': 'Listada',
  'A_SEGUIR': 'A seguir',
  'COLETA_DE_DADOS': 'Coleta de dados',
  'ANDAMENTO': 'Andamento',
  'ENTREGUE': 'Entregue',
  'CANCELADA': 'Cancelada',
};

const grupoOperacionalOrder = [
  'LISTADA',
  'A_SEGUIR',
  'COLETA_DE_DADOS',
  'ANDAMENTO',
  'ENTREGUE',
  'CANCELADA',
];

const statusDemandaGrupo = {
  'LISTADA': 'LISTADA',
  'AGENDADA': 'A_SEGUIR',
  'LIBERADO_PARA_PRESCRICAO': 'ANDAMENTO',
  'PREPARACAO_DE_DADOS': 'ANDAMENTO',
  'PRESCRICAO_EM_ANDAMENTO': 'ANDAMENTO',
  'PRESCRICAO_EM_REVISAO': 'ANDAMENTO',
  'LIBERADO_PARA_ENTREGA': 'ANDAMENTO',
  'ENTREGUE': 'ENTREGUE',
  'CANCELADA': 'CANCELADA',
};

class StatusFluxo {
  const StatusFluxo({
    required this.ordem,
    required this.transicoesValidas,
    required this.exigeDadosPreenchidos,
    required this.exigeMapeamentoConcluido,
  });

  factory StatusFluxo.fromJson(Map<String, dynamic> json) {
    final rawTransitions =
        json['transicoesValidas'] as Map<String, dynamic>? ?? const {};
    return StatusFluxo(
      ordem: _stringList(json['ordem']),
      transicoesValidas: rawTransitions.map(
        (key, value) => MapEntry(key, _stringList(value)),
      ),
      exigeDadosPreenchidos: _stringList(json['exigeDadosPreenchidos']),
      exigeMapeamentoConcluido: _stringList(json['exigeMapeamentoConcluido']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ordem': ordem,
        'transicoesValidas': transicoesValidas,
        'exigeDadosPreenchidos': exigeDadosPreenchidos,
        'exigeMapeamentoConcluido': exigeMapeamentoConcluido,
      };

  final List<String> ordem;
  final Map<String, List<String>> transicoesValidas;
  final List<String> exigeDadosPreenchidos;
  final List<String> exigeMapeamentoConcluido;
}

class IndicadoresPainel {
  const IndicadoresPainel({
    required this.mapeamentoConcluido,
    required this.dadosPreenchidos,
    required this.liberadoParaPrescricao,
  });

  final bool mapeamentoConcluido;
  final bool dadosPreenchidos;
  final bool liberadoParaPrescricao;
}

String statusDemandaLabel(String status) =>
    statusDemandaLabels[status] ?? status;

String situacaoDadosLabel(String situacao) =>
    situacaoDadosLabels[situacao] ?? situacao;

String situacaoMapeamentoLabel(String situacao) =>
    situacaoMapeamentoLabels[situacao] ?? situacao;

String tipoDemandaLabel(String tipo) => tipoDemandaLabels[tipo] ?? tipo;

String grupoOperacionalLabel(String grupo) =>
    grupoOperacionalLabels[grupo] ?? grupo;

String grupoDaDemanda({
  required String status,
  required String situacaoMapeamento,
}) {
  final grupo = statusDemandaGrupo[status] ?? status;
  if (grupo == 'A_SEGUIR' && situacaoMapeamento != 'SEM_IMAGENS') {
    return 'COLETA_DE_DADOS';
  }
  return grupo;
}

bool demandaSemMapeamento(
    {required String tipo, required String? metodoMapeamento}) {
  return tipo == 'SMART_SEEDING' || metodoMapeamento == null;
}

List<String> proximosStatusValidos({
  required String status,
  required String situacaoDados,
  required String situacaoMapeamento,
  required String tipo,
  required String? metodoMapeamento,
  required StatusFluxo statusFluxo,
}) {
  final proximos =
      List<String>.of(statusFluxo.transicoesValidas[status] ?? const []);
  proximos.removeWhere((proximo) {
    if (situacaoDados == 'DADOS_INCOMPLETOS' &&
        statusFluxo.exigeDadosPreenchidos.contains(proximo)) {
      return true;
    }
    if (situacaoMapeamento != 'IMAGENS_DISPONIVEIS' &&
        !demandaSemMapeamento(tipo: tipo, metodoMapeamento: metodoMapeamento) &&
        statusFluxo.exigeMapeamentoConcluido.contains(proximo)) {
      return true;
    }
    return false;
  });
  return proximos;
}

String? bloqueioParaStatus({
  required String proximoStatus,
  required String situacaoDados,
  required String situacaoMapeamento,
  required String tipo,
  required String? metodoMapeamento,
  required StatusFluxo statusFluxo,
}) {
  if (situacaoDados == 'DADOS_INCOMPLETOS' &&
      statusFluxo.exigeDadosPreenchidos.contains(proximoStatus)) {
    return 'Exige dados preenchidos.';
  }
  if (situacaoMapeamento != 'IMAGENS_DISPONIVEIS' &&
      !demandaSemMapeamento(tipo: tipo, metodoMapeamento: metodoMapeamento) &&
      statusFluxo.exigeMapeamentoConcluido.contains(proximoStatus)) {
    return 'Exige imagens disponíveis.';
  }
  return null;
}

IndicadoresPainel? derivarIndicadores({
  required String status,
  required String situacaoDados,
  required String situacaoMapeamento,
  required String tipo,
  required String? metodoMapeamento,
}) {
  if (status == 'CANCELADA') return null;
  final mapeamentoConcluido =
      demandaSemMapeamento(tipo: tipo, metodoMapeamento: metodoMapeamento) ||
          situacaoMapeamento == 'IMAGENS_DISPONIVEIS';
  final dadosPreenchidos = situacaoDados == 'DADOS_PREENCHIDOS';
  return IndicadoresPainel(
    mapeamentoConcluido: mapeamentoConcluido,
    dadosPreenchidos: dadosPreenchidos,
    liberadoParaPrescricao: mapeamentoConcluido && dadosPreenchidos,
  );
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item as String)
      .toList();
}
