import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/auth_user.dart';
import '../providers/auth_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    final subscription = ref
        .watch(authSessionEventsProvider)
        .sessionExpired
        .listen((_) => _handleSessionExpired());
    ref.onDispose(() => unawaited(subscription.cancel()));
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  void _handleSessionExpired() {
    state = const AsyncData(null);
    unawaited(
      ref.read(authRepositoryProvider).clearLocalSession().catchError((_) {}),
    );
  }

  Future<void> login(String email, String senha) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session =
          await ref.read(authRepositoryProvider).login(email, senha);
      return session.user;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> changePassword({
    String? senhaAtual,
    required String novaSenha,
  }) async {
    final user = await ref.read(authRepositoryProvider).changePassword(
          senhaAtual: senhaAtual,
          novaSenha: novaSenha,
        );
    state = AsyncData(user);
  }

  void applyUser(AuthUser user) {
    state = AsyncData(user);
  }
}
