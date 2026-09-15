import '../../../core/database/app_database.dart';
import '../../../core/network/network_status.dart';
import '../domain/dashboard_models.dart';
import 'dashboard_api.dart';

class DashboardRepository {
  DashboardRepository({
    required DashboardApi api,
    required AppDatabase database,
    required ConnectivityStatus networkStatus,
  })  : _api = api,
        _database = database,
        _networkStatus = networkStatus;

  final DashboardApi _api;
  final AppDatabase _database;
  final ConnectivityStatus _networkStatus;

  Future<DashboardOverview?> loadOverview() async {
    final cached = await _database.readDashboardOverview();
    if (await _networkStatus.isOnline()) {
      try {
        final remote = await _api.getOverview();
        await _database.saveDashboardOverview(remote);
        return remote;
      } catch (_) {
        return cached;
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
      } catch (_) {
        return cached;
      }
    }
    return cached;
  }
}
