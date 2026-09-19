/// Domain errors, in domain terms (ADR 0009). Returned inside a `Result`,
/// never thrown out of a repository.
sealed class AppError {
  const AppError();

  /// A short message that is safe to show to the user.
  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Wrong email or password.
final class InvalidCredentials extends AppError {
  const InvalidCredentials();

  @override
  String get message => 'Wrong email or password.';
}

/// Sign-up with an email that already has an account.
final class EmailTaken extends AppError {
  const EmailTaken();

  @override
  String get message => 'An account with this email already exists.';
}

/// No session, or the session expired and could not be refreshed.
final class Unauthorized extends AppError {
  const Unauthorized();

  @override
  String get message => 'Your session has expired. Please log in again.';
}

/// The request never got a response (offline, timeout, DNS).
final class NetworkError extends AppError {
  const NetworkError();

  @override
  String get message => 'Network error. Check your connection and try again.';
}

/// The server answered with an error status.
final class ServerError extends AppError {
  const ServerError(this.statusCode);

  final int? statusCode;

  @override
  String get message => 'Server error ($statusCode). Please try again.';
}

/// The response did not have the expected shape, or something else failed.
final class UnexpectedError extends AppError {
  const UnexpectedError(this.detail);

  /// For logs; not shown to the user.
  final String detail;

  @override
  String get message => 'Something went wrong. Please try again.';
}
