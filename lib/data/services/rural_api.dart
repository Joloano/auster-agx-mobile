import '../models/page_response.dart';
import '../models/rural_models.dart';
import 'api_client.dart';

class RuralApi {
  RuralApi(this._client);

  final ApiClient _client;

  Future<PageResponse<Client>> listClients({
    int page = 0,
    int pageSize = 20,
    String? tradeName,
    String? userId,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/clientes',
      queryParameters: {
        'pagina': page,
        'tamanho': pageSize,
        if (_hasText(tradeName)) 'nomeFantasia': tradeName!.trim(),
        if (_hasText(userId)) 'usuarioId': userId,
      },
    );
    return PageResponse<Client>.fromJson(response.data!, Client.fromJson);
  }

  Future<Client> getClient(String id) async {
    final response = await _client.dio.get<JsonMap>('/clientes/$id');
    return Client.fromJson(response.data!);
  }

  Future<Client> createClient(ClientInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/clientes',
      data: input.toJson(includeUser: true),
    );
    return Client.fromJson(response.data!);
  }

  Future<Client> updateClient(String id, ClientInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/clientes/$id',
      data: input.toJson(includeUser: false),
    );
    return Client.fromJson(response.data!);
  }

  Future<void> deactivateClient(String id) {
    return _client.dio.patch<void>('/clientes/$id/desativar');
  }

  Future<PageResponse<Farm>> listFarms({
    int page = 0,
    int pageSize = 20,
    String? name,
    String? city,
    String? state,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/fazendas',
      queryParameters: {
        'pagina': page,
        'tamanho': pageSize,
        if (_hasText(name)) 'nome': name!.trim(),
        if (_hasText(city)) 'cidade': city!.trim(),
        if (_hasText(state)) 'uf': state!.trim(),
      },
    );
    return PageResponse<Farm>.fromJson(response.data!, Farm.fromJson);
  }

  Future<Farm> getFarm(String id) async {
    final response = await _client.dio.get<JsonMap>('/fazendas/$id');
    return Farm.fromJson(response.data!);
  }

  Future<Farm> createFarm(FarmInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/fazendas',
      data: input.toJson(),
    );
    return Farm.fromJson(response.data!);
  }

  Future<Farm> updateFarm(String id, FarmInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/fazendas/$id',
      data: input.toJson(),
    );
    return Farm.fromJson(response.data!);
  }

  Future<void> deactivateFarm(String id) {
    return _client.dio.patch<void>('/fazendas/$id/desativar');
  }

  Future<List<ClientFarmLink>> listActiveLinks() async {
    final response = await _client.dio.get<List<dynamic>>('/fazendas/vinculos');
    return response.data!
        .whereType<Map>()
        .map((item) => ClientFarmLink.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<ClientFarmLink> linkClientToFarm({
    required String clientId,
    required String farmId,
    required String startDate,
  }) async {
    final response = await _client.dio.post<JsonMap>(
      '/fazendas/vinculos',
      data: {
        'clienteId': clientId,
        'fazendaId': farmId,
        'dataInicio': startDate,
      },
    );
    return ClientFarmLink.fromJson(response.data!);
  }

  Future<void> closeClientFarmLink(String id, String endDate) {
    return _client.dio.patch<void>(
      '/fazendas/vinculos/$id/encerrar',
      data: {'dataFim': endDate},
    );
  }

  Future<Farm> setFarmCulture(
    String farmId,
    int cultureId, {
    required bool associated,
  }) async {
    final response = associated
        ? await _client.dio.post<JsonMap>(
            '/fazendas/$farmId/culturas/$cultureId',
          )
        : await _client.dio.delete<JsonMap>(
            '/fazendas/$farmId/culturas/$cultureId',
          );
    return Farm.fromJson(response.data!);
  }

  Future<Farm> setFarmEquipment(
    String farmId,
    int equipmentId, {
    required bool associated,
  }) async {
    final response = associated
        ? await _client.dio.post<JsonMap>(
            '/fazendas/$farmId/equipamentos/$equipmentId',
          )
        : await _client.dio.delete<JsonMap>(
            '/fazendas/$farmId/equipamentos/$equipmentId',
          );
    return Farm.fromJson(response.data!);
  }

  Future<PageResponse<FieldPlot>> listFields({
    required String farmId,
    int page = 0,
    int pageSize = 200,
    bool withoutGroup = false,
  }) async {
    final response = await _client.dio.get<JsonMap>(
      '/talhoes',
      queryParameters: {
        'fazendaId': farmId,
        'semGrupo': withoutGroup,
        'pagina': page,
        'tamanho': pageSize,
      },
    );
    return PageResponse<FieldPlot>.fromJson(response.data!, FieldPlot.fromJson);
  }

  Future<FieldPlot> getField(String id) async {
    final response = await _client.dio.get<JsonMap>('/talhoes/$id');
    return FieldPlot.fromJson(response.data!);
  }

  Future<FieldPlot> createField(FieldInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/talhoes',
      data: input.toJson(includeFarm: true),
    );
    return FieldPlot.fromJson(response.data!);
  }

  Future<FieldPlot> updateField(String id, FieldInput input) async {
    final response = await _client.dio.patch<JsonMap>(
      '/talhoes/$id',
      data: input.toJson(includeFarm: false),
    );
    return FieldPlot.fromJson(response.data!);
  }

  Future<void> deactivateField(String id) {
    return _client.dio.patch<void>('/talhoes/$id/desativar');
  }

  Future<List<Collaborator>> listCollaborators({String? farmId}) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/colaboradores',
      queryParameters: {if (_hasText(farmId)) 'fazendaId': farmId},
    );
    return response.data!
        .whereType<Map>()
        .map((item) => Collaborator.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<Collaborator> createCollaborator(CollaboratorInput input) async {
    final response = await _client.dio.post<JsonMap>(
      '/colaboradores',
      data: input.toJson(),
    );
    return Collaborator.fromJson(response.data!);
  }

  Future<Collaborator> updateCollaborator(
    String id,
    CollaboratorInput input,
  ) async {
    final response = await _client.dio.patch<JsonMap>(
      '/colaboradores/$id',
      data: input.toJson(),
    );
    return Collaborator.fromJson(response.data!);
  }

  Future<void> deactivateCollaborator(String id) {
    return _client.dio.patch<void>('/colaboradores/$id/desativar');
  }

  Future<Collaborator> setCollaboratorFarm(
    String collaboratorId,
    String farmId, {
    required bool associated,
  }) async {
    final response = associated
        ? await _client.dio.post<JsonMap>(
            '/colaboradores/$collaboratorId/fazendas/$farmId',
          )
        : await _client.dio.delete<JsonMap>(
            '/colaboradores/$collaboratorId/fazendas/$farmId',
          );
    return Collaborator.fromJson(response.data!);
  }

  Future<List<Equipment>> listEquipment() async {
    final response = await _client.dio.get<List<dynamic>>('/equipamentos');
    return response.data!
        .whereType<Map>()
        .map((item) => Equipment.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<List<FieldGroup>> listGroups() async {
    final response = await _client.dio.get<List<dynamic>>('/grupos');
    return response.data!
        .whereType<Map>()
        .map((item) => FieldGroup.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<FieldGroup> createGroup(String name) async {
    final response = await _client.dio.post<JsonMap>(
      '/grupos',
      data: {'nome': name},
    );
    return FieldGroup.fromJson(response.data!);
  }

  Future<FieldGroup> updateGroup(String id, String name) async {
    final response = await _client.dio.patch<JsonMap>(
      '/grupos/$id',
      data: {'nome': name},
    );
    return FieldGroup.fromJson(response.data!);
  }

  Future<void> deactivateGroup(String id) {
    return _client.dio.patch<void>('/grupos/$id/desativar');
  }

  Future<FieldGroup> setGroupField(
    String groupId,
    String fieldId, {
    required bool associated,
  }) async {
    final response = associated
        ? await _client.dio.post<JsonMap>(
            '/grupos/$groupId/talhoes/$fieldId',
          )
        : await _client.dio.delete<JsonMap>(
            '/grupos/$groupId/talhoes/$fieldId',
          );
    return FieldGroup.fromJson(response.data!);
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
