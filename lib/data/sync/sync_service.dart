import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/network_status.dart';
import '../local/app_database.dart';
import '../models/demanda_models.dart';
import '../services/demandas_api.dart';

class SyncService {
  SyncService({
    required AppDatabase database,
    required DemandasRemoteDataSource demandasApi,
    required ConnectivityStatus networkStatus,
  })  : _database = database,
        _demandasApi = demandasApi,
        _networkStatus = networkStatus;

  final AppDatabase _database;
  final DemandasRemoteDataSource _demandasApi;
  final ConnectivityStatus _networkStatus;
  StreamSubscription<bool>? _subscription;
  bool _running = false;

  void start() {
    _subscription ??= _networkStatus.onlineChanges.listen((online) {
      if (online) unawaited(processPending());
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> processPending() async {
    if (_running || !await _networkStatus.isOnline()) return;
    _running = true;
    try {
      final operations = await _database.readPendingSyncOperations();
      for (final operation in operations) {
        try {
          await _process(operation);
          await _database.markSyncDone(operation.id);
        } on DioException {
          await _database.markSyncFailed(operation.id);
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<int> pendingCount() {
    return _database.countPendingSyncOperations();
  }

  Future<void> _process(SyncQueueItem operation) async {
    if (operation.operationType == 'update_demanda' &&
        operation.entity == 'demanda') {
      final updated = await _demandasApi.update(
        operation.entityId,
        DemandaUpdateInput(
          tipo: operation.payload['tipo'] as String,
          representanteId: operation.payload['representanteId'] as String?,
          prazo: operation.payload['prazo'] as String?,
          areaDeInteresse: operation.payload['areaDeInteresse'] as String?,
          status: operation.payload['status'] as String?,
          situacaoDados: operation.payload['situacaoDados'] as String?,
          situacaoMapeamento:
              operation.payload['situacaoMapeamento'] as String?,
          retrabalho: operation.payload['retrabalho'] as bool?,
        ),
      );
      final cachedDetail =
          await _database.readDemandaDetail(operation.entityId);
      if (cachedDetail != null) {
        await _database.saveDemandaDetail(
          cachedDetail.copyWith(demanda: updated),
        );
      }
      await _database.updateCachedDashboardDemand(updated);
      return;
    }

    throw AppException(
      'Operação de sincronização desconhecida: ${operation.operationType}',
    );
  }
}
