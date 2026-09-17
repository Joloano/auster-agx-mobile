import 'dart:io';

import 'package:dio/dio.dart';

abstract final class ApiFailurePolicy {
  static bool isTransient(Object error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    if (error.type == DioExceptionType.unknown &&
        error.error is SocketException) {
      return true;
    }

    final statusCode = error.response?.statusCode;
    return statusCode == 408 ||
        statusCode == 429 ||
        (statusCode != null && statusCode >= 500);
  }
}
