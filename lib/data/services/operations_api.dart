import 'package:dio/dio.dart';

import '../models/page_response.dart';
import 'api_client.dart';

class OperationsApi {
  OperationsApi(this._client);

  final ApiClient _client;

  Future<PageResponse<JsonMap>> getPage(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      path,
      queryParameters: _withoutNulls(query),
    );
    return PageResponse<JsonMap>.fromJson(response.data!, (json) => json);
  }

  Future<List<JsonMap>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.get<dynamic>(
      path,
      queryParameters: _withoutNulls(query),
    );
    final data = response.data;
    final rawItems = switch (data) {
      List<dynamic> values => values,
      Map<String, dynamic> page when page['conteudo'] is List<dynamic> =>
        page['conteudo'] as List<dynamic>,
      _ => const <dynamic>[],
    };
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<JsonMap> getRecord(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      path,
      queryParameters: _withoutNulls(query),
    );
    return response.data!;
  }

  Future<JsonMap?> getOptionalRecord(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.get<dynamic>(
      path,
      queryParameters: _withoutNulls(query),
    );
    final data = response.data;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<JsonMap> postRecord(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.post<JsonMap>(
      path,
      data: data,
      queryParameters: _withoutNulls(query),
    );
    return response.data!;
  }

  Future<JsonMap?> postOptionalRecord(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.post<dynamic>(
      path,
      data: data,
      queryParameters: _withoutNulls(query),
    );
    final value = response.data;
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<JsonMap> patchRecord(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.patch<JsonMap>(
      path,
      data: data,
      queryParameters: _withoutNulls(query),
    );
    return response.data!;
  }

  Future<void> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    await _client.dio.patch<void>(
      path,
      data: data,
      queryParameters: _withoutNulls(query),
    );
  }

  Future<void> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    await _client.dio.post<void>(
      path,
      data: data,
      queryParameters: _withoutNulls(query),
    );
  }

  Future<void> delete(String path, {Object? data}) async {
    await _client.dio.delete<void>(path, data: data);
  }

  Future<String> getText(String path) async {
    final response = await _client.dio.get<String>(
      path,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }
}

Map<String, dynamic>? _withoutNulls(Map<String, dynamic>? values) {
  if (values == null) return null;
  return Map<String, dynamic>.fromEntries(
    values.entries.where((entry) => entry.value != null),
  );
}
