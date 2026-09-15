import 'package:dio/dio.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/network_status.dart';
import '../domain/demanda_models.dart';
import 'demandas_api.dart';

class DemandaRepository {
  DemandaRepository({
    required DemandasRemoteDataSource api,
    required AppDatabase database,
    required ConnectivityStatus networkStatus,
  })  : _api = api,
        _database = database,
        _networkStatus = networkStatus;

  final DemandasRemoteDataSource _api;
  final AppDatabase _database;
  final ConnectivityStatus _networkStatus;

  Future<DemandaDetail?> loadDetail(String id) async {
    final cached = await _database.readDemandaDetail(id);
    if (await _networkStatus.isOnline()) {
      try {
        final remote = await _api.getDetail(id);
        await _database.saveDemandaDetail(remote);
        return remote;
      } catch (_) {
        return cached;
      }
    }
    return cached;
  }

  Future<DemandaDetail> updateStatus({
    required DemandaDetail current,
    required String status,
  }) async {
    final optimistic = current.copyWith(
      demanda: current.demanda.copyWith(
        statusChave: status,
        status: _statusLabel(status),
      ),
    );
    await _database.saveDemandaDetail(optimistic);

    final input = DemandaUpdateInput(
      tipo: current.demanda.tipo,
      representanteId: current.demanda.representanteId,
      prazo: current.demanda.prazo,
      areaDeInteresse: current.demanda.areaDeInteresse,
      status: status,
      situacaoDados: current.demanda.situacaoDados,
      situacaoMapeamento: current.demanda.situacaoMapeamento,
      retrabalho: current.demanda.retrabalho,
    );

    if (!await _networkStatus.isOnline()) {
      await _enqueueUpdate(current.demanda.id, input);
      return optimistic;
    }

    try {
      final updated = await _api.update(current.demanda.id, input);
      final synced = current.copyWith(demanda: updated);
      await _database.saveDemandaDetail(synced);
      return synced;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        await _enqueueUpdate(current.demanda.id, input);
        return optimistic;
      }
      rethrow;
    }
  }

  Future<StatusFluxo?> loadStatusFluxo() async {
    try {
      return await _api.getStatusFluxo();
    } catch (_) {
      return null;
    }
  }

  Future<void> _enqueueUpdate(String demandaId, DemandaUpdateInput input) {
    return _database.enqueueSyncOperation(
      operationType: 'update_demanda',
      entity: 'demanda',
      entityId: demandaId,
      payload: input.toJson(),
    );
  }

  String _statusLabel(String status) {
    return statusLabels[status] ?? status;
  }
}

const statusLabels = {
  'LISTADA': 'Listada',
  'AGENDADA': 'Agendada',
  'LIBERADO_PARA_PRESCRICAO': 'Liberado para prescricao',
  'PREPARACAO_DE_DADOS': 'Preparacao de dados',
  'PRESCRICAO_EM_ANDAMENTO': 'Prescricao em andamento',
  'PRESCRICAO_EM_REVISAO': 'Prescricao em revisao',
  'LIBERADO_PARA_ENTREGA': 'Liberado para a entrega',
  'ENTREGUE': 'Entregue',
  'CANCELADA': 'Cancelada',
};
