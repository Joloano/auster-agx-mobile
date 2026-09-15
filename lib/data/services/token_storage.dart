import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_tokens.dart';

abstract class TokenStore {
  Future<AuthTokens?> read();

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> save(AuthTokens tokens);

  Future<void> clear();
}

class TokenStorage implements TokenStore {
  TokenStorage(this._storage);

  static const _accessTokenKey = 'auster_agx_access_token';
  static const _refreshTokenKey = 'auster_agx_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
