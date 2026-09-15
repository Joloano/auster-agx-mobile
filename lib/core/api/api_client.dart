import 'package:dio/dio.dart';

import '../auth/auth_tokens.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({required AppConfig config, required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: config.apiTimeout,
            receiveTimeout: config.apiTimeout,
            sendTimeout: config.apiTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;
  Future<void>? _refreshInFlight;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && !_isPublicAuthRoute(options.path)) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;
    final request = error.requestOptions;

    if (statusCode == 401 &&
        request.extra['retriedAfterRefresh'] != true &&
        !_isPublicAuthRoute(request.path)) {
      request.extra['retriedAfterRefresh'] = true;
      try {
        await _refreshTokens();
        final response = await dio.fetch<dynamic>(request);
        handler.resolve(response);
        return;
      } catch (_) {
        await _tokenStorage.clear();
        handler.reject(error);
        return;
      }
    }

    handler.next(error);
  }

  Future<void> _refreshTokens() {
    _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<void> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) throw const UnauthorizedException();

    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipRefresh': true}),
    );
    final data = response.data;
    if (data == null) throw const UnauthorizedException();

    await _tokenStorage.save(
      AuthTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      ),
    );
  }

  bool _isPublicAuthRoute(String path) {
    return path.startsWith('/auth/login') || path.startsWith('/auth/refresh');
  }
}
