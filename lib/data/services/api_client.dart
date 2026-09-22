import 'package:dio/dio.dart';

import '../../core/auth/auth_session_events.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_failure_policy.dart';
import '../models/auth_tokens.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStore tokenStorage,
    required AuthSessionEvents sessionEvents,
    Duration retryDelay = const Duration(milliseconds: 350),
    int maxReadRetries = 1,
  })  : _sessionEvents = sessionEvents,
        _tokenStorage = tokenStorage,
        _retryDelay = retryDelay,
        _maxReadRetries = maxReadRetries,
        dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: config.apiTimeout,
            receiveTimeout: config.apiTimeout,
            sendTimeout: config.apiTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    if (maxReadRetries < 0) {
      throw ArgumentError.value(
        maxReadRetries,
        'maxReadRetries',
        'must not be negative',
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio dio;
  final TokenStore _tokenStorage;
  final AuthSessionEvents _sessionEvents;
  final Duration _retryDelay;
  final int _maxReadRetries;
  Future<void>? _refreshInFlight;

  static const _retryCountKey = 'transientReadRetryCount';

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

    if (_shouldRetryRead(error)) {
      request.extra[_retryCountKey] =
          (request.extra[_retryCountKey] as int? ?? 0) + 1;
      if (_retryDelay > Duration.zero) {
        await Future<void>.delayed(_retryDelay);
      }
      try {
        final response = await dio.fetch<dynamic>(request);
        handler.resolve(response);
      } on DioException catch (retryError) {
        handler.reject(retryError);
      } catch (retryError) {
        handler.reject(
          DioException(requestOptions: request, error: retryError),
        );
      }
      return;
    }

    handler.next(error);
  }

  bool _shouldRetryRead(DioException error) {
    final method = error.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;

    final retries = error.requestOptions.extra[_retryCountKey] as int? ?? 0;
    return retries < _maxReadRetries && ApiFailurePolicy.isTransient(error);
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
