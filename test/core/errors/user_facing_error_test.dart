import 'package:auster_agx_mobile/core/errors/app_exception.dart';
import 'package:auster_agx_mobile/core/errors/user_facing_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserva mensagem de erro de dominio', () {
    expect(
      userFacingErrorMessage(const OfflineException()),
      'Sem conexão com a internet.',
    );
  });

  test('traduz falha de conexao sem expor detalhes tecnicos', () {
    final error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/dashboard/resumo'),
      reason: 'SocketException: host lookup failed',
    );

    final message = userFacingErrorMessage(error);

    expect(
        message, 'Não foi possível conectar ao servidor. Verifique sua rede.');
    expect(message, isNot(contains('SocketException')));
  });

  test('traduz autorizacao negada', () {
    final options = RequestOptions(path: '/demandas/demanda-1');
    final error = DioException.badResponse(
      requestOptions: options,
      response: Response<void>(requestOptions: options, statusCode: 403),
      statusCode: 403,
    );

    expect(
      userFacingErrorMessage(error),
      'Você não tem permissão para realizar esta operação.',
    );
  });

  test('usa mensagem curta de validacao devolvida pelo backend', () {
    final options = RequestOptions(path: '/demandas/demanda-1');
    final error = DioException.badResponse(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 422,
        data: {'message': 'Mapeamento deve estar concluído.'},
      ),
      statusCode: 422,
    );

    expect(
      userFacingErrorMessage(error),
      'Mapeamento deve estar concluído.',
    );
  });

  test('nao exibe representacao de erro inesperado', () {
    final message = userFacingErrorMessage(StateError('segredo interno'));

    expect(message, 'Ocorreu um erro inesperado. Tente novamente.');
    expect(message, isNot(contains('segredo interno')));
  });
}
