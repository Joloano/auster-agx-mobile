import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_api.dart';
import '../services/auth_user_storage.dart';
import '../services/token_storage.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource api,
    required TokenStore tokenStorage,
    required AuthUserStore userStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _userStorage = userStorage;

  final AuthRemoteDataSource _api;
  final TokenStore _tokenStorage;
  final AuthUserStore _userStorage;

  Future<AuthUser?> restoreSession() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      await _userStorage.clear();
      return null;
    }

    try {
      final user = await _api.me();
      await _userStorage.save(user);
      return user;
    } catch (error) {
      if (_isDefinitiveAuthFailure(error)) {
        await clearLocalSession();
        return null;
      }
      if (_isTransientFailure(error)) {
        final cachedUser = await _userStorage.read();
        if (cachedUser != null) return cachedUser;
      }
      rethrow;
    }
  }

  Future<AuthSession> login(String email, String senha) async {
    final session = await _api.login(email: email, senha: senha);
    try {
      await _tokenStorage.save(session.tokens);
      await _userStorage.save(session.user);
    } catch (_) {
      await clearLocalSession();
      rethrow;
    }
    return session;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    await clearLocalSession();
    if (refreshToken != null) {
      await _api.logout(refreshToken).catchError((_) {});
    }
  }

  Future<AuthUser> changePassword({
    String? senhaAtual,
    required String novaSenha,
  }) async {
    final user = await _api.changePassword(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
    );
    await _userStorage.save(user);
    return user;
  }

  Future<void> clearLocalSession() async {
    try {
      await _tokenStorage.clear();
    } finally {
      await _userStorage.clear();
    }
  }

  bool _isDefinitiveAuthFailure(Object error) {
    if (error is UnauthorizedException) return true;
    if (error is! DioException) return false;
    final statusCode = error.response?.statusCode;
    return statusCode == 401 || statusCode == 403;
  }

  bool _isTransientFailure(Object error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    if (error.type == DioExceptionType.unknown &&
        error.error is SocketException) {
      return true;
    }
    final statusCode = error.response?.statusCode;
    return statusCode == 408 ||
        statusCode == 429 ||
        (statusCode != null && statusCode >= 500);
  }
}
