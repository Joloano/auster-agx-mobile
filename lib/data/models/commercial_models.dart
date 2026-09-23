import 'demanda_models.dart';
import 'page_response.dart';

class Order {
  const Order({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.code,
    required this.nickname,
    required this.notes,
    required this.active,
    required this.createdAt,
  });

  factory Order.fromJson(JsonMap json) {
    return Order(
      id: json['id'].toString(),
      clientId: json['clienteId'].toString(),
      clientName: json['clienteNomeFantasia'] as String? ?? '',
      code: json['codigo'] as String? ?? '',
      nickname: json['apelido'] as String?,
      notes: json['observacoes'] as String?,
      active: json['ativo'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String clientId;
  final String clientName;
  final String code;
  final String? nickname;
  final String? notes;
  final bool active;
  final String? createdAt;
}

class OrderInput {
  const OrderInput({required this.clientId, this.nickname, this.notes});

  final String clientId;
  final String? nickname;
  final String? notes;

  JsonMap toCreateJson() => {
        'clienteId': clientId,
        if (_hasText(nickname)) 'apelido': nickname!.trim(),
        if (_hasText(notes)) 'observacoes': notes!.trim(),
      };

  JsonMap toUpdateJson() => {
        if (_hasText(nickname)) 'apelido': nickname!.trim(),
        if (_hasText(notes)) 'observacoes': notes!.trim(),
      };
}

class DemandCreateInput {
  const DemandCreateInput({
    required this.orderId,
    required this.type,
    this.representativeId,
    this.deadline,
    this.areaOfInterest,
    this.originDemandId,
    this.applicationNumber,
    this.source,
    this.pilotId,
    this.satellite,
  });

  final String orderId;
  final String type;
  final String? representativeId;
  final String? deadline;
  final String? areaOfInterest;
  final String? originDemandId;
  final int? applicationNumber;
  final String? source;
  final String? pilotId;
  final String? satellite;

  JsonMap toJson() => {
        'pedidoId': orderId,
        'tipo': type,
        if (_hasText(representativeId)) 'representanteId': representativeId,
        if (_hasText(deadline)) 'prazo': deadline,
        if (_hasText(areaOfInterest)) 'areaDeInteresse': areaOfInterest,
        if (_hasText(originDemandId)) 'demandaOrigemId': originDemandId,
        if (applicationNumber != null) 'numeroAplicacao': applicationNumber,
        if (_hasText(source)) 'fonte': source,
        if (_hasText(pilotId)) 'pilotoId': pilotId,
        if (_hasText(satellite)) 'satelite': satellite,
      };
}

class RemoteSensingCreateInput {
  const RemoteSensingCreateInput({
    required this.source,
    this.imageDate,
    this.pilotId,
    this.satellite,
    this.originMappingId,
    this.mappingNumber,
    this.quality,
    this.phenologicalStage,
    this.notes,
  });

  final String source;
  final String? imageDate;
  final String? pilotId;
  final String? satellite;
  final String? originMappingId;
  final int? mappingNumber;
  final String? quality;
  final String? phenologicalStage;
  final String? notes;

  JsonMap toJson() => {
        'fonte': source,
        if (_hasText(imageDate)) 'dataImagem': imageDate,
        if (_hasText(pilotId)) 'pilotoId': pilotId,
        if (_hasText(satellite)) 'satelite': satellite,
        if (_hasText(originMappingId)) 'mapeamentoOrigemId': originMappingId,
        if (mappingNumber != null) 'numeroMapeamento': mappingNumber,
        if (_hasText(quality)) 'qualidade': quality,
        if (_hasText(phenologicalStage)) 'estadioFenologico': phenologicalStage,
        if (_hasText(notes)) 'observacoes': notes,
      };
}

class OrderDetails {
  const OrderDetails({required this.order, required this.demands});

  final Order order;
  final List<Demanda> demands;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
