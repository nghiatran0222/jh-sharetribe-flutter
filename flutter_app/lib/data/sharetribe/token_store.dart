import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A user token from `POST /v1/auth/token`.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Where the user token lives between launches (ADR 0010).
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

/// Keychain (iOS) / Keystore-backed storage (Android) via
/// flutter_secure_storage. Used in live mode.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  ]) : _storage = storage;

  static const _accessKey = 'sharetribe.access_token';
  static const _refreshKey = 'sharetribe.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Keeps the token in memory only. Used by tests and by widget tests of
/// mock mode, where platform channels are not available.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._tokens]);

  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> save(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
