import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Where the session stands.
sealed class AuthState {
  const AuthState();
}

/// On launch, before the stored session has been checked.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// No session. [submitting] is a login in flight; [error] is the last failure.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.error, this.submitting = false});

  final AppError? error;
  final bool submitting;

  @override
  bool operator ==(Object other) =>
      other is AuthUnauthenticated &&
      other.error.runtimeType == error.runtimeType &&
      other.submitting == submitting;

  @override
  int get hashCode => Object.hash(error.runtimeType, submitting);

  @override
  String toString() =>
      'AuthUnauthenticated(submitting: $submitting, error: $error)';
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  bool operator ==(Object other) =>
      other is AuthAuthenticated && other.user == user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'AuthAuthenticated(${user.email})';
}

/// Identity for the UI: restore on launch, log in, log out.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._auth) : super(const AuthUnknown());

  final AuthRepository _auth;

  /// Called once on launch: a stored session goes straight to listings.
  Future<void> restoreSession() async {
    emit(const AuthUnknown());
    switch (await _auth.restoreSession()) {
      case Ok(:final value):
        emit(
          value == null
              ? const AuthUnauthenticated()
              : AuthAuthenticated(value),
        );
      case Err(:final error):
        emit(AuthUnauthenticated(error: error));
    }
  }

  Future<void> logIn({required String email, required String password}) async {
    emit(const AuthUnauthenticated(submitting: true));
    switch (await _auth.login(email: email, password: password)) {
      case Ok(:final value):
        emit(AuthAuthenticated(value));
      case Err(:final error):
        emit(AuthUnauthenticated(error: error));
    }
  }

  /// Clears the stored tokens and returns to login, online or not.
  Future<void> logOut() async {
    await _auth.logout();
    emit(const AuthUnauthenticated());
  }
}
