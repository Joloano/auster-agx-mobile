import 'package:dio/dio.dart';

import '../../core/auth/auth_session_events.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/auth_tokens.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStore tokenStorage,
    required AuthSessionEvents sessionEvents,
  })  : _sessionEvents = sessionEvents,
        _tokenStorage = tokenStorage,
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
  final TokenStore _tokenStorage;
  final AuthSessionEvents _sessionEvents;
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
        request.extra['skipRefresh'] != true &&
        !_isPublicAuthRoute(request.path)) {
      request.extra['retriedAfterRefresh'] = true;
      try {
        await _refreshTokens();
        final accessToken = await _tokenStorage.readAccessToken();
        if (accessToken == null) throw const UnauthorizedException();
        request.headers['Authorization'] = 'Bearer $accessToken';
        final response = await dio.fetch<dynamic>(request);
        handler.resolve(response);
        return;
      } catch (refreshError) {
        if (_isDefinitiveAuthFailure(refreshError)) {
          try {
            await _tokenStorage.clear();
          } finally {
            _sessionEvents.notifySessionExpired();
          }
          handler.reject(error);
          return;
        }

        handler.reject(
          refreshError is DioException
              ? refreshError
              : DioException(
                  requestOptions: request,
                  error: refreshError,
                ),
        );
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
    final accessToken = data['accessToken'];
    final nextRefreshToken = data['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        nextRefreshToken is! String ||
        nextRefreshToken.isEmpty) {
      throw const UnauthorizedException();
    }

    await _tokenStorage.save(
      AuthTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      ),
    );
  }

  bool _isDefinitiveAuthFailure(Object error) {
    if (error is UnauthorizedException) return true;
    if (error is! DioException) return false;
    final statusCode = error.response?.statusCode;
    return statusCode == 401 || statusCode == 403;
  }

  bool _isPublicAuthRoute(String path) {
    return path.startsWith('/auth/login') || path.startsWith('/auth/refresh');
  }

  void close() {
    dio.close(force: true);
  }
}
