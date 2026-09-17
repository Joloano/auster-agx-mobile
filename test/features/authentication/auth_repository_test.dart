import 'package:dio/dio.dart';
import 'package:auster_agx_mobile/data/models/auth_tokens.dart';
import 'package:auster_agx_mobile/data/services/token_storage.dart';
import 'package:auster_agx_mobile/data/services/auth_api.dart';
import 'package:auster_agx_mobile/data/services/auth_user_storage.dart';
import 'package:auster_agx_mobile/data/repositorios/auth_repository.dart';
import 'package:auster_agx_mobile/data/models/auth_session.dart';
import 'package:auster_agx_mobile/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login salva access token e refresh token no storage seguro', () async {
    final api = _FakeAuthApi();
    final storage = _FakeTokenStore();
    final userStorage = _FakeAuthUserStore();
    final repository = AuthRepository(
      api: api,
      tokenStorage: storage,
      userStorage: userStorage,
    );

    final session = await repository.login('admin@auster.local', 'auster');

    expect(session.user.email, 'admin@auster.local');
    expect(storage.saved?.accessToken, 'access-token');
    expect(storage.saved?.refreshToken, 'refresh-token');
    expect(userStorage.saved?.email, 'admin@auster.local');
  });

  test('restoreSession usa usuario seguro quando API esta indisponivel',
      () async {
    final api = _FakeAuthApi(
      meError: DioException.connectionError(
        requestOptions: RequestOptions(path: '/auth/me'),
        reason: 'offline',
      ),
    );
    final storage = _FakeTokenStore(
      saved: const AuthTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final cachedUser = _user('admin@auster.local');
    final userStorage = _FakeAuthUserStore(saved: cachedUser);
    final repository = AuthRepository(
      api: api,
      tokenStorage: storage,
      userStorage: userStorage,
    );

    final user = await repository.restoreSession();

    expect(user, same(cachedUser));
    expect(storage.saved, isNotNull);
    expect(userStorage.saved, same(cachedUser));
  });

  test('restoreSession limpa sessao somente em rejeicao definitiva', () async {
    final options = RequestOptions(path: '/auth/me');
    final api = _FakeAuthApi(
      meError: DioException.badResponse(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 401),
        statusCode: 401,
      ),
    );
    final storage = _FakeTokenStore(
      saved: const AuthTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final userStorage = _FakeAuthUserStore(
      saved: _user('admin@auster.local'),
    );
    final repository = AuthRepository(
      api: api,
      tokenStorage: storage,
      userStorage: userStorage,
    );

    final user = await repository.restoreSession();

    expect(user, isNull);
    expect(storage.saved, isNull);
    expect(userStorage.saved, isNull);
  });

  test('changePassword envia contrato oficial e atualiza usuario', () async {
    final api = _FakeAuthApi(
      meUser: _user('admin@auster.local', deveAlterarSenha: true),
    );
    final repository = AuthRepository(
      api: api,
      tokenStorage: _FakeTokenStore(),
      userStorage: _FakeAuthUserStore(),
    );

    final user = await repository.changePassword(
      senhaAtual: 'senha-temporaria',
      novaSenha: 'novaSenha456',
    );

    expect(api.lastSenhaAtual, 'senha-temporaria');
    expect(api.lastNovaSenha, 'novaSenha456');
    expect(user.deveAlterarSenha, isFalse);
  });
}

class _FakeAuthApi implements AuthRemoteDataSource {
  _FakeAuthApi({this.meError, AuthUser? meUser})
      : meUser = meUser ?? _user('admin@auster.local');

  final Object? meError;
  AuthUser meUser;
  String? lastSenhaAtual;
  String? lastNovaSenha;

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
    if (meError != null) throw meError!;
    return meUser;
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> changePassword({
    String? senhaAtual,
    required String novaSenha,
  }) async {
    lastSenhaAtual = senhaAtual;
    lastNovaSenha = novaSenha;
    meUser = meUser.copyWith(deveAlterarSenha: false);
    return meUser;
  }
}

class _FakeAuthUserStore implements AuthUserStore {
  _FakeAuthUserStore({this.saved});

  AuthUser? saved;

  @override
  Future<void> clear() async {
    saved = null;
  }

  @override
  Future<AuthUser?> read() async => saved;

  @override
  Future<void> save(AuthUser user) async {
    saved = user;
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
