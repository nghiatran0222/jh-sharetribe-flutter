import 'package:dio/dio.dart';

import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../json_api.dart';
import 'guard.dart';
import 'sharetribe_client.dart';
import 'token_store.dart';

/// [AuthRepository] against the Sharetribe Marketplace API.
class LiveAuthRepository implements AuthRepository {
  LiveAuthRepository(this._client, this._store);

  final SharetribeClient _client;
  final TokenStore _store;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    final saved = await guard(() async {
      final tokens = await _client.passwordGrant(
        email: email.trim(),
        password: password,
      );
      await _store.save(tokens);
    });
    // The token endpoint answers bad credentials with 400 or 401.
    if (saved case Err(error: Unauthorized() || ServerError(statusCode: 400))) {
      return const Err(InvalidCredentials());
    }
    if (saved case Err(:final error)) return Err(error);
    return guard(_currentUser);
  }

  @override
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final created = await guard(() async {
      final anonymous = await _client.anonymousAccessToken();
      await _client.postApi('current_user/create', {
        'email': email.trim(),
        'password': password,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      }, bearer: anonymous);
    });
    if (created case Err(error: ServerError(statusCode: 409))) {
      return const Err(EmailTaken());
    }
    if (created case Err(:final error)) return Err(error);
    return login(email: email, password: password);
  }

  @override
  Future<Result<User?>> restoreSession() => guard(() async {
    if (await _store.read() == null) return null;
    try {
      return await _currentUser();
    } on DioException catch (e) {
      // The refresh failed too: the stored session is gone.
      if (e.response?.statusCode == 401) {
        await _store.clear();
        return null;
      }
      rethrow;
    }
  });

  @override
  Future<Result<void>> logout() => guard(() async {
    final tokens = await _store.read();
    await _store.clear();
    if (tokens == null) return;
    try {
      await _client.revoke(tokens.refreshToken);
    } on DioException {
      // Best effort: the local session is already gone.
    }
  });

  Future<User> _currentUser() async {
    final body = await _client.getApi('current_user/show');
    return User.fromJsonApi(JsonApiDocument.parse(body).data.single);
  }
}
