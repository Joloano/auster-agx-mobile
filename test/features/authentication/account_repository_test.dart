import 'package:auster_agx_mobile/data/models/auth_tokens.dart';
import 'package:auster_agx_mobile/data/models/auth_user.dart';
import 'package:auster_agx_mobile/data/models/user_management.dart';
import 'package:auster_agx_mobile/data/repositorios/account_repository.dart';
import 'package:auster_agx_mobile/data/services/account_api.dart';
import 'package:auster_agx_mobile/data/services/auth_user_storage.dart';
import 'package:auster_agx_mobile/data/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('atualizacao do perfil troca apenas access token e persiste usuario',
      () async {
    final tokenStore = _FakeTokenStore(
      const AuthTokens(accessToken: 'antigo', refreshToken: 'refresh-valido'),
    );
    final userStore = _FakeUserStore();
    final repository = AccountRepository(
      api: _FakeAccountApi(),
      tokenStorage: tokenStore,
      userStorage: userStore,
    );

    final user = await repository.updateMe(
      name: 'Nome Atualizado',
      email: 'novo@austertec.com',
      currentPassword: 'senha-atual',
    );

    expect(user.email, 'novo@austertec.com');
    expect(tokenStore.tokens?.accessToken, 'access-novo');
    expect(tokenStore.tokens?.refreshToken, 'refresh-valido');
    expect(userStore.user, same(user));
  });
}

class _FakeAccountApi implements AccountRemoteDataSource {
  @override
  Future<ProfileUpdateResult> updateMe({
    required String name,
    required String email,
    required String currentPassword,
  }) async {
    return ProfileUpdateResult(
      user: AuthUser(
        userId: '1',
        nome: name,
        email: email,
        perfil: 'SUPER_ADMIN',
        authority: 'ROLE_SUPER_ADMIN',
        ativo: true,
        deveAlterarSenha: false,
      ),
      accessToken: 'access-novo',
      expiresIn: 3600,
    );
  }

  @override
  Future<CreatedUser> createUser({
    required String name,
    required String email,
    required String profile,
    required String password,
    required bool temporaryPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword(String email) => throw UnimplementedError();

  @override
  Future<List<AuthUser>> listUsers({bool includeInactive = false}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<TemporaryPasswordResult> resetUserPassword(
    String userId, {
    String? password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setUserActive(String userId, {required bool active}) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> updateUser({
    required String userId,
    required String name,
    required String email,
    required String profile,
  }) =>
      throw UnimplementedError();
}

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore(this.tokens);

  AuthTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<String?> readAccessToken() async => tokens?.accessToken;

  @override
  Future<String?> readRefreshToken() async => tokens?.refreshToken;

  @override
  Future<void> save(AuthTokens value) async => tokens = value;
}

class _FakeUserStore implements AuthUserStore {
  AuthUser? user;

  @override
  Future<void> clear() async => user = null;

  @override
  Future<AuthUser?> read() async => user;

  @override
  Future<void> save(AuthUser value) async => user = value;
}
