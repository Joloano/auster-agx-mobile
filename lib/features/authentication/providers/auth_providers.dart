import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/auth_api.dart';
import '../../../data/repositorios/auth_repository.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    userStorage: ref.watch(authUserStorageProvider),
  );
});
