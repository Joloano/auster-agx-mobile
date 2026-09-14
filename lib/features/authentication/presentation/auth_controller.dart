import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_user.dart';
import '../providers/auth_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  Future<void> login(String email, String senha) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email, senha);
      return session.user;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
