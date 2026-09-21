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

/// The customer already has a request open on this listing.
final class AlreadyRequested extends AppError {
  const AlreadyRequested();

  @override
  String get message => 'You have already requested this listing.';
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

/// The server answered with an error status. [code] is Sharetribe's own
/// error code from the response body (e.g. `transaction-unknown-alias`),
/// which says far more than the status alone.
final class ServerError extends AppError {
  const ServerError(this.statusCode, {this.code = ''});

  final int? statusCode;
  final String code;

  @override
  bool operator ==(Object other) =>
      other is ServerError &&
      other.statusCode == statusCode &&
      other.code == code;

  @override
  int get hashCode => Object.hash(statusCode, code);

  @override
  String get message => switch (code) {
    'transaction-same-author-and-customer' =>
      'You cannot request your own listing. Log in as the customer.',
    'transaction-unknown-alias' =>
      'This marketplace has no simple-request/release-2 alias. '
          'Push the process and create the alias first.',
    'transaction-invalid-transition' =>
      "This listing's type uses a different transaction process. "
          'Point its listing type at simple-request/release-2.',
    'transaction-missing-listing-price' =>
      'This listing has no price, so it cannot be requested.',
    'email-taken' => 'An account with this email already exists.',
    _ when code.isNotEmpty => 'Server error ($statusCode): $code.',
    _ => 'Server error ($statusCode). Please try again.',
  };

  @override
  String toString() => 'ServerError($statusCode, $code)';
}

/// The response did not have the expected shape, or something else failed.
final class UnexpectedError extends AppError {
  const UnexpectedError(this.detail);

  /// For logs; not shown to the user.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is UnexpectedError && other.detail == detail;

  @override
  int get hashCode => detail.hashCode;

  @override
  String get message => 'Something went wrong. Please try again.';
}
