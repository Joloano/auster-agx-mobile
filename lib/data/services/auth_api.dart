import '../models/auth_session.dart';
import '../models/auth_tokens.dart';
import '../models/auth_user.dart';
import 'api_client.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String senha});

  Future<AuthSession> refresh(String refreshToken);

  Future<void> logout(String refreshToken);

  Future<AuthUser> me();

  Future<AuthUser> changePassword({
    String? senhaAtual,
    required String novaSenha,
  });
}

class AuthApi implements AuthRemoteDataSource {
  AuthApi(this._client);

  final ApiClient _client;

  @override
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

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _sessionFromJson(response.data!);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _client.dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  @override
  Future<AuthUser> me() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(response.data!);
  }

  @override
  Future<AuthUser> changePassword({
    String? senhaAtual,
    required String novaSenha,
  }) async {
    final payload = <String, dynamic>{'novaSenha': novaSenha};
    if (senhaAtual != null && senhaAtual.trim().isNotEmpty) {
      payload['senhaAtual'] = senhaAtual;
    }

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: payload,
    );
    final data = response.data;
    if (data == null) return me();
    return AuthUser.fromJson(data);
  }

  AuthSession _sessionFromJson(Map<String, dynamic> json) {
    return AuthSession(
      tokens: AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      ),
      expiresIn: (json['expiresIn'] as num).toInt(),
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
