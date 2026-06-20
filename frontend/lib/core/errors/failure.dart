sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

final class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflict']);
}
