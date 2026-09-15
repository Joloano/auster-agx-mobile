import '../models/demanda_models.dart';
import '../models/demanda_status_rules.dart';
import 'api_client.dart';

abstract class DemandasRemoteDataSource {
  Future<DemandaDetail> getDetail(String id);

  Future<List<DemandaStatusHistorico>> getHistoricoStatus(String id);

  Future<Demanda> update(String id, DemandaUpdateInput input);

  Future<StatusFluxo> getStatusFluxo();
}

class DemandasApi implements DemandasRemoteDataSource {
  DemandasApi(this._client);

  final ApiClient _client;

  @override
  Future<DemandaDetail> getDetail(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/demandas/$id/detalhe',
    );
    return DemandaDetail.fromJson(response.data!);
  }

  @override
  Future<List<DemandaStatusHistorico>> getHistoricoStatus(String id) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/demandas/$id/historico-status',
    );
    return response.data!
        .map((value) =>
            DemandaStatusHistorico.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Demanda> update(String id, DemandaUpdateInput input) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/demandas/$id',
      data: input.toJson(),
    );
    return Demanda.fromJson(response.data!);
  }

  @override
  Future<StatusFluxo> getStatusFluxo() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/demandas/status-fluxo',
    );
    return StatusFluxo.fromJson(response.data!);
  }
}
