import 'package:auster_agx_mobile/core/config/app_config.dart';
import 'package:auster_agx_mobile/data/models/auth_tokens.dart';
import 'package:auster_agx_mobile/data/services/google_drive_authorization.dart';
import 'package:auster_agx_mobile/data/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monta autorizacao do Drive com token codificado', () async {
    final authorization = GoogleDriveAuthorization(
      config: AppConfig(
        apiBaseUrl: 'https://api.auster.test',
        apiTimeout: const Duration(seconds: 10),
      ),
      tokenStorage: const _FakeTokenStore('token com + e /'),
    );

    final uri = await authorization.authorizationUri();

    expect(uri?.path, '/google/authorize');
    expect(uri?.queryParameters['token'], 'token com + e /');
    expect(uri.toString(), contains('token=token+com+%2B+e+%2F'));
  });

  test('nao cria autorizacao sem sessao autenticada', () async {
    final authorization = GoogleDriveAuthorization(
      config: AppConfig(
        apiBaseUrl: 'https://api.auster.test',
        apiTimeout: const Duration(seconds: 10),
      ),
      tokenStorage: const _FakeTokenStore(null),
    );

    expect(await authorization.authorizationUri(), isNull);
  });
}

class _FakeTokenStore implements TokenStore {
  const _FakeTokenStore(this.accessToken);

  final String? accessToken;

  @override
  Future<void> clear() async {}

  @override
  Future<AuthTokens?> read() async => null;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> save(AuthTokens tokens) async {}
}
