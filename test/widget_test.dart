import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auster_agx_mobile/app/auster_mobile_app.dart';
import 'package:auster_agx_mobile/data/models/auth_tokens.dart';
import 'package:auster_agx_mobile/data/services/token_storage.dart';
import 'package:auster_agx_mobile/data/services/auth_api.dart';
import 'package:auster_agx_mobile/data/repositorios/auth_repository.dart';
import 'package:auster_agx_mobile/data/models/auth_session.dart';
import 'package:auster_agx_mobile/data/models/auth_user.dart';
import 'package:auster_agx_mobile/features/authentication/providers/auth_providers.dart';

void main() {
  testWidgets('mostra tela de login no primeiro acesso', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              api: _FakeAuthApi(),
              tokenStorage: _MemoryTokenStore(),
            ),
          ),
        ],
        child: const AusterMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('ACESSAR PLATAFORMA'), findsOneWidget);
  });

  testWidgets('protege dashboard durante restauracao da sessao',
      (tester) async {
    final tokenStore = _DelayedTokenStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              api: _FakeAuthApi(),
              tokenStorage: tokenStore,
            ),
          ),
        ],
        child: const AusterMobileApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    tokenStore.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('direciona senha temporaria para troca obrigatoria',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              api: _FakeAuthApi(
                user: _user(
                  'admin@auster.local',
                  deveAlterarSenha: true,
                ),
              ),
              tokenStorage: _MemoryTokenStore(
                const AuthTokens(
                  accessToken: 'access-token',
                  refreshToken: 'refresh-token',
                ),
              ),
            ),
          ),
        ],
        child: const AusterMobileApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TROCA DE SENHA'), findsOneWidget);
    expect(find.textContaining('Senha provisória detectada'), findsOneWidget);
    expect(find.text('Alterar senha'), findsOneWidget);
  });
}

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore([this.saved]);

  AuthTokens? saved;

  @override
  Future<void> clear() async {
    saved = null;
  }

  @override
  Future<AuthTokens?> read() async => saved;

  @override
  Future<String?> readAccessToken() async => saved?.accessToken;

  @override
  Future<String?> readRefreshToken() async => saved?.refreshToken;

  @override
  Future<void> save(AuthTokens tokens) async {
    saved = tokens;
  }
}

class _DelayedTokenStore implements TokenStore {
  final _readCompleter = Completer<AuthTokens?>();

  void complete(AuthTokens? tokens) => _readCompleter.complete(tokens);

  @override
  Future<void> clear() async {}

  @override
  Future<AuthTokens?> read() => _readCompleter.future;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> save(AuthTokens tokens) async {}
}

class _FakeAuthApi implements AuthRemoteDataSource {
  _FakeAuthApi({AuthUser? user}) : user = user ?? _user('admin@auster.local');

  AuthUser user;

  @override
  Future<AuthSession> login({required String email, required String senha}) {
    user = _user(email);
    return Future.value(
      AuthSession(
        tokens: const AuthTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        ),
        user: user,
        expiresIn: 3600,
      ),
    );
  }

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<AuthUser> me() async {
    return user;
  }

  @override
  Future<AuthSession> refresh(String refreshToken) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> changePassword({
    String? senhaAtual,
    required String novaSenha,
  }) async {
    user = user.copyWith(deveAlterarSenha: false);
    return user;
  }
}

AuthUser _user(String email, {bool deveAlterarSenha = false}) {
  return AuthUser(
    userId: '01900000-0000-7000-8000-000000000001',
    nome: 'Admin',
    email: email,
    perfil: 'SUPER_ADMIN',
    authority: 'ROLE_SUPER_ADMIN',
    ativo: true,
    deveAlterarSenha: deveAlterarSenha,
  );
}
