import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/page_response.dart';
import '../models/system_models.dart';
import 'api_client.dart';

class SystemApi {
  SystemApi(this._client);

  final ApiClient _client;

  Future<List<RemoteSensing>> listRemoteSensing({
    String? source,
    bool pendingOnly = false,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      pendingOnly
          ? '/sensoriamentos-remotos/pendentes-mapeamento'
          : '/sensoriamentos-remotos',
      queryParameters: {if (_hasText(source)) 'fonte': source},
    );
    return _models(response.data, RemoteSensing.fromJson);
  }

  Future<RemoteSensing> updateRemoteSensing(
    String id,
    RemoteSensingUpdateInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/sensoriamentos-remotos/$id',
      data: input.toJson(),
    );
    return RemoteSensing.fromJson(response.data!);
  }

  Future<void> deactivateRemoteSensing(String id) async {
    await _client.dio.patch<void>('/sensoriamentos-remotos/$id/desativar');
  }

  Future<void> startFlight(String id) async {
    await _client.dio.patch<void>('/sensoriamentos-remotos/$id/iniciar-voo');
  }

  Future<RemoteSensing> updateMappingStatus(
    String id,
    String status, {
    String? mappingImagePath,
  }) async {
    final response = await _client.dio.patch<JsonMap>(
      '/sensoriamentos-remotos/$id/status-mapeamento',
      data: {
        'status': status,
        if (_hasText(mappingImagePath))
          'imagemMapeamentoPath': mappingImagePath,
      },
    );
    return RemoteSensing.fromJson(response.data!);
  }

  Future<PageResponse<AuditEntry>> listAudit({
    String? entity,
    String? entityId,
    String? userId,
    String? action,
    String? from,
    String? to,
    int page = 0,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/auditoria',
      queryParameters: {
        if (_hasText(entity)) 'entidade': entity,
        if (_hasText(entityId)) 'entidadeId': entityId,
        if (_hasText(userId)) 'usuarioId': userId,
        if (_hasText(action)) 'acao': action,
        if (_hasText(from)) 'de': from,
        if (_hasText(to)) 'ate': to,
        'pagina': page,
        'tamanho': pageSize,
      },
    );
    return PageResponse<AuditEntry>.fromJson(
      response.data!,
      AuditEntry.fromJson,
    );
  }

  Future<List<String>> listAuditedEntities() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/auditoria/entidades',
    );
    return (response.data ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
  }

  Future<PageResponse<FeedbackReport>> listFeedback({
    String? type,
    bool? pending,
    bool? discardedOnly,
    int page = 0,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/feedbacks',
      queryParameters: {
        if (_hasText(type)) 'tipo': type,
        if (pending != null) 'pendentes': pending,
        if (discardedOnly != null) 'apenasDescartados': discardedOnly,
        'pagina': page,
        'tamanho': pageSize,
      },
    );
    return PageResponse<FeedbackReport>.fromJson(
      response.data!,
      FeedbackReport.fromJson,
    );
  }

  Future<FeedbackReport> createFeedback(FeedbackInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/feedbacks',
      data: input.toJson(),
    );
    return FeedbackReport.fromJson(response.data!);
  }

  Future<FeedbackReport> updateFeedbackIssue(
    String id,
    int issueNumber,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/feedbacks/$id',
      data: {'issueNumero': issueNumber},
    );
    return FeedbackReport.fromJson(response.data!);
  }

  Future<void> deactivateFeedback(String id) async {
    await _client.dio.patch<void>('/feedbacks/$id/desativar');
  }

  Future<String> getFeedbackIssueMarkdown(String id) async {
    final response = await _client.dio.get<String>(
      '/feedbacks/$id/issue.md',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Future<Map<String, List<String>>> getAllowedFileTypes() async {
    final response = await _client.dio.get<JsonMap>('/arquivos/tipos');
    return response.data!.map(
      (key, value) => MapEntry(
        key,
        value is List
            ? value.map((item) => item.toString()).toList(growable: false)
            : const <String>[],
      ),
    );
  }

  Future<UploadedFile> uploadFile({
    required String type,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final form = FormData.fromMap({
      'arquivo': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.dio.post<JsonMap>(
      '/arquivos',
      queryParameters: {'tipo': type},
      data: form,
    );
    return UploadedFile.fromJson(response.data!);
  }

  Future<DownloadedFile> downloadFile(String key) async {
    final response = await _client.dio.get<List<int>>(
      '/arquivos/$key',
      options: Options(responseType: ResponseType.bytes),
    );
    final fileName = key.split('/').last;
    return DownloadedFile(
      bytes: Uint8List.fromList(response.data ?? const []),
      contentType: response.headers.value(Headers.contentTypeHeader) ??
          'application/octet-stream',
      fileName: fileName.isEmpty ? 'arquivo' : fileName,
    );
  }

  Future<bool> getGoogleDriveStatus() async {
    final response = await _client.dio.get<JsonMap>('/google/status');
    return response.data?['conectado'] as bool? ?? false;
  }
}

List<T> _models<T>(
  List<dynamic>? values,
  T Function(JsonMap) fromJson,
) {
  return (values ?? const [])
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
