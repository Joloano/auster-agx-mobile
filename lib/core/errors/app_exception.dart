class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class OfflineException extends AppException {
  const OfflineException() : super('Sem conexão com a internet.');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException()
      : super('Sessao expirada. Faca login novamente.');
}
