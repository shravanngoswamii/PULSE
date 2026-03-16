class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Internal server error', String? code]) : super(code: code);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out']);
}
