abstract class Failure {
  final String message;

  Failure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure([super.message = 'Network connection failed']);
}

class ServerFailure extends Failure {
  ServerFailure([super.message = 'Server error occurred']);
}

class AuthFailure extends Failure {
  AuthFailure([super.message = 'Authentication failed']);
}

class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}
