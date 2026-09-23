import 'page_response.dart';

class Client {
  const Client({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.documentNumber,
    required this.tradeName,
    required this.companyName,
    required this.stateRegistration,
    required this.billingEmail,
    required this.contactEmail,
    required this.phone,
    required this.street,
    required this.addressNumber,
    required this.complement,
    required this.reference,
    required this.district,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.active,
    required this.createdAt,
  });

  factory Client.fromJson(JsonMap json) {
    return Client(
      id: _requiredString(json['id']),
      userId: _requiredString(json['usuarioId']),
      documentType: _requiredString(json['tipoDocumento']),
      documentNumber: _requiredString(json['numeroDocumento']),
      tradeName: _requiredString(json['nomeFantasia']),
      companyName: _string(json['razaoSocial']),
      stateRegistration: _string(json['inscricaoEstadual']),
      billingEmail: _requiredString(json['emailFaturamento']),
      contactEmail: _string(json['emailContato']),
      phone: _string(json['telefone']),
      street: _string(json['logradouro']),
      addressNumber: _string(json['numeroEndereco']),
      complement: _string(json['complemento']),
      reference: _string(json['referencia']),
      district: _string(json['bairro']),
      city: _string(json['cidade']),
      state: _string(json['uf']),
      postalCode: _string(json['cep']),
      active: _bool(json['ativo'], fallback: true),
      createdAt: _string(json['createdAt']),
    );
  }

  final String id;
  final String userId;
  final String documentType;
  final String documentNumber;
  final String tradeName;
  final String? companyName;
  final String? stateRegistration;
  final String billingEmail;
  final String? contactEmail;
  final String? phone;
  final String? street;
  final String? addressNumber;
  final String? complement;
  final String? reference;
  final String? district;
  final String? city;
  final String? state;
  final String? postalCode;
  final bool active;
  final String? createdAt;
}

class ClientInput {
  const ClientInput({
    this.userId,
    required this.documentType,
    required this.documentNumber,
    required this.tradeName,
    this.companyName,
    this.stateRegistration,
    required this.billingEmail,
    this.contactEmail,
    this.phone,
    this.street,
    this.addressNumber,
    this.complement,
    this.reference,
    this.district,
    this.city,
    this.state,
    this.postalCode,
  });

  final String? userId;
  final String documentType;
  final String documentNumber;
  final String tradeName;
  final String? companyName;
  final String? stateRegistration;
  final String billingEmail;
  final String? contactEmail;
  final String? phone;
  final String? street;
  final String? addressNumber;
  final String? complement;
  final String? reference;
  final String? district;
  final String? city;
  final String? state;
  final String? postalCode;

  JsonMap toJson({required bool includeUser}) {
    return _withoutNulls({
      if (includeUser) 'usuarioId': userId,
      'tipoDocumento': documentType,
      'numeroDocumento': documentNumber,
      'nomeFantasia': tradeName,
      'razaoSocial': companyName,
      'inscricaoEstadual': stateRegistration,
      'emailFaturamento': billingEmail,
      'emailContato': contactEmail,
      'telefone': phone,
      'logradouro': street,
      'numeroEndereco': addressNumber,
      'complemento': complement,
      'referencia': reference,
      'bairro': district,
      'cidade': city,
      'uf': state,
      'cep': postalCode,
    });
  }
}

class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.manager,
    required this.ownerClientId,
    required this.ownerClientName,
    required this.areaHa,
    required this.cultivableArea,
    required this.latitude,
    required this.longitude,
    required this.boundaryGeoJson,
    required this.sketchPath,
    required this.phone,
    required this.location,
    required this.street,
    required this.addressNumber,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.active,
    required this.cultures,
    required this.equipment,
  });

  factory Farm.fromJson(JsonMap json) {
    return Farm(
      id: _requiredString(json['id']),
      name: _requiredString(json['nome']),
      manager: _string(json['responsavel']),
      ownerClientId: _string(json['clienteProprietarioId']),
      ownerClientName: _string(json['clienteProprietarioNome']),
      areaHa: _double(json['areaHa']),
      cultivableArea: _double(json['areaCultivavel']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      boundaryGeoJson: _string(json['contornoGeoJson']),
      sketchPath: _string(json['croquiPath']),
      phone: _string(json['telefone']),
      location: _string(json['localizacao']),
      street: _string(json['logradouro']),
      addressNumber: _string(json['numeroEndereco']),
      complement: _string(json['complemento']),
      district: _string(json['bairro']),
      city: _string(json['cidade']),
      state: _string(json['uf']),
      postalCode: _string(json['cep']),
      active: _bool(json['ativo'], fallback: true),
      cultures: _mapList(json['culturas']),
      equipment: _mapList(json['equipamentos']),
    );
  }

  final String id;
  final String name;
  final String? manager;
  final String? ownerClientId;
  final String? ownerClientName;
  final double? areaHa;
  final double? cultivableArea;
  final double? latitude;
  final double? longitude;
  final String? boundaryGeoJson;
  final String? sketchPath;
  final String? phone;
  final String? location;
  final String? street;
  final String? addressNumber;
  final String? complement;
  final String? district;
  final String? city;
  final String? state;
  final String? postalCode;
  final bool active;
  final List<JsonMap> cultures;
  final List<JsonMap> equipment;
}

class FarmInput {
  const FarmInput({
    required this.name,
    this.manager,
    this.ownerClientId,
    this.areaHa,
    this.cultivableArea,
    this.latitude,
    this.longitude,
    this.boundaryGeoJson,
    this.sketchPath,
    this.phone,
    this.location,
    this.street,
    this.addressNumber,
    this.complement,
    this.district,
    this.city,
    this.state,
    this.postalCode,
  });

  final String name;
  final String? manager;
  final String? ownerClientId;
  final double? areaHa;
  final double? cultivableArea;
  final double? latitude;
  final double? longitude;
  final String? boundaryGeoJson;
  final String? sketchPath;
  final String? phone;
  final String? location;
  final String? street;
  final String? addressNumber;
  final String? complement;
  final String? district;
  final String? city;
  final String? state;
  final String? postalCode;

  JsonMap toJson() => _withoutNulls({
        'nome': name,
        'responsavel': manager,
        'clienteProprietarioId': ownerClientId,
        'areaHa': areaHa,
        'areaCultivavel': cultivableArea,
        'latitude': latitude,
        'longitude': longitude,
        'contornoGeoJson': boundaryGeoJson,
        'croquiPath': sketchPath,
        'telefone': phone,
        'localizacao': location,
        'logradouro': street,
        'numeroEndereco': addressNumber,
        'complemento': complement,
        'bairro': district,
        'cidade': city,
        'uf': state,
        'cep': postalCode,
      });
}

class ClientFarmLink {
  const ClientFarmLink({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.farmId,
    required this.farmName,
    required this.startDate,
    required this.endDate,
  });

  factory ClientFarmLink.fromJson(JsonMap json) {
    return ClientFarmLink(
      id: _requiredString(json['id']),
      clientId: _requiredString(json['clienteId']),
      clientName: _requiredString(json['clienteNomeFantasia']),
      farmId: _requiredString(json['fazendaId']),
      farmName: _requiredString(json['fazendaNome']),
      startDate: _requiredString(json['dataInicio']),
      endDate: _string(json['dataFim']),
    );
  }

  final String id;
  final String clientId;
  final String clientName;
  final String farmId;
  final String farmName;
  final String startDate;
  final String? endDate;
}

class FieldPlot {
  const FieldPlot({
    required this.id,
    required this.farmId,
    required this.name,
    required this.lptCode,
    required this.number,
    required this.areaHa,
    required this.cultivableArea,
    required this.latitude,
    required this.longitude,
    required this.boundaryGeoJson,
    required this.irrigated,
    required this.active,
  });

  factory FieldPlot.fromJson(JsonMap json) {
    return FieldPlot(
      id: _requiredString(json['id']),
      farmId: _requiredString(json['fazendaId']),
      name: _requiredString(json['nome']),
      lptCode: _string(json['codigoLpt']),
      number: _int(json['numeroTalhao']),
      areaHa: _double(json['areaHa']),
      cultivableArea: _double(json['areaCultivavel']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      boundaryGeoJson: _string(json['contornoGeoJson']),
      irrigated: _bool(json['irrigacao']),
      active: _bool(json['ativo'], fallback: true),
    );
  }

  final String id;
  final String farmId;
  final String name;
  final String? lptCode;
  final int? number;
  final double? areaHa;
  final double? cultivableArea;
  final double? latitude;
  final double? longitude;
  final String? boundaryGeoJson;
  final bool irrigated;
  final bool active;
}

class FieldInput {
  const FieldInput({
    this.farmId,
    required this.name,
    this.lptCode,
    this.number,
    this.areaHa,
    this.cultivableArea,
    this.latitude,
    this.longitude,
    this.boundaryGeoJson,
    required this.irrigated,
  });

  final String? farmId;
  final String name;
  final String? lptCode;
  final int? number;
  final double? areaHa;
  final double? cultivableArea;
  final double? latitude;
  final double? longitude;
  final String? boundaryGeoJson;
  final bool irrigated;

  JsonMap toJson({required bool includeFarm}) => _withoutNulls({
        if (includeFarm) 'fazendaId': farmId,
        'nome': name,
        'codigoLpt': lptCode,
        'numeroTalhao': number,
        'areaHa': areaHa,
        'areaCultivavel': cultivableArea,
        'latitude': latitude,
        'longitude': longitude,
        'contornoGeoJson': boundaryGeoJson,
        'irrigacao': irrigated,
      });
}

class Collaborator {
  const Collaborator({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.clientId,
    required this.clientName,
    required this.userId,
    required this.farmIds,
    required this.active,
  });

  factory Collaborator.fromJson(JsonMap json) {
    return Collaborator(
      id: _requiredString(json['id']),
      name: _requiredString(json['nome']),
      role: _string(json['cargo']),
      phone: _string(json['telefone']),
      email: _string(json['email']),
      clientId: _string(json['clienteId']),
      clientName: _string(json['clienteNome']),
      userId: _string(json['usuarioId']),
      farmIds: _stringList(json['fazendaIds']),
      active: _bool(json['ativo'], fallback: true),
    );
  }

  final String id;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String? clientId;
  final String? clientName;
  final String? userId;
  final List<String> farmIds;
  final bool active;
}

class CollaboratorInput {
  const CollaboratorInput({
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.clientId,
    this.userId,
  });

  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String? clientId;
  final String? userId;

  JsonMap toJson() => _withoutNulls({
        'nome': name,
        'cargo': role,
        'telefone': phone,
        'email': email,
        'clienteId': clientId,
        'usuarioId': userId,
      });
}

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.comment,
    required this.active,
  });

  factory Equipment.fromJson(JsonMap json) {
    return Equipment(
      id: _int(json['id']) ?? 0,
      name: _requiredString(json['nome']),
      comment: _string(json['comentario']),
      active: _bool(json['ativo'], fallback: true),
    );
  }

  final int id;
  final String name;
  final String? comment;
  final bool active;
}

class FieldGroup {
  const FieldGroup({
    required this.id,
    required this.name,
    required this.active,
    required this.fields,
  });

  factory FieldGroup.fromJson(JsonMap json) {
    return FieldGroup(
      id: _requiredString(json['id']),
      name: _requiredString(json['nome']),
      active: _bool(json['ativo'], fallback: true),
      fields: _mapList(json['talhoes']),
    );
  }

  final String id;
  final String name;
  final bool active;
  final List<JsonMap> fields;
}

String _requiredString(Object? value) => value?.toString() ?? '';

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value, {bool fallback = false}) {
  return value is bool ? value : fallback;
}

List<JsonMap> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

JsonMap _withoutNulls(JsonMap json) {
  return Map<String, dynamic>.fromEntries(
    json.entries.where((entry) {
      final value = entry.value;
      return value != null && (value is! String || value.trim().isNotEmpty);
    }),
  );
}
