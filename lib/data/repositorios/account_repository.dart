import '../models/auth_tokens.dart';
import '../models/auth_user.dart';
import '../models/user_management.dart';
import '../services/account_api.dart';
import '../services/auth_user_storage.dart';
import '../services/token_storage.dart';

class AccountRepository {
  AccountRepository({
    required AccountRemoteDataSource api,
    required TokenStore tokenStorage,
    required AuthUserStore userStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _userStorage = userStorage;

  final AccountRemoteDataSource _api;
  final TokenStore _tokenStorage;
  final AuthUserStore _userStorage;

  Future<void> forgotPassword(String email) => _api.forgotPassword(email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _api.resetPassword(token: token, newPassword: newPassword);
  }

  Future<AuthUser> updateMe({
    required String name,
    required String email,
    required String currentPassword,
  }) async {
    final result = await _api.updateMe(
      name: name,
      email: email,
      currentPassword: currentPassword,
    );
    final currentTokens = await _tokenStorage.read();
    if (currentTokens == null) {
      throw StateError('Sessão local indisponível.');
    }
    await _tokenStorage.save(
      AuthTokens(
        accessToken: result.accessToken,
        refreshToken: currentTokens.refreshToken,
      ),
    );
    await _userStorage.save(result.user);
    return result.user;
  }

  Future<List<AuthUser>> listUsers({bool includeInactive = false}) {
    return _api.listUsers(includeInactive: includeInactive);
  }

  Future<CreatedUser> createUser({
    required String name,
    required String email,
    required String profile,
    required String password,
    required bool temporaryPassword,
  }) {
    return _api.createUser(
      name: name,
      email: email,
      profile: profile,
      password: password,
      temporaryPassword: temporaryPassword,
    );
  }

  Future<AuthUser> updateUser({
    required String userId,
    required String name,
    required String email,
    required String profile,
  }) {
    return _api.updateUser(
      userId: userId,
      name: name,
      email: email,
      profile: profile,
    );
  }

  Future<void> setUserActive(String userId, {required bool active}) {
    return _api.setUserActive(userId, active: active);
  }

  Future<TemporaryPasswordResult> resetUserPassword(
    String userId, {
    String? password,
  }) {
    return _api.resetUserPassword(userId, password: password);
  }
}
