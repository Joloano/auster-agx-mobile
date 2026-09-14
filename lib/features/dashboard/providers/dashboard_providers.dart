import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = FutureProvider<DashboardRepository>((
  ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return DashboardRepository(
    api: ref.watch(dashboardApiProvider),
    database: database,
    networkStatus: ref.watch(networkStatusProvider),
  );
});

final dashboardOverviewProvider = FutureProvider<DashboardOverview?>((
  ref,
) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.loadOverview();
});

final dashboardDemandasProvider = FutureProvider<List<DashboardDemandItem>>((
  ref,
) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.loadDemandas();
});
