class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.apiTimeout});

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    const timeoutMs = int.fromEnvironment(
      'API_TIMEOUT_MS',
      defaultValue: 10000,
    );

    return const AppConfig(
      apiBaseUrl: apiBaseUrl,
      apiTimeout: Duration(milliseconds: timeoutMs),
    );
  }

  final String apiBaseUrl;
  final Duration apiTimeout;
}
