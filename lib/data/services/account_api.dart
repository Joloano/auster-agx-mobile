import '../models/auth_user.dart';
import '../models/user_management.dart';
import 'api_client.dart';

abstract class AccountRemoteDataSource {
  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<ProfileUpdateResult> updateMe({
    required String name,
    required String email,
    required String currentPassword,
  });

  Future<List<AuthUser>> listUsers({bool includeInactive = false});

  Future<CreatedUser> createUser({
    required String name,
    required String email,
    required String profile,
    required String password,
    required bool temporaryPassword,
  });

  Future<AuthUser> updateUser({
    required String userId,
    required String name,
    required String email,
    required String profile,
  });

  Future<void> setUserActive(String userId, {required bool active});

  Future<TemporaryPasswordResult> resetUserPassword(
    String userId, {
    String? password,
  });
}

class AccountApi implements AccountRemoteDataSource {
  AccountApi(this._client);

  final ApiClient _client;

  @override
  Future<void> forgotPassword(String email) async {
    await _client.dio.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.dio.post<void>(
      '/auth/reset-password',
      data: {'token': token, 'novaSenha': newPassword},
    );
  }

  @override
  Future<ProfileUpdateResult> updateMe({
    required String name,
    required String email,
    required String currentPassword,
  }) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/auth/me',
      data: {
        'nome': name,
        'email': email,
        'senhaAtual': currentPassword,
      },
    );
    final data = response.data!;
    return ProfileUpdateResult(
      user: AuthUser.fromJson(data['usuario'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      expiresIn: (data['expiresIn'] as num).toInt(),
    );
  }

  @override
  Future<List<AuthUser>> listUsers({bool includeInactive = false}) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/auth/users',
      queryParameters: {
        if (includeInactive) 'incluirInativos': true,
      },
    );
    return response.data!
        .whereType<Map>()
        .map((item) => AuthUser.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<CreatedUser> createUser({
    required String name,
    required String email,
    required String profile,
    required String password,
    required bool temporaryPassword,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/users',
      data: {
        'nome': name,
        'email': email,
        'perfil': profile,
        'senha': password,
        'senhaTemporaria': temporaryPassword,
      },
    );
    return CreatedUser.fromJson(response.data!);
  }

  @override
  Future<AuthUser> updateUser({
    required String userId,
    required String name,
    required String email,
    required String profile,
  }) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/auth/users/$userId',
      data: {'nome': name, 'email': email, 'perfil': profile},
    );
    return AuthUser.fromJson(response.data!);
  }

  @override
  Future<void> setUserActive(String userId, {required bool active}) async {
    final action = active ? 'activate' : 'deactivate';
    await _client.dio.patch<void>('/auth/users/$userId/$action');
  }

  @override
  Future<TemporaryPasswordResult> resetUserPassword(
    String userId, {
    String? password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/users/$userId/reset-password',
      data: {
        if (password != null && password.trim().isNotEmpty)
          'senhaTemporaria': password,
      },
    );
    return TemporaryPasswordResult.fromJson(response.data!);
  }
}
