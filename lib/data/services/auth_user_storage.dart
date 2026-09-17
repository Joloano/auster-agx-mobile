import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_user.dart';

abstract class AuthUserStore {
  Future<AuthUser?> read();

  Future<void> save(AuthUser user);

  Future<void> clear();
}

class AuthUserStorage implements AuthUserStore {
  AuthUserStorage(this._storage);

  static const _userKey = 'auster_agx_authenticated_user';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthUser?> read() async {
    final encoded = await _storage.read(key: _userKey);
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        await clear();
        return null;
      }
      return AuthUser.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(AuthUser user) {
    return _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _userKey);
  }
}
