import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_tokens.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthSession> login({
    required String email,
    required String senha,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'senha': senha},
    );
    return _sessionFromJson(response.data!);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _sessionFromJson(response.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _client.dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<AuthUser> me() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(response.data!);
  }

  AuthSession _sessionFromJson(Map<String, dynamic> json) {
    return AuthSession(
      tokens: AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      ),
      expiresIn: json['expiresIn'] as int,
      user: AuthUser.fromJson({
        'userId': json['userId'],
        'nome': json['nome'],
        'email': json['email'],
        'perfil': json['perfil'],
        'authority': json['authority'],
        'ativo': true,
        'deveAlterarSenha': json['deveAlterarSenha'],
      }),
    );
  }
}
