import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auster_agx_mobile/app/auster_mobile_app.dart';
import 'package:auster_agx_mobile/core/auth/auth_tokens.dart';
import 'package:auster_agx_mobile/core/auth/token_storage.dart';
import 'package:auster_agx_mobile/features/authentication/data/auth_api.dart';
import 'package:auster_agx_mobile/features/authentication/data/auth_repository.dart';
import 'package:auster_agx_mobile/features/authentication/domain/auth_session.dart';
import 'package:auster_agx_mobile/features/authentication/domain/auth_user.dart';
import 'package:auster_agx_mobile/features/authentication/providers/auth_providers.dart';

void main() {
  testWidgets('mostra tela de login no primeiro acesso', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              api: _FakeAuthApi(),
              tokenStorage: _EmptyTokenStore(),
            ),
          ),
        ],
        child: const AusterMobileApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('AusterAgX Mobile'), findsOneWidget);
  });
}

class _EmptyTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthTokens?> read() async => null;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> save(AuthTokens tokens) async {}
}

class _FakeAuthApi implements AuthRemoteDataSource {
  @override
  Future<AuthSession> login({required String email, required String senha}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<AuthUser> me() {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> refresh(String refreshToken) {
    throw UnimplementedError();
  }
}
