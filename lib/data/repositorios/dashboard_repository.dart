import '../../core/network/api_failure_policy.dart';
import '../../core/network/network_status.dart';
import '../local/app_database.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_api.dart';

class DashboardRepository {
  DashboardRepository({
    required DashboardRemoteDataSource api,
    required AppDatabase database,
    required ConnectivityStatus networkStatus,
  })  : _api = api,
        _database = database,
        _networkStatus = networkStatus;

  final DashboardRemoteDataSource _api;
  final AppDatabase _database;
  final ConnectivityStatus _networkStatus;

  Future<DashboardOverview?> loadOverview() async {
    final cached = await _database.readDashboardOverview();
    if (await _networkStatus.isOnline()) {
      try {
        final remote = await _api.getOverview();
        await _database.saveDashboardOverview(remote);
        return remote;
      } catch (error) {
        if (cached != null && ApiFailurePolicy.isTransient(error)) {
          return cached;
        }
        rethrow;
      }
    }
    return cached;
  }

  Future<List<DashboardDemandItem>> loadDemandas() async {
    final cached = await _database.readDashboardItems();
    if (await _networkStatus.isOnline()) {
      try {
        final remote = await _api.listDemandasPainel(tamanho: 200);
        await _database.saveDashboardItems(remote.conteudo);
        return remote.conteudo;
      } catch (error) {
        if (ApiFailurePolicy.isTransient(error)) return cached;
        rethrow;
      }
    }
    return cached;
  }
}
