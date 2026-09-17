import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../features/authentication/providers/current_user_provider.dart';
import '../../features/demandas/providers/demandas_providers.dart';
import 'sync_service.dart';

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final database = await ref.watch(appDatabaseProvider(userId).future);
  final service = SyncService(
    database: database,
    demandasApi: ref.watch(demandasApiProvider),
    networkStatus: ref.watch(networkStatusProvider),
  );
  service.start();
  ref.onDispose(() {
    unawaited(service.stop());
  });
  return service;
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final service = await ref.watch(syncServiceProvider.future);
  return service.pendingCount();
});
