import 'package:dio/dio.dart';

import '../../../core/network/network_status.dart';
import '../local/app_database.dart';
import '../models/demanda_models.dart';
import '../models/demanda_status_rules.dart';
import '../services/demandas_api.dart';

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
    return updateFields(current: current, status: status);
  }

  Future<DemandaDetail> updateFields({
    required DemandaDetail current,
    String? status,
    String? situacaoDados,
    String? situacaoMapeamento,
  }) async {
    final optimistic = current.copyWith(
      demanda: current.demanda.copyWith(
        statusChave: status,
        status: status == null ? null : _statusLabel(status),
        situacaoDados: situacaoDados,
        situacaoMapeamento: situacaoMapeamento,
      ),
    );
    await _database.saveDemandaDetail(optimistic);
    await _database.updateCachedDashboardDemand(optimistic.demanda);

    final input = DemandaUpdateInput(
      tipo: current.demanda.tipo,
      representanteId: current.demanda.representanteId,
      prazo: current.demanda.prazo,
      areaDeInteresse: current.demanda.areaDeInteresse,
      status: status,
      situacaoDados: situacaoDados ?? current.demanda.situacaoDados,
      situacaoMapeamento:
          situacaoMapeamento ?? current.demanda.situacaoMapeamento,
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
      await _database.updateCachedDashboardDemand(synced.demanda);
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
    final cached = await _database.readStatusFluxo();
    if (await _networkStatus.isOnline()) {
      try {
        final remote = await _api.getStatusFluxo();
        await _database.saveStatusFluxo(remote);
        return remote;
      } catch (_) {
        return cached;
      }
    }
    return cached;
  }

  Future<List<DemandaStatusHistorico>> loadHistoricoStatus(String id) async {
    final cached = await _database.readDemandaStatusHistory(id);
    if (await _networkStatus.isOnline()) {
      try {
        final remote = await _api.getHistoricoStatus(id);
        await _database.saveDemandaStatusHistory(id, remote);
        return remote;
      } catch (_) {
        return cached;
      }
    }
    return cached;
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
    return statusDemandaLabel(status);
  }
}
