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
    required this.sensoriamentos,
    required this.culturas,
    required this.demandaOrigem,
    required this.derivadas,
  });

  factory DemandaDetail.fromJson(Map<String, dynamic> json) {
    return DemandaDetail(
      demanda: Demanda.fromJson(json['demanda'] as Map<String, dynamic>),
      pedido: PedidoResumo.fromJson(json['pedido'] as Map<String, dynamic>),
      cliente: json['cliente'] == null
          ? null
          : ClienteResumo.fromJson(json['cliente'] as Map<String, dynamic>),
      fazendas: (json['fazendas'] as List<dynamic>? ?? const [])
          .map((value) => FazendaResumo.fromJson(value as Map<String, dynamic>))
          .toList(),
      grupos: (json['grupos'] as List<dynamic>? ?? const [])
          .map((value) => GrupoResumo.fromJson(value as Map<String, dynamic>))
          .toList(),
      sensoriamentos: (json['sensoriamentos'] as List<dynamic>? ?? const [])
          .map((value) => SensoriamentoResumo.fromJson(
                value as Map<String, dynamic>,
              ))
          .toList(),
      culturas: (json['culturas'] as List<dynamic>? ?? const [])
          .map((value) => CulturaResumo.fromJson(value as Map<String, dynamic>))
          .toList(),
      demandaOrigem: json['demandaOrigem'] == null
          ? null
          : DemandaCadeiaResumo.fromJson(
              json['demandaOrigem'] as Map<String, dynamic>,
            ),
      derivadas: (json['derivadas'] as List<dynamic>? ?? const [])
          .map((value) => DemandaDerivadaResumo.fromJson(
                value as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'demanda': demanda.toJson(),
      'pedido': pedido.toJson(),
      'cliente': cliente?.toJson(),
      'fazendas': fazendas.map((value) => value.toJson()).toList(),
      'grupos': grupos.map((value) => value.toJson()).toList(),
      'sensoriamentos': sensoriamentos.map((value) => value.toJson()).toList(),
      'culturas': culturas.map((value) => value.toJson()).toList(),
      'demandaOrigem': demandaOrigem?.toJson(),
      'derivadas': derivadas.map((value) => value.toJson()).toList(),
    };
  }

  DemandaDetail copyWith({Demanda? demanda}) {
    return DemandaDetail(
      demanda: demanda ?? this.demanda,
      pedido: pedido,
      cliente: cliente,
      fazendas: fazendas,
      grupos: grupos,
      sensoriamentos: sensoriamentos,
      culturas: culturas,
      demandaOrigem: demandaOrigem,
      derivadas: derivadas,
    );
  }

  final Demanda demanda;
  final PedidoResumo pedido;
  final ClienteResumo? cliente;
  final List<FazendaResumo> fazendas;
  final List<GrupoResumo> grupos;
  final List<SensoriamentoResumo> sensoriamentos;
  final List<CulturaResumo> culturas;
  final DemandaCadeiaResumo? demandaOrigem;
  final List<DemandaDerivadaResumo> derivadas;
}

class PedidoResumo {
  const PedidoResumo({required this.id, required this.codigo, this.apelido});

  factory PedidoResumo.fromJson(Map<String, dynamic> json) {
    return PedidoResumo(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      apelido: json['apelido'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'apelido': apelido,
      };

  final String id;
  final String codigo;
  final String? apelido;
}

class ClienteResumo {
  const ClienteResumo({required this.id, required this.nomeFantasia});

  factory ClienteResumo.fromJson(Map<String, dynamic> json) {
    return ClienteResumo(
      id: json['id'] as String,
      nomeFantasia: json['nomeFantasia'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomeFantasia': nomeFantasia,
      };

  final String id;
  final String nomeFantasia;
}

class FazendaResumo {
  const FazendaResumo({required this.id, required this.nome});

  factory FazendaResumo.fromJson(Map<String, dynamic> json) {
    return FazendaResumo(
        id: json['id'] as String, nome: json['nome'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};

  final String id;
  final String nome;
}

class TalhaoResumo {
  const TalhaoResumo({
    required this.id,
    required this.nome,
    required this.fazendaId,
    required this.fazendaNome,
  });

  factory TalhaoResumo.fromJson(Map<String, dynamic> json) {
    return TalhaoResumo(
      id: json['id'] as String,
      nome: json['nome'] as String,
      fazendaId: json['fazendaId'] as String?,
      fazendaNome: json['fazendaNome'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'fazendaId': fazendaId,
        'fazendaNome': fazendaNome,
      };

  final String id;
  final String nome;
  final String? fazendaId;
  final String? fazendaNome;
}

class GrupoResumo {
  const GrupoResumo({
    required this.id,
    required this.nome,
    required this.talhoes,
  });

  factory GrupoResumo.fromJson(Map<String, dynamic> json) {
    return GrupoResumo(
      id: json['id'] as String,
      nome: json['nome'] as String,
      talhoes: (json['talhoes'] as List<dynamic>? ?? const [])
          .map((value) => TalhaoResumo.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'talhoes': talhoes.map((value) => value.toJson()).toList(),
      };

  final String id;
  final String nome;
  final List<TalhaoResumo> talhoes;
}

class SensoriamentoResumo {
  const SensoriamentoResumo({
    required this.id,
    required this.codigoMapeamento,
    required this.fonte,
    required this.pilotoId,
    required this.pilotoNome,
    required this.satelite,
    required this.mapeamentoOrigemId,
    required this.numeroMapeamento,
    required this.status,
  });

  factory SensoriamentoResumo.fromJson(Map<String, dynamic> json) {
    return SensoriamentoResumo(
      id: json['id'] as String,
      codigoMapeamento: json['codigoMapeamento'] as String,
      fonte: json['fonte'] as String,
      pilotoId: json['pilotoId'] as String?,
      pilotoNome: json['pilotoNome'] as String?,
      satelite: json['satelite'] as String?,
      mapeamentoOrigemId: json['mapeamentoOrigemId'] as String?,
      numeroMapeamento: (json['numeroMapeamento'] as num?)?.toInt(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigoMapeamento': codigoMapeamento,
        'fonte': fonte,
        'pilotoId': pilotoId,
        'pilotoNome': pilotoNome,
        'satelite': satelite,
        'mapeamentoOrigemId': mapeamentoOrigemId,
        'numeroMapeamento': numeroMapeamento,
        'status': status,
      };

  final String id;
  final String codigoMapeamento;
  final String fonte;
  final String? pilotoId;
  final String? pilotoNome;
  final String? satelite;
  final String? mapeamentoOrigemId;
  final int? numeroMapeamento;
  final String status;
}

class CulturaResumo {
  const CulturaResumo({required this.id, required this.nome});

  factory CulturaResumo.fromJson(Map<String, dynamic> json) {
    return CulturaResumo(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};

  final int id;
  final String nome;
}

class DemandaCadeiaResumo {
  const DemandaCadeiaResumo({
    required this.id,
    required this.codigoDemanda,
    required this.status,
  });

  factory DemandaCadeiaResumo.fromJson(Map<String, dynamic> json) {
    return DemandaCadeiaResumo(
      id: json['id'] as String,
      codigoDemanda: json['codigoDemanda'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigoDemanda': codigoDemanda,
        'status': status,
      };

  final String id;
  final String codigoDemanda;
  final String status;
}

class DemandaDerivadaResumo {
  const DemandaDerivadaResumo({
    required this.id,
    required this.codigoDemanda,
    required this.tipo,
    required this.status,
    required this.numeroAplicacao,
    required this.retrabalho,
  });

  factory DemandaDerivadaResumo.fromJson(Map<String, dynamic> json) {
    return DemandaDerivadaResumo(
      id: json['id'] as String,
      codigoDemanda: json['codigoDemanda'] as String,
      tipo: json['tipo'] as String,
      status: json['status'] as String,
      numeroAplicacao: (json['numeroAplicacao'] as num?)?.toInt(),
      retrabalho: json['retrabalho'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigoDemanda': codigoDemanda,
        'tipo': tipo,
        'status': status,
        'numeroAplicacao': numeroAplicacao,
        'retrabalho': retrabalho,
      };

  final String id;
  final String codigoDemanda;
  final String tipo;
  final String status;
  final int? numeroAplicacao;
  final bool retrabalho;
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

class DemandaStatusHistorico {
  const DemandaStatusHistorico({
    required this.demandaId,
    required this.statusAnterior,
    required this.statusAnteriorChave,
    required this.statusNovo,
    required this.statusNovoChave,
    required this.alteradoPorId,
    required this.alteradoPorNome,
    required this.alteradoEm,
  });

  factory DemandaStatusHistorico.fromJson(Map<String, dynamic> json) {
    return DemandaStatusHistorico(
      demandaId: json['demandaId'] as String,
      statusAnterior: json['statusAnterior'] as String?,
      statusAnteriorChave: json['statusAnteriorChave'] as String?,
      statusNovo: json['statusNovo'] as String,
      statusNovoChave: json['statusNovoChave'] as String,
      alteradoPorId: json['alteradoPorId'] as String?,
      alteradoPorNome: json['alteradoPorNome'] as String,
      alteradoEm: json['alteradoEm'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'demandaId': demandaId,
        'statusAnterior': statusAnterior,
        'statusAnteriorChave': statusAnteriorChave,
        'statusNovo': statusNovo,
        'statusNovoChave': statusNovoChave,
        'alteradoPorId': alteradoPorId,
        'alteradoPorNome': alteradoPorNome,
        'alteradoEm': alteradoEm,
      };

  final String demandaId;
  final String? statusAnterior;
  final String? statusAnteriorChave;
  final String statusNovo;
  final String statusNovoChave;
  final String? alteradoPorId;
  final String alteradoPorNome;
  final String alteradoEm;
}
