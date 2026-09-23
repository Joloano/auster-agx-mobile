import '../models/agronomic_models.dart';
import '../models/page_response.dart';
import 'api_client.dart';

class AgronomicApi {
  AgronomicApi(this._client);

  final ApiClient _client;

  Future<List<Culture>> listCultures({String? group}) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/culturas',
      queryParameters: {if (_hasText(group)) 'grupo': group},
    );
    return _models(response.data, Culture.fromJson);
  }

  Future<Culture> getCulture(int id) async {
    final response = await _client.dio.get<JsonMap>('/culturas/$id');
    return Culture.fromJson(response.data!);
  }

  Future<Culture> createCulture(CultureInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/culturas',
      data: input.toJson(),
    );
    return Culture.fromJson(response.data!);
  }

  Future<Culture> updateCulture(int id, CultureInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/culturas/$id',
      data: input.toJson(),
    );
    return Culture.fromJson(response.data!);
  }

  Future<void> deactivateCulture(int id) async {
    await _client.dio.patch<void>('/culturas/$id/desativar');
  }

  Future<PageResponse<PhenologicalStage>> listPhenologicalStages({
    int? cultureId,
    int page = 0,
    int pageSize = 300,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/estadios-fenologicos',
      queryParameters: {
        if (cultureId != null) 'culturaId': cultureId,
        'pagina': page,
        'tamanho': pageSize,
      },
    );
    return PageResponse<PhenologicalStage>.fromJson(
      response.data!,
      PhenologicalStage.fromJson,
    );
  }

  Future<PhenologicalStage> createPhenologicalStage(
    PhenologicalStageInput input,
  ) async {
    final response = await _client.dio.post<JsonMap>(
      '/estadios-fenologicos',
      data: input.toJson(),
    );
    return PhenologicalStage.fromJson(response.data!);
  }

  Future<PhenologicalStage> updatePhenologicalStage(
    int id,
    String name,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/estadios-fenologicos/$id',
      data: PhenologicalStageInput(name: name).toJson(nameOnly: true),
    );
    return PhenologicalStage.fromJson(response.data!);
  }

  Future<void> deactivatePhenologicalStage(int id) async {
    await _client.dio.patch<void>('/estadios-fenologicos/$id/desativar');
  }

  Future<List<Cultivation>> listCultivations(
    String fieldId, {
    bool? active,
  }) async {
    final page = await _getPage(
      '/cultivos',
      {'talhaoId': fieldId, if (active != null) 'ativo': active},
      Cultivation.fromJson,
    );
    return page.items;
  }

  Future<Cultivation> createCultivation(CultivationInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/cultivos',
      data: input.toJson(includeRelations: true),
    );
    return Cultivation.fromJson(response.data!);
  }

  Future<Cultivation> updateCultivation(
    String id,
    CultivationInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/cultivos/$id',
      data: input.toJson(includeRelations: false),
    );
    return Cultivation.fromJson(response.data!);
  }

  Future<void> deactivateCultivation(String id) async {
    await _client.dio.patch<void>('/cultivos/$id/desativar');
  }

  Future<List<PreviousCrop>> listPreviousCrops(String fieldId) async {
    final page = await _getPage(
      '/culturas-antecessoras',
      {'talhaoId': fieldId},
      PreviousCrop.fromJson,
    );
    return page.items;
  }

  Future<PreviousCrop> createPreviousCrop(PreviousCropInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/culturas-antecessoras',
      data: input.toJson(includeRelations: true),
    );
    return PreviousCrop.fromJson(response.data!);
  }

  Future<PreviousCrop> updatePreviousCrop(
    String id,
    PreviousCropInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/culturas-antecessoras/$id',
      data: input.toJson(includeRelations: false),
    );
    return PreviousCrop.fromJson(response.data!);
  }

  Future<void> deactivatePreviousCrop(String id) async {
    await _client.dio.patch<void>('/culturas-antecessoras/$id/desativar');
  }

  Future<List<SoilData>> listSoilData(String fieldId) async {
    final page = await _getPage(
      '/dados-solo',
      {'talhaoId': fieldId},
      SoilData.fromJson,
    );
    return page.items;
  }

  Future<SoilData> createSoilData(SoilDataInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/dados-solo',
      data: input.toJson(includeField: true),
    );
    return SoilData.fromJson(response.data!);
  }

  Future<SoilData> updateSoilData(String id, SoilDataInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/dados-solo/$id',
      data: input.toJson(includeField: false),
    );
    return SoilData.fromJson(response.data!);
  }

  Future<void> deactivateSoilData(String id) async {
    await _client.dio.patch<void>('/dados-solo/$id/desativar');
  }

  Future<List<Fertilization>> listFertilizations(String demandId) async {
    final page = await _getPage(
      '/adubacoes',
      {'demandaId': demandId, 'tamanho': 50},
      Fertilization.fromJson,
    );
    return page.items;
  }

  Future<Fertilization> createFertilization(FertilizationInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/adubacoes',
      data: input.toJson(includeDemand: true),
    );
    return Fertilization.fromJson(response.data!);
  }

  Future<Fertilization> updateFertilization(
    String id,
    FertilizationInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/adubacoes/$id',
      data: input.toJson(includeDemand: false),
    );
    return Fertilization.fromJson(response.data!);
  }

  Future<void> deactivateFertilization(String id) async {
    await _client.dio.patch<void>('/adubacoes/$id/desativar');
  }

  Future<NitrogenManagement?> getNitrogenManagement(String demandId) {
    return _getNullable(
      '/manejo-nitrogenio',
      {'demandaId': demandId},
      NitrogenManagement.fromJson,
    );
  }

  Future<NitrogenManagement> createNitrogenManagement(
    NitrogenManagementInput input,
  ) async {
    final response = await _client.dio.post<JsonMap>(
      '/manejo-nitrogenio',
      data: input.toJson(includeDemand: true),
    );
    return NitrogenManagement.fromJson(response.data!);
  }

  Future<NitrogenManagement> updateNitrogenManagement(
    String id,
    NitrogenManagementInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/manejo-nitrogenio/$id',
      data: input.toJson(includeDemand: false),
    );
    return NitrogenManagement.fromJson(response.data!);
  }

  Future<void> deactivateNitrogenManagement(String id) async {
    await _client.dio.patch<void>('/manejo-nitrogenio/$id/desativar');
  }

  Future<SmartBrakePrescription?> getSmartBrakePrescription(String demandId) {
    return _getNullable(
      '/prescricoes-smart-brake',
      {'demandaId': demandId},
      SmartBrakePrescription.fromJson,
    );
  }

  Future<SmartBrakePrescription> createSmartBrakePrescription(
    SmartBrakePrescriptionInput input,
  ) async {
    final response = await _client.dio.post<JsonMap>(
      '/prescricoes-smart-brake',
      data: input.toJson(includeDemand: true),
    );
    return SmartBrakePrescription.fromJson(response.data!);
  }

  Future<SmartBrakePrescription> updateSmartBrakePrescription(
    String id,
    SmartBrakePrescriptionInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/prescricoes-smart-brake/$id',
      data: input.toJson(includeDemand: false),
    );
    return SmartBrakePrescription.fromJson(response.data!);
  }

  Future<void> deactivateSmartBrakePrescription(String id) async {
    await _client.dio.patch<void>('/prescricoes-smart-brake/$id/desativar');
  }

  Future<SmartSeedingPrescription?> getSmartSeedingPrescription(
    String demandId,
  ) {
    return _getNullable(
      '/prescricoes-smart-seeding',
      {'demandaId': demandId},
      SmartSeedingPrescription.fromJson,
    );
  }

  Future<SmartSeedingPrescription> createSmartSeedingPrescription(
    SmartSeedingPrescriptionInput input,
  ) async {
    final response = await _client.dio.post<JsonMap>(
      '/prescricoes-smart-seeding',
      data: input.toJson(includeDemand: true),
    );
    return SmartSeedingPrescription.fromJson(response.data!);
  }

  Future<SmartSeedingPrescription> updateSmartSeedingPrescription(
    String id,
    SmartSeedingPrescriptionInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/prescricoes-smart-seeding/$id',
      data: input.toJson(includeDemand: false),
    );
    return SmartSeedingPrescription.fromJson(response.data!);
  }

  Future<void> deactivateSmartSeedingPrescription(String id) async {
    await _client.dio.patch<void>('/prescricoes-smart-seeding/$id/desativar');
  }

  Future<PageResponse<T>> _getPage<T>(
    String path,
    JsonMap query,
    T Function(JsonMap) fromJson,
  ) async {
    final response = await _client.dio.get<JsonMap>(
      path,
      queryParameters: {'pagina': 0, 'tamanho': 200, ...query},
    );
    return PageResponse<T>.fromJson(response.data!, fromJson);
  }

  Future<T?> _getNullable<T>(
    String path,
    JsonMap query,
    T Function(JsonMap) fromJson,
  ) async {
    final response = await _client.dio.get<JsonMap?>(
      path,
      queryParameters: query,
    );
    final data = response.data;
    return data == null ? null : fromJson(data);
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
