import 'package:dio/dio.dart';

import 'token_store.dart';

/// Attaches `Authorization: Bearer` and refreshes the user token on a 401
/// (ADR 0002). This is the only place a refresh happens.
///
/// Being a [QueuedInterceptor], errors are handled one at a time: when
/// several requests fail together, the first refreshes, and the rest see
/// that the stored token has changed and retry without refreshing again.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required this._refresh,
    required this._retryDio,
  }) : _store = tokenStore;

  /// Set in `RequestOptions.extra` to send a request with its own
  /// `Authorization` header (e.g. an anonymous token), untouched by refresh.
  static const skipAuth = 'sharetribe.skipAuth';
  static const _retried = 'sharetribe.retried';

  final TokenStore _store;
  final Future<AuthTokens> Function(String refreshToken) _refresh;

  /// A Dio without this interceptor, so a retry cannot re-enter the queue.
  final Dio _retryDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
      final tokens = await _store.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[skipAuth] == true ||
        options.extra[_retried] == true) {
      return handler.next(err);
    }
    final stored = await _store.read();
    if (stored == null) return handler.next(err);

    var current = stored;
    if (options.headers['Authorization'] == 'Bearer ${stored.accessToken}') {
      try {
        current = await _refresh(stored.refreshToken);
      } on DioException catch (refreshError) {
        final status = refreshError.response?.statusCode;
        if (status == 400 || status == 401) {
          // The refresh token is dead: the session is over.
          await _store.clear();
          return handler.next(err);
        }
        return handler.next(refreshError);
      }
      // Sharetribe rotates the refresh token; the old one is now invalid.
      await _store.save(current);
    }

    final retry = options.copyWith(
      headers: {
        ...options.headers,
        'Authorization': 'Bearer ${current.accessToken}',
      },
      extra: {...options.extra, _retried: true},
    );
    try {
      handler.resolve(await _retryDio.fetch<Object?>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
