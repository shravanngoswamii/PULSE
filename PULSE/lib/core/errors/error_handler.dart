import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'failure.dart';

class ErrorHandler {
  static Failure handleException(dynamic exception) {
    if (exception is DioException) {
      return _handleDioException(exception);
    } else if (exception is ApiException) {
      return ServerFailure(exception.message);
    } else {
      return ServerFailure('An unexpected error occurred');
    }
  }

  static Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timed out');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AuthFailure('Unauthorized access');
        }
        return ServerFailure('Server error: $statusCode');
      case DioExceptionType.cancel:
        return ServerFailure('Request was cancelled');
      default:
        return NetworkFailure('Network error occurred');
    }
  }
}
