import 'package:auster_agx_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aceita e normaliza origem HTTPS', () {
    final config = AppConfig(
      apiBaseUrl: ' https://api.auster.test:8443/ ',
      apiTimeout: const Duration(seconds: 10),
    );

    expect(config.apiBaseUrl, 'https://api.auster.test:8443');
  });

  test('rejeita HTTP quando transporte inseguro nao foi autorizado', () {
    expect(
      () => AppConfig(
        apiBaseUrl: 'http://10.0.2.2:8080',
        apiTimeout: const Duration(seconds: 10),
      ),
      throwsArgumentError,
    );
  });

  test('permite HTTP somente quando desenvolvimento autoriza explicitamente',
      () {
    final config = AppConfig(
      apiBaseUrl: 'http://10.0.2.2:8080',
      apiTimeout: const Duration(seconds: 10),
      allowInsecureHttp: true,
    );

    expect(config.apiBaseUrl, 'http://10.0.2.2:8080');
  });

  test('rejeita URL com caminho e timeout invalido', () {
    expect(
      () => AppConfig(
        apiBaseUrl: 'https://api.auster.test/v1',
        apiTimeout: const Duration(seconds: 10),
      ),
      throwsArgumentError,
    );
    expect(
      () => AppConfig(
        apiBaseUrl: 'https://api.auster.test',
        apiTimeout: Duration.zero,
      ),
      throwsArgumentError,
    );
  });
}
