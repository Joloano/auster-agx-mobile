import 'package:flutter/foundation.dart';

class AppConfig {
  factory AppConfig({
    required String apiBaseUrl,
    required Duration apiTimeout,
    bool allowInsecureHttp = false,
  }) {
    if (apiTimeout <= Duration.zero) {
      throw ArgumentError.value(
        apiTimeout,
        'apiTimeout',
        'must be greater than zero',
      );
    }

    final normalizedUrl = _normalizeApiBaseUrl(
      apiBaseUrl,
      allowInsecureHttp: allowInsecureHttp,
    );
    return AppConfig._(
      apiBaseUrl: normalizedUrl,
      apiTimeout: apiTimeout,
    );
  }

  const AppConfig._({required this.apiBaseUrl, required this.apiTimeout});

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    const timeoutMs = int.fromEnvironment(
      'API_TIMEOUT_MS',
      defaultValue: 30000,
    );
    const allowInsecureHttp = bool.fromEnvironment(
      'ALLOW_INSECURE_HTTP',
      defaultValue: !kReleaseMode,
    );

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      apiTimeout: const Duration(milliseconds: timeoutMs),
      allowInsecureHttp: allowInsecureHttp,
    );
  }

  static String _normalizeApiBaseUrl(
    String value, {
    required bool allowInsecureHttp,
  }) {
    final uri = Uri.tryParse(value.trim());
    final validScheme = uri?.scheme == 'https' || uri?.scheme == 'http';
    final hasBasePath = uri != null && uri.path.isNotEmpty && uri.path != '/';
    if (uri == null ||
        !validScheme ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        hasBasePath) {
      throw ArgumentError.value(
        value,
        'apiBaseUrl',
        'must be an HTTP(S) origin without credentials, path, query or fragment',
      );
    }
    if (uri.scheme == 'http' && !allowInsecureHttp) {
      throw ArgumentError.value(
        value,
        'apiBaseUrl',
        'HTTP is disabled; use HTTPS or explicitly enable development HTTP',
      );
    }

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  final String apiBaseUrl;
  final Duration apiTimeout;
}
