class DashboardOverview {
  const DashboardOverview({
    required this.escopo,
    required this.totalClientes,
    required this.totalFazendas,
    required this.totalTalhoes,
    required this.totalVinculosAtivos,
    required this.areaTotalFazendasHa,
    required this.areaTotalTalhoesHa,
    required this.coberturaAreaTalhoesPercentual,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      escopo: json['escopo'] as String,
      totalClientes: (json['totalClientes'] as num).toInt(),
      totalFazendas: (json['totalFazendas'] as num).toInt(),
      totalTalhoes: (json['totalTalhoes'] as num).toInt(),
      totalVinculosAtivos: (json['totalVinculosAtivos'] as num).toInt(),
      areaTotalFazendasHa: _doubleOrNull(json['areaTotalFazendasHa']),
      areaTotalTalhoesHa: _doubleOrNull(json['areaTotalTalhoesHa']),
      coberturaAreaTalhoesPercentual: _doubleOrNull(
        json['coberturaAreaTalhoesPercentual'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'escopo': escopo,
      'totalClientes': totalClientes,
      'totalFazendas': totalFazendas,
      'totalTalhoes': totalTalhoes,
      'totalVinculosAtivos': totalVinculosAtivos,
      'areaTotalFazendasHa': areaTotalFazendasHa,
      'areaTotalTalhoesHa': areaTotalTalhoesHa,
      'coberturaAreaTalhoesPercentual': coberturaAreaTalhoesPercentual,
    };
  }

  final String escopo;
  final int totalClientes;
  final int totalFazendas;
  final int totalTalhoes;
  final int totalVinculosAtivos;
  final double? areaTotalFazendasHa;
  final double? areaTotalTalhoesHa;
  final double? coberturaAreaTalhoesPercentual;
}

class DashboardDemandItem {
  const DashboardDemandItem({
    required this.id,
    required this.tipo,
    required this.codigo,
    required this.aplicacao,
    required this.fazenda,
    required this.talhoes,
    required this.areaHa,
    required this.cultura,
    required this.dataPrevista,
    required this.representanteId,
    required this.responsavelNome,
    required this.status,
    required this.situacaoDados,
    required this.situacaoMapeamento,
    required this.metodoMapeamento,
    required this.arquivada,
    required this.areaDeInteresse,
    required this.retrabalho,
  });

  factory DashboardDemandItem.fromJson(Map<String, dynamic> json) {
    return DashboardDemandItem(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      codigo: json['codigo'] as String,
      aplicacao: json['aplicacao'] as String?,
      fazenda: json['fazenda'] as String?,
      talhoes: (json['talhoes'] as List<dynamic>? ?? const [])
          .map((value) => value as String)
          .toList(),
      areaHa: _doubleOrNull(json['areaHa']),
      cultura: json['cultura'] as String?,
      dataPrevista: json['dataPrevista'] as String?,
      representanteId: json['representanteId'] as String?,
      responsavelNome: json['responsavelNome'] as String?,
      status: json['status'] as String,
      situacaoDados: json['situacaoDados'] as String,
      situacaoMapeamento: json['situacaoMapeamento'] as String,
      metodoMapeamento: json['metodoMapeamento'] as String?,
      arquivada: json['arquivada'] as bool,
      areaDeInteresse: json['areaDeInteresse'] as String?,
      retrabalho: json['retrabalho'] as bool,
    );
  }

  DashboardDemandItem copyWith({
    String? status,
    String? situacaoDados,
    String? situacaoMapeamento,
    bool? arquivada,
  }) {
    return DashboardDemandItem(
      id: id,
      tipo: tipo,
      codigo: codigo,
      aplicacao: aplicacao,
      fazenda: fazenda,
      talhoes: talhoes,
      areaHa: areaHa,
      cultura: cultura,
      dataPrevista: dataPrevista,
      representanteId: representanteId,
      responsavelNome: responsavelNome,
      status: status ?? this.status,
      situacaoDados: situacaoDados ?? this.situacaoDados,
      situacaoMapeamento: situacaoMapeamento ?? this.situacaoMapeamento,
      metodoMapeamento: metodoMapeamento,
      arquivada: arquivada ?? this.arquivada,
      areaDeInteresse: areaDeInteresse,
      retrabalho: retrabalho,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'codigo': codigo,
      'aplicacao': aplicacao,
      'fazenda': fazenda,
      'talhoes': talhoes,
      'areaHa': areaHa,
      'cultura': cultura,
      'dataPrevista': dataPrevista,
      'representanteId': representanteId,
      'responsavelNome': responsavelNome,
      'status': status,
      'situacaoDados': situacaoDados,
      'situacaoMapeamento': situacaoMapeamento,
      'metodoMapeamento': metodoMapeamento,
      'arquivada': arquivada,
      'areaDeInteresse': areaDeInteresse,
      'retrabalho': retrabalho,
    };
  }

  final String id;
  final String tipo;
  final String codigo;
  final String? aplicacao;
  final String? fazenda;
  final List<String> talhoes;
  final double? areaHa;
  final String? cultura;
  final String? dataPrevista;
  final String? representanteId;
  final String? responsavelNome;
  final String status;
  final String situacaoDados;
  final String situacaoMapeamento;
  final String? metodoMapeamento;
  final bool arquivada;
  final String? areaDeInteresse;
  final bool retrabalho;
}

class PageResponse<T> {
  const PageResponse({
    required this.conteudo,
    required this.totalElementos,
    required this.totalPaginas,
    required this.pagina,
    required this.tamanho,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper,
  ) {
    return PageResponse<T>(
      conteudo: (json['conteudo'] as List<dynamic>)
          .map((item) => mapper(item as Map<String, dynamic>))
          .toList(),
      totalElementos: (json['totalElementos'] as num).toInt(),
      totalPaginas: (json['totalPaginas'] as num).toInt(),
      pagina: (json['pagina'] as num).toInt(),
      tamanho: (json['tamanho'] as num).toInt(),
    );
  }

  final List<T> conteudo;
  final int totalElementos;
  final int totalPaginas;
  final int pagina;
  final int tamanho;
}

double? _doubleOrNull(Object? value) {
  if (value == null) return null;
  return (value as num).toDouble();
}
