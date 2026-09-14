import 'package:auster_agx_mobile/core/auth/auth_tokens.dart';
import 'package:auster_agx_mobile/core/auth/token_storage.dart';
import 'package:auster_agx_mobile/features/authentication/data/auth_api.dart';
import 'package:auster_agx_mobile/features/authentication/data/auth_repository.dart';
import 'package:auster_agx_mobile/features/authentication/domain/auth_session.dart';
import 'package:auster_agx_mobile/features/authentication/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login salva access token e refresh token no storage seguro', () async {
    final api = _FakeAuthApi();
    final storage = _FakeTokenStore();
    final repository = AuthRepository(api: api, tokenStorage: storage);

    final session = await repository.login('admin@auster.local', 'auster');

    expect(session.user.email, 'admin@auster.local');
    expect(storage.saved?.accessToken, 'access-token');
    expect(storage.saved?.refreshToken, 'refresh-token');
  });

  test('restoreSession limpa tokens quando GET /auth/me falha', () async {
    final api = _FakeAuthApi(throwOnMe: true);
    final storage = _FakeTokenStore(
      saved: const AuthTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final repository = AuthRepository(api: api, tokenStorage: storage);

    final user = await repository.restoreSession();

    expect(user, isNull);
    expect(storage.saved, isNull);
  });
}

class _FakeAuthApi implements AuthRemoteDataSource {
  _FakeAuthApi({this.throwOnMe = false});

  final bool throwOnMe;

  @override
  Future<AuthSession> login({
    required String email,
    required String senha,
  }) async {
    return AuthSession(
      tokens: const AuthTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
      user: _user(email),
      expiresIn: 3600,
    );
  }

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<AuthUser> me() async {
    if (throwOnMe) throw Exception('401');
    return _user('admin@auster.local');
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    throw UnimplementedError();
  }
}

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore({this.saved});

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

AuthUser _user(String email) {
  return AuthUser(
    userId: '01900000-0000-7000-8000-000000000001',
    nome: 'Admin',
    email: email,
    perfil: 'SUPER_ADMIN',
    authority: 'ROLE_SUPER_ADMIN',
    ativo: true,
    deveAlterarSenha: false,
  );
}
