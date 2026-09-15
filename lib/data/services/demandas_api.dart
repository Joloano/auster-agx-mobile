import '../models/demanda_models.dart';
import 'api_client.dart';

abstract class DemandasRemoteDataSource {
  Future<DemandaDetail> getDetail(String id);

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

class StatusFluxo {
  const StatusFluxo({
    required this.ordem,
    required this.transicoesValidas,
    required this.exigeDadosPreenchidos,
    required this.exigeMapeamentoConcluido,
  });

  factory StatusFluxo.fromJson(Map<String, dynamic> json) {
    final rawTransitions =
        json['transicoesValidas'] as Map<String, dynamic>? ?? const {};
    return StatusFluxo(
      ordem: _stringList(json['ordem']),
      transicoesValidas: rawTransitions.map(
        (key, value) => MapEntry(key, _stringList(value)),
      ),
      exigeDadosPreenchidos: _stringList(json['exigeDadosPreenchidos']),
      exigeMapeamentoConcluido: _stringList(json['exigeMapeamentoConcluido']),
    );
  }

  final List<String> ordem;
  final Map<String, List<String>> transicoesValidas;
  final List<String> exigeDadosPreenchidos;
  final List<String> exigeMapeamentoConcluido;
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item as String)
      .toList();
}
