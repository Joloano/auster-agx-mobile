import '../models/dashboard_models.dart';
import 'api_client.dart';

class DashboardApi {
  DashboardApi(this._client);

  final ApiClient _client;

  Future<DashboardOverview> getOverview() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/dashboard/resumo',
    );
    return DashboardOverview.fromJson(response.data!);
  }

  Future<PageResponse<DashboardDemandItem>> listDemandasPainel({
    bool arquivada = false,
    int pagina = 0,
    int tamanho = 100,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/dashboard/demandas',
      queryParameters: {
        'arquivada': arquivada,
        'pagina': pagina,
        'tamanho': tamanho,
      },
    );
    return PageResponse.fromJson(response.data!, DashboardDemandItem.fromJson);
  }
}
