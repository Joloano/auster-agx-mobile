import 'dart:typed_data';

import 'page_response.dart';

class RemoteSensing {
  const RemoteSensing({
    required this.id,
    required this.mappingCode,
    required this.source,
    required this.pilotId,
    required this.pilotName,
    required this.satellite,
    required this.originMappingId,
    required this.mappingNumber,
    required this.quality,
    required this.imageDate,
    required this.phenologicalStage,
    required this.notes,
    required this.mappingImagePath,
    required this.status,
    required this.active,
    required this.createdAt,
  });

  factory RemoteSensing.fromJson(JsonMap json) => RemoteSensing(
        id: _string(json['id']) ?? '',
        mappingCode: _string(json['codigoMapeamento']) ?? '',
        source: _string(json['fonte']) ?? '',
        pilotId: _string(json['pilotoId']),
        pilotName: _string(json['pilotoNome']),
        satellite: _string(json['satelite']),
        originMappingId: _string(json['mapeamentoOrigemId']),
        mappingNumber: _int(json['numeroMapeamento']),
        quality: _string(json['qualidade']),
        imageDate: _string(json['dataImagem']),
        phenologicalStage: _string(json['estadioFenologico']),
        notes: _string(json['observacoes']),
        mappingImagePath: _string(json['imagemMapeamentoPath']),
        status: _string(json['status']) ?? '',
        active: _bool(json['ativo'], fallback: true),
        createdAt: _string(json['createdAt']) ?? '',
      );

  final String id;
  final String mappingCode;
  final String source;
  final String? pilotId;
  final String? pilotName;
  final String? satellite;
  final String? originMappingId;
  final int? mappingNumber;
  final String? quality;
  final String? imageDate;
  final String? phenologicalStage;
  final String? notes;
  final String? mappingImagePath;
  final String status;
  final bool active;
  final String createdAt;
}

class RemoteSensingUpdateInput {
  const RemoteSensingUpdateInput({
    required this.source,
    required this.imageDate,
    this.pilotId,
    this.satellite,
    this.quality,
    this.phenologicalStage,
    this.notes,
    this.mappingImagePath,
  });

  final String source;
  final String imageDate;
  final String? pilotId;
  final String? satellite;
  final String? quality;
  final String? phenologicalStage;
  final String? notes;
  final String? mappingImagePath;

  JsonMap toJson() => _withoutNulls({
        'fonte': source,
        'dataImagem': imageDate,
        'pilotoId': _text(pilotId),
        'satelite': _text(satellite),
        'qualidade': _text(quality),
        'estadioFenologico': _text(phenologicalStage),
        'observacoes': _text(notes),
        'imagemMapeamentoPath': _text(mappingImagePath),
      });
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.oldValues,
    required this.newValues,
    required this.createdAt,
  });

  factory AuditEntry.fromJson(JsonMap json) => AuditEntry(
        id: _int(json['id']) ?? 0,
        entity: _string(json['entidade']) ?? '',
        entityId: _string(json['entidadeId']) ?? '',
        userId: _string(json['usuarioId']),
        userName: _string(json['usuarioNome']) ?? '',
        action: _string(json['acao']) ?? '',
        oldValues: _map(json['valoresAntigos']),
        newValues: _map(json['valoresNovos']),
        createdAt: _string(json['createdAt']) ?? '',
      );

  final int id;
  final String entity;
  final String entityId;
  final String? userId;
  final String userName;
  final String action;
  final JsonMap? oldValues;
  final JsonMap? newValues;
  final String createdAt;
}

class FeedbackReport {
  const FeedbackReport({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.attachmentKey,
    required this.issueNumber,
    required this.active,
    required this.createdAt,
  });

  factory FeedbackReport.fromJson(JsonMap json) => FeedbackReport(
        id: _string(json['id']) ?? '',
        userId: _string(json['usuarioId']) ?? '',
        userName: _string(json['usuarioNome']) ?? '',
        type: _string(json['tipo']) ?? '',
        title: _string(json['titulo']) ?? '',
        description: _string(json['descricao']) ?? '',
        attachmentKey: _string(json['anexoChave']),
        issueNumber: _int(json['issueNumero']),
        active: _bool(json['ativo'], fallback: true),
        createdAt: _string(json['createdAt']) ?? '',
      );

  final String id;
  final String userId;
  final String userName;
  final String type;
  final String title;
  final String description;
  final String? attachmentKey;
  final int? issueNumber;
  final bool active;
  final String createdAt;
}

class FeedbackInput {
  const FeedbackInput({
    required this.type,
    required this.title,
    required this.description,
    this.attachmentKey,
  });

  final String type;
  final String title;
  final String description;
  final String? attachmentKey;

  JsonMap toJson() => _withoutNulls({
        'tipo': type,
        'titulo': title.trim(),
        'descricao': description.trim(),
        'anexoChave': _text(attachmentKey),
      });
}

class UploadedFile {
  const UploadedFile({
    required this.key,
    required this.size,
    required this.contentType,
  });

  factory UploadedFile.fromJson(JsonMap json) => UploadedFile(
        key: _string(json['chave']) ?? '',
        size: _int(json['tamanho']) ?? 0,
        contentType: _string(json['contentType']) ?? 'application/octet-stream',
      );

  final String key;
  final int size;
  final String contentType;
}

class DownloadedFile {
  const DownloadedFile({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String contentType;
  final String fileName;
}

String? _string(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value, {bool fallback = false}) {
  return value is bool ? value : fallback;
}

JsonMap? _map(Object? value) {
  return value is Map ? Map<String, dynamic>.from(value) : null;
}

JsonMap _withoutNulls(JsonMap values) {
  return Map<String, dynamic>.fromEntries(
    values.entries.where((entry) => entry.value != null),
  );
}
