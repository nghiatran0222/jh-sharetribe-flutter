import 'package:dio/dio.dart';

import 'auth_interceptor.dart';
import 'token_store.dart';

/// The Sharetribe Marketplace API over dio. Only the Marketplace API, with
/// the public client ID and a user token; never the Integration API.
///
/// Methods throw [DioException] or [FormatException]; repositories turn
/// those into a `Result`.
class SharetribeClient {
  SharetribeClient({
    required this._clientId,
    required TokenStore tokenStore,
    Dio? dio,
    String baseUrl = defaultBaseUrl,
  }) : _api = dio ?? Dio() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    );
    _api.options = options;
    _plain = Dio(options.copyWith())
      ..httpClientAdapter = _api.httpClientAdapter;
    _api.interceptors.add(
      AuthInterceptor(
        tokenStore: tokenStore,
        refresh: refreshGrant,
        retryDio: _plain,
      ),
    );
  }

  static const defaultBaseUrl = 'https://flex-api.sharetribe.com';

  final String _clientId;

  /// Marketplace API calls: bearer token + refresh on 401.
  final Dio _api;

  /// Auth endpoints and retries: no interceptor.
  late final Dio _plain;

  /// Logs in: `password` grant with `scope=user`.
  Future<AuthTokens> passwordGrant({
    required String email,
    required String password,
  }) async => _userTokens(
    await _token({
      'grant_type': 'password',
      'username': email,
      'password': password,
      'scope': 'user',
    }),
  );

  /// Exchanges a refresh token for a new (rotated) user token.
  Future<AuthTokens> refreshGrant(String refreshToken) async => _userTokens(
    await _token({
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    }),
  );

  /// An anonymous access token (`client_credentials`, `scope=public-read`),
  /// needed to create a user.
  Future<String> anonymousAccessToken() async {
    final body = await _token({
      'grant_type': 'client_credentials',
      'scope': 'public-read',
    });
    final access = body['access_token'];
    if (access is! String) throw const FormatException('No access_token');
    return access;
  }

  /// Revokes a refresh token on logout.
  Future<void> revoke(String refreshToken) => _plain.post<Object?>(
    '/v1/auth/revoke',
    data: {'client_id': _clientId, 'token': refreshToken},
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );

  /// `GET /v1/api/<path>` with the user token.
  Future<Map<String, Object?>> getApi(
    String path, {
    Map<String, Object?>? query,
  }) async =>
      _json(await _api.get<Object?>('/v1/api/$path', queryParameters: query));

  /// `POST /v1/api/<path>` as JSON. With [bearer], that token is sent
  /// instead of the user token (e.g. an anonymous token for sign-up).
  Future<Map<String, Object?>> postApi(
    String path,
    Map<String, Object?> data, {
    String? bearer,
  }) async => _json(
    await _api.post<Object?>(
      '/v1/api/$path',
      data: data,
      options: Options(
        contentType: Headers.jsonContentType,
        headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
        extra: {AuthInterceptor.skipAuth: bearer != null},
      ),
    ),
  );

  Future<Map<String, Object?>> _token(Map<String, String> form) async => _json(
    await _plain.post<Object?>(
      '/v1/auth/token',
      data: {'client_id': _clientId, ...form},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    ),
  );

  static AuthTokens _userTokens(Map<String, Object?> body) {
    final access = body['access_token'];
    final refresh = body['refresh_token'];
    if (access is! String || refresh is! String) {
      throw const FormatException(
        'Token response needs access and refresh tokens',
      );
    }
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  static Map<String, Object?> _json(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, Object?>) return data;
    if (data is Map) return Map<String, Object?>.from(data);
    throw const FormatException('Response body is not a JSON object');
  }
}
