import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_api.dart';
import '../services/token_storage.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource api,
    required TokenStore tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _api;
  final TokenStore _tokenStorage;

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

  Future<AuthUser> changePassword({
    String? senhaAtual,
    required String novaSenha,
  }) {
    return _api.changePassword(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
    );
  }
}
