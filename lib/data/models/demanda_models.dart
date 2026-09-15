class Demanda {
  const Demanda({
    required this.id,
    required this.pedidoId,
    required this.pedidoCodigo,
    required this.clienteNome,
    required this.fazendaNomes,
    required this.codigoDemanda,
    required this.tipo,
    required this.status,
    required this.statusChave,
    required this.situacaoDados,
    required this.situacaoMapeamento,
    required this.retrabalho,
    required this.demandaOrigemId,
    required this.numeroAplicacao,
    required this.representanteId,
    required this.representanteNome,
    required this.prazo,
    required this.areaDeInteresse,
    required this.grupoIds,
    required this.sensoriamentoIds,
    required this.ativo,
    required this.createdAt,
  });

  factory Demanda.fromJson(Map<String, dynamic> json) {
    return Demanda(
      id: json['id'] as String,
      pedidoId: json['pedidoId'] as String,
      pedidoCodigo: json['pedidoCodigo'] as String,
      clienteNome: json['clienteNome'] as String?,
      fazendaNomes: (json['fazendaNomes'] as List<dynamic>? ?? const [])
          .map((value) => value as String)
          .toList(),
      codigoDemanda: json['codigoDemanda'] as String,
      tipo: json['tipo'] as String,
      status: json['status'] as String,
      statusChave: json['statusChave'] as String,
      situacaoDados: json['situacaoDados'] as String,
      situacaoMapeamento: json['situacaoMapeamento'] as String,
      retrabalho: json['retrabalho'] as bool,
      demandaOrigemId: json['demandaOrigemId'] as String?,
      numeroAplicacao: (json['numeroAplicacao'] as num?)?.toInt(),
      representanteId: json['representanteId'] as String?,
      representanteNome: json['representanteNome'] as String?,
      prazo: json['prazo'] as String?,
      areaDeInteresse: json['areaDeInteresse'] as String?,
      grupoIds: (json['grupoIds'] as List<dynamic>? ?? const [])
          .map((value) => value as String)
          .toList(),
      sensoriamentoIds: (json['sensoriamentoIds'] as List<dynamic>? ?? const [])
          .map((value) => value as String)
          .toList(),
      ativo: json['ativo'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pedidoId': pedidoId,
      'pedidoCodigo': pedidoCodigo,
      'clienteNome': clienteNome,
      'fazendaNomes': fazendaNomes,
      'codigoDemanda': codigoDemanda,
      'tipo': tipo,
      'status': status,
      'statusChave': statusChave,
      'situacaoDados': situacaoDados,
      'situacaoMapeamento': situacaoMapeamento,
      'retrabalho': retrabalho,
      'demandaOrigemId': demandaOrigemId,
      'numeroAplicacao': numeroAplicacao,
      'representanteId': representanteId,
      'representanteNome': representanteNome,
      'prazo': prazo,
      'areaDeInteresse': areaDeInteresse,
      'grupoIds': grupoIds,
      'sensoriamentoIds': sensoriamentoIds,
      'ativo': ativo,
      'createdAt': createdAt,
    };
  }

  Demanda copyWith({
    String? status,
    String? statusChave,
    String? situacaoDados,
    String? situacaoMapeamento,
  }) {
    return Demanda(
      id: id,
      pedidoId: pedidoId,
      pedidoCodigo: pedidoCodigo,
      clienteNome: clienteNome,
      fazendaNomes: fazendaNomes,
      codigoDemanda: codigoDemanda,
      tipo: tipo,
      status: status ?? this.status,
      statusChave: statusChave ?? this.statusChave,
      situacaoDados: situacaoDados ?? this.situacaoDados,
      situacaoMapeamento: situacaoMapeamento ?? this.situacaoMapeamento,
      retrabalho: retrabalho,
      demandaOrigemId: demandaOrigemId,
      numeroAplicacao: numeroAplicacao,
      representanteId: representanteId,
      representanteNome: representanteNome,
      prazo: prazo,
      areaDeInteresse: areaDeInteresse,
      grupoIds: grupoIds,
      sensoriamentoIds: sensoriamentoIds,
      ativo: ativo,
      createdAt: createdAt,
    );
  }

  final String id;
  final String pedidoId;
  final String pedidoCodigo;
  final String? clienteNome;
  final List<String> fazendaNomes;
  final String codigoDemanda;
  final String tipo;
  final String status;
  final String statusChave;
  final String situacaoDados;
  final String situacaoMapeamento;
  final bool retrabalho;
  final String? demandaOrigemId;
  final int? numeroAplicacao;
  final String? representanteId;
  final String? representanteNome;
  final String? prazo;
  final String? areaDeInteresse;
  final List<String> grupoIds;
  final List<String> sensoriamentoIds;
  final bool ativo;
  final String createdAt;
}

class DemandaDetail {
  const DemandaDetail({
    required this.demanda,
    required this.pedido,
    required this.cliente,
    required this.fazendas,
    required this.grupos,
    required this.culturas,
  });

  factory DemandaDetail.fromJson(Map<String, dynamic> json) {
    return DemandaDetail(
      demanda: Demanda.fromJson(json['demanda'] as Map<String, dynamic>),
      pedido: json['pedido'] as Map<String, dynamic>,
      cliente: json['cliente'] as Map<String, dynamic>?,
      fazendas: (json['fazendas'] as List<dynamic>? ?? const [])
          .map((value) => value as Map<String, dynamic>)
          .toList(),
      grupos: (json['grupos'] as List<dynamic>? ?? const [])
          .map((value) => value as Map<String, dynamic>)
          .toList(),
      culturas: (json['culturas'] as List<dynamic>? ?? const [])
          .map((value) => value as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'demanda': demanda.toJson(),
      'pedido': pedido,
      'cliente': cliente,
      'fazendas': fazendas,
      'grupos': grupos,
      'culturas': culturas,
    };
  }

  DemandaDetail copyWith({Demanda? demanda}) {
    return DemandaDetail(
      demanda: demanda ?? this.demanda,
      pedido: pedido,
      cliente: cliente,
      fazendas: fazendas,
      grupos: grupos,
      culturas: culturas,
    );
  }

  final Demanda demanda;
  final Map<String, dynamic> pedido;
  final Map<String, dynamic>? cliente;
  final List<Map<String, dynamic>> fazendas;
  final List<Map<String, dynamic>> grupos;
  final List<Map<String, dynamic>> culturas;
}

class DemandaUpdateInput {
  const DemandaUpdateInput({
    required this.tipo,
    this.representanteId,
    this.prazo,
    this.areaDeInteresse,
    this.status,
    this.situacaoDados,
    this.situacaoMapeamento,
    this.retrabalho,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      if (representanteId != null) 'representanteId': representanteId,
      if (prazo != null) 'prazo': prazo,
      if (areaDeInteresse != null) 'areaDeInteresse': areaDeInteresse,
      if (status != null) 'status': status,
      if (situacaoDados != null) 'situacaoDados': situacaoDados,
      if (situacaoMapeamento != null) 'situacaoMapeamento': situacaoMapeamento,
      if (retrabalho != null) 'retrabalho': retrabalho,
    };
  }

  final String tipo;
  final String? representanteId;
  final String? prazo;
  final String? areaDeInteresse;
  final String? status;
  final String? situacaoDados;
  final String? situacaoMapeamento;
  final bool? retrabalho;
}
