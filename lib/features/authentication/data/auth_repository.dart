import '../../../core/auth/token_storage.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage tokenStorage})
    : _api = api,
      _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<AuthUser?> restoreSession() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) return null;

    try {
      return await _api.me();
    } catch (_) {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AuthSession> login(String email, String senha) async {
    final session = await _api.login(email: email, senha: senha);
    await _tokenStorage.save(session.tokens);
    return session;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    await _tokenStorage.clear();
    if (refreshToken != null) {
      await _api.logout(refreshToken).catchError((_) {});
    }
  }
}
