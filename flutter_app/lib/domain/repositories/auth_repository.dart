import '../../core/result.dart';
import '../models/user.dart';

/// Identity: login, sign-up, session restore and logout. Implemented by the
/// mock and the live repository.
abstract interface class AuthRepository {
  /// Logs in and stores the user token.
  Future<Result<User>> login({required String email, required String password});

  /// Creates an account, then logs in.
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  /// The stored session's user, or `Ok(null)` when there is no valid session.
  Future<Result<User?>> restoreSession();

  /// Clears the stored tokens. Succeeds even if the server cannot be reached.
  Future<Result<void>> logout();
}
