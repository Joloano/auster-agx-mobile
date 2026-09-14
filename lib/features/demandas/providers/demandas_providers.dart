import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/demanda_repository.dart';
import '../data/demandas_api.dart';
import '../domain/demanda_models.dart';

final demandasApiProvider = Provider<DemandasApi>((ref) {
  return DemandasApi(ref.watch(apiClientProvider));
});

final demandaRepositoryProvider = FutureProvider<DemandaRepository>((
  ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return DemandaRepository(
    api: ref.watch(demandasApiProvider),
    database: database,
    networkStatus: ref.watch(networkStatusProvider),
  );
});

final demandaDetailProvider = FutureProvider.family<DemandaDetail?, String>((
  ref,
  id,
) async {
  final repository = await ref.watch(demandaRepositoryProvider.future);
  return repository.loadDetail(id);
});
