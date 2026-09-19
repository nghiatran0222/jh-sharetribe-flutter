import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A canned HTTP response for [FakeAdapter].
class FakeResponse {
  const FakeResponse(this.statusCode, [this.body = const {}]);

  final int statusCode;
  final Object body;
}

/// Thrown by a [FakeAdapter] handler to simulate no connection.
class FakeConnectionError implements Exception {}

/// An [HttpClientAdapter] that answers from a handler and records every
/// request it receives, so tests can inject it into a real [Dio].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FutureOr<FakeResponse> Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  /// Requests whose path ends with [suffix].
  List<RequestOptions> requestsTo(String suffix) =>
      requests.where((r) => r.path.endsWith(suffix)).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Snapshot: interceptors may reuse or change headers after sending.
    requests.add(options.copyWith(headers: Map.of(options.headers)));
    // Let other in-flight requests interleave, like a real network.
    await Future<void>.delayed(Duration.zero);
    final FakeResponse response;
    try {
      response = await handler(options);
    } on FakeConnectionError {
      throw const SocketException('offline');
    }
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Reads a JSON fixture from `test/fixtures/`.
Map<String, Object?> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, Object?>;

/// The `Authorization` header a request was sent with.
String? bearerOf(RequestOptions request) =>
    request.headers['Authorization'] as String?;

/// A token-endpoint response body.
Map<String, Object?> tokenBody(String access, String refresh) => {
  'access_token': access,
  'token_type': 'bearer',
  'expires_in': 3600,
  'scope': 'user',
  'refresh_token': refresh,
};
