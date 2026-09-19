import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sharetribe/token_store.dart';
import 'mock_data.dart';

/// Offline [AuthRepository] over [mockAccounts]. Stores a fake token in the
/// [TokenStore] so session restore and logout behave like live mode.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._store, {this.latency = Duration.zero});

  static const _tokenPrefix = 'mock-access-';

  final TokenStore _store;
  final Duration latency;

  /// Shared by every instance, so a sign-up survives a new repository.
  static final List<MockAccount> _accounts = [...mockAccounts];

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final account = _find(email);
    if (account == null || account.password != password) {
      return const Err(InvalidCredentials());
    }
    await _store.save(
      AuthTokens(
        accessToken: '$_tokenPrefix${account.id}',
        refreshToken: 'mock-refresh-${account.id}',
      ),
    );
    return Ok(_user(account));
  }

  @override
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await Future<void>.delayed(latency);
    if (_find(email) != null) return const Err(EmailTaken());
    _accounts.add(
      MockAccount(
        id: 'mock-user-${_accounts.length + 1}',
        email: email.trim().toLowerCase(),
        password: password,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      ),
    );
    return login(email: email, password: password);
  }

  @override
  Future<Result<User?>> restoreSession() async {
    final tokens = await _store.read();
    final id = tokens?.accessToken.replaceFirst(_tokenPrefix, '');
    final account = _accounts.where((a) => a.id == id).firstOrNull;
    return Ok(account == null ? null : _user(account));
  }

  @override
  Future<Result<void>> logout() async {
    await _store.clear();
    return const Ok(null);
  }

  MockAccount? _find(String email) {
    final key = email.trim().toLowerCase();
    return _accounts.where((a) => a.email == key).firstOrNull;
  }

  static User _user(MockAccount a) =>
      User(id: a.id, displayName: a.displayName, email: a.email);
}
