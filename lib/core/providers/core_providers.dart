import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../network/network_status.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final networkStatusProvider = Provider<NetworkStatus>((ref) {
  return NetworkStatus(Connectivity());
});

final onlineStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(networkStatusProvider).onlineChanges;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await AppDatabase.openDefault();
  ref.onDispose(database.dispose);
  return database;
});
