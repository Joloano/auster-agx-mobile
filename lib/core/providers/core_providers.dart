import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/local/app_database.dart';
import '../../data/services/api_client.dart';
import '../../data/services/auth_user_storage.dart';
import '../../data/services/token_storage.dart';
import '../auth/auth_session_events.dart';
import '../config/app_config.dart';
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

final authUserStorageProvider = Provider<AuthUserStorage>((ref) {
  return AuthUserStorage(ref.watch(secureStorageProvider));
});

final authSessionEventsProvider = Provider<AuthSessionEvents>((ref) {
  final events = AuthSessionEvents();
  ref.onDispose(() => unawaited(events.dispose()));
  return events;
});

final networkStatusProvider = Provider<NetworkStatus>((ref) {
  return NetworkStatus(Connectivity());
});

final onlineStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(networkStatusProvider).onlineChanges;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    sessionEvents: ref.watch(authSessionEventsProvider),
  );
  ref.onDispose(client.close);
  return client;
});

final appDatabaseProvider =
    FutureProvider.autoDispose.family<AppDatabase, String>((ref, userId) async {
  final database = await AppDatabase.openForUser(userId);
  ref.onDispose(database.dispose);
  return database;
});
