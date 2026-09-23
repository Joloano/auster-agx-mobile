import '../models/commercial_models.dart';
import '../models/demanda_models.dart';
import '../models/page_response.dart';
import 'api_client.dart';

class CommercialApi {
  CommercialApi(this._client);

  final ApiClient _client;

  Future<PageResponse<Order>> listOrders({
    int page = 0,
    int pageSize = 20,
    String? clientId,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/pedidos',
      queryParameters: {
        'pagina': page,
        'tamanho': pageSize,
        if (clientId != null && clientId.isNotEmpty) 'clienteId': clientId,
      },
    );
    return PageResponse<Order>.fromJson(response.data!, Order.fromJson);
  }

  Future<Order> getOrder(String id) async {
    final response = await _client.dio.get<JsonMap>('/pedidos/$id');
    return Order.fromJson(response.data!);
  }

  Future<Order> createOrder(OrderInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/pedidos',
      data: input.toCreateJson(),
    );
    return Order.fromJson(response.data!);
  }

  Future<Order> updateOrder(String id, OrderInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/pedidos/$id',
      data: input.toUpdateJson(),
    );
    return Order.fromJson(response.data!);
  }

  Future<void> deactivateOrder(String id) async {
    await _client.dio.patch<void>('/pedidos/$id/desativar');
  }

  Future<PageResponse<Demanda>> listDemands({
    int page = 0,
    int pageSize = 200,
    String? orderId,
    String? clientId,
    String? farmId,
    String? fieldId,
    String? status,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/demandas',
      queryParameters: {
        'pagina': page,
        'tamanho': pageSize,
        if (_hasText(orderId)) 'pedidoId': orderId,
        if (_hasText(clientId)) 'clienteId': clientId,
        if (_hasText(farmId)) 'fazendaId': farmId,
        if (_hasText(fieldId)) 'talhaoId': fieldId,
        if (_hasText(status)) 'status': status,
      },
    );
    return PageResponse<Demanda>.fromJson(response.data!, Demanda.fromJson);
  }

  Future<Demanda> createDemand(DemandCreateInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/demandas',
      data: input.toJson(),
    );
    return Demanda.fromJson(response.data!);
  }

  Future<Demanda> updateDemand(String id, DemandaUpdateInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/demandas/$id',
      data: input.toJson(),
    );
    return Demanda.fromJson(response.data!);
  }

  Future<void> deactivateDemand(String id) async {
    await _client.dio.patch<void>('/demandas/$id/desativar');
  }

  Future<void> setDemandGroup(
    String demandId,
    String groupId, {
    required bool associated,
  }) async {
    final path = '/demandas/$demandId/grupos/$groupId';
    if (associated) {
      await _client.dio.post<void>(path);
    } else {
      await _client.dio.delete<void>(path);
    }
  }

  Future<void> setDemandRemoteSensing(
    String demandId,
    String remoteSensingId, {
    required bool associated,
  }) async {
    final path = '/demandas/$demandId/sensoriamentos/$remoteSensingId';
    if (associated) {
      await _client.dio.post<void>(path);
    } else {
      await _client.dio.delete<void>(path);
    }
  }

  Future<SensoriamentoResumo> createRemoteSensing(
    String demandId,
    RemoteSensingCreateInput input,
  ) async {
    final response = await _client.dio.post<JsonMap>(
      '/demandas/$demandId/sensoriamentos',
      data: input.toJson(),
    );
    return SensoriamentoResumo.fromJson(response.data!);
  }

  Future<List<String>> listContractedTypes(String farmId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/demandas/tipos-contratados',
      queryParameters: {'fazendaId': farmId},
    );
    return response.data!
        .map((item) => item.toString())
        .toList(growable: false);
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
