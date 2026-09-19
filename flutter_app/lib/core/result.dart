import 'app_error.dart';

/// The outcome of a repository call (ADR 0009). Repositories return a
/// [Result] and never throw.
sealed class Result<T> {
  const Result();

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  AppError? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final AppError error;

  @override
  String toString() => 'Err($error)';
}
