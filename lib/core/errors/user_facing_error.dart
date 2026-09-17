import 'package:dio/dio.dart';

import 'app_exception.dart';

String userFacingErrorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is! DioException) {
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
    return _serverMessage(error.response?.data) ??
        'Os dados enviados não foram aceitos pelo servidor.';
  }
  if (statusCode == 401) {
    return 'Sua sessão expirou. Entre novamente.';
  }
  if (statusCode == 403) {
    return 'Você não tem permissão para realizar esta operação.';
  }
  if (statusCode == 404) {
    return 'O recurso solicitado não foi encontrado.';
  }
  if (statusCode == 408) {
    return 'O servidor demorou para responder. Tente novamente.';
  }
  if (statusCode == 429) {
    return 'Muitas tentativas em pouco tempo. Aguarde e tente novamente.';
  }
  if (statusCode != null && statusCode >= 500) {
    return 'O servidor está indisponível no momento. Tente novamente.';
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'A conexão demorou para responder. Verifique a rede e tente novamente.';
  }
  if (error.type == DioExceptionType.connectionError) {
    return 'Não foi possível conectar ao servidor. Verifique sua rede.';
  }
  if (error.type == DioExceptionType.badCertificate) {
    return 'Não foi possível validar a segurança do servidor.';
  }
  if (error.type == DioExceptionType.cancel) {
    return 'A operação foi cancelada.';
  }
  return 'Não foi possível concluir a operação. Tente novamente.';
}

String? _serverMessage(Object? data) {
  if (data is! Map) return null;
  final value = data['message'] ?? data['mensagem'];
  if (value is! String) return null;
  final message = value.trim();
  if (message.isEmpty || message.length > 240) return null;
  return message;
}
