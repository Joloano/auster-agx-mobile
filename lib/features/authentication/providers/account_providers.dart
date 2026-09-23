import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/repositorios/account_repository.dart';
import '../../../data/services/account_api.dart';

final accountApiProvider = Provider<AccountApi>((ref) {
  return AccountApi(ref.watch(apiClientProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    api: ref.watch(accountApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    userStorage: ref.watch(authUserStorageProvider),
  );
});

final managedUsersProvider = FutureProvider.autoDispose
    .family<List<AuthUser>, bool>((ref, includeInactive) {
  return ref
      .watch(accountRepositoryProvider)
      .listUsers(includeInactive: includeInactive);
});
