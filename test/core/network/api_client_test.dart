import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auster_agx_mobile/core/auth/auth_session_events.dart';
import 'package:auster_agx_mobile/core/config/app_config.dart';
import 'package:auster_agx_mobile/data/models/auth_tokens.dart';
import 'package:auster_agx_mobile/data/services/api_client.dart';
import 'package:auster_agx_mobile/data/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryTokenStore tokenStore;
  late AuthSessionEvents sessionEvents;
  late ApiClient client;

  setUp(() {
    tokenStore = _MemoryTokenStore(
      const AuthTokens(
        accessToken: 'expired-access-token',
        refreshToken: 'valid-refresh-token',
      ),
    );
    sessionEvents = AuthSessionEvents();
    client = ApiClient(
      config: AppConfig(
        apiBaseUrl: 'https://api.auster.test',
        apiTimeout: const Duration(seconds: 1),
      ),
      tokenStorage: tokenStore,
      sessionEvents: sessionEvents,
      retryDelay: Duration.zero,
    );
  });

  tearDown(() async {
    client.close();
    await sessionEvents.dispose();
  });

  test('preserva credenciais quando refresh falha por conexao', () async {
    var expirationEvents = 0;
    final subscription = sessionEvents.sessionExpired.listen(
      (_) => expirationEvents++,
    );
    client.dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path == '/auth/refresh') {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return _jsonResponse(401, {'message': 'expired'});
    });

    await expectLater(
      client.dio.get<void>('/protected'),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );

    expect(tokenStore.saved, isNotNull);
    expect(tokenStore.clearCount, 0);
    expect(expirationEvents, 0);
    await subscription.cancel();
  });

  test('limpa credenciais e emite expiracao quando refresh e rejeitado',
      () async {
    final expired = Completer<void>();
    final subscription = sessionEvents.sessionExpired.listen((_) {
      if (!expired.isCompleted) expired.complete();
    });
    client.dio.httpClientAdapter = _StubAdapter((options) {
      return _jsonResponse(401, {'message': 'unauthorized'});
    });

    await expectLater(
      client.dio.get<void>('/protected'),
      throwsA(isA<DioException>()),
    );
    await expired.future;

    expect(tokenStore.saved, isNull);
    expect(tokenStore.clearCount, 1);
    await subscription.cancel();
  });

  test('renova tokens e repete requisicao com novo access token', () async {
    var protectedCalls = 0;
    var refreshCalls = 0;
    client.dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path == '/auth/refresh') {
        refreshCalls++;
        return _jsonResponse(200, {
          'accessToken': 'new-access-token',
          'refreshToken': 'new-refresh-token',
        });
      }
      protectedCalls++;
      if (options.headers['Authorization'] == 'Bearer new-access-token') {
        return _jsonResponse(200, {'ok': true});
      }
      return _jsonResponse(401, {'message': 'expired'});
    });

    final response = await client.dio.get<Map<String, dynamic>>('/protected');

    expect(response.data, {'ok': true});
    expect(protectedCalls, 2);
    expect(refreshCalls, 1);
    expect(tokenStore.saved?.accessToken, 'new-access-token');
    expect(tokenStore.saved?.refreshToken, 'new-refresh-token');
  });

  test('repete leitura uma vez quando a falha e transitoria', () async {
    var calls = 0;
    client.dio.httpClientAdapter = _StubAdapter((options) {
      calls++;
      if (calls == 1) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'conexao interrompida',
        );
      }
      return _jsonResponse(200, {'ok': true});
    });

    final response = await client.dio.get<Map<String, dynamic>>('/protected');

    expect(response.data, {'ok': true});
    expect(calls, 2);
  });

  test('nao repete escrita quando a falha e transitoria', () async {
    var calls = 0;
    client.dio.httpClientAdapter = _StubAdapter((options) {
      calls++;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'conexao interrompida',
      );
    });

    await expectLater(
      client.dio.patch<void>('/protected', data: {'status': 'AGENDADA'}),
      throwsA(isA<DioException>()),
    );

    expect(calls, 1);
  });

  test('limita a uma repeticao quando a leitura continua falhando', () async {
    var calls = 0;
    client.dio.httpClientAdapter = _StubAdapter((options) {
      calls++;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'conexao interrompida',
      );
    });

    await expectLater(
      client.dio.get<void>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(calls, 2);
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore(this.saved);

  AuthTokens? saved;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
    saved = null;
  }

  @override
  Future<AuthTokens?> read() async => saved;

  @override
  Future<String?> readAccessToken() async => saved?.accessToken;

  @override
  Future<String?> readRefreshToken() async => saved?.refreshToken;

  @override
  Future<void> save(AuthTokens tokens) async {
    saved = tokens;
  }
}
