import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/data/sharetribe/sharetribe_client.dart';
import 'package:sharetribe_flutter/data/sharetribe/token_store.dart';

import 'support/fake_adapter.dart';

void main() {
  late InMemoryTokenStore store;
  late FakeAdapter adapter;
  late SharetribeClient client;
  var refreshSucceeds = true;

  /// Only `Bearer a2` is valid. Refreshing with `r1` rotates to a2/r2.
  FakeResponse server(RequestOptions request) {
    if (request.path.endsWith('/v1/auth/token')) {
      final form = request.data as Map;
      if (refreshSucceeds &&
          form['grant_type'] == 'refresh_token' &&
          form['refresh_token'] == 'r1') {
        return FakeResponse(200, tokenBody('a2', 'r2'));
      }
      return const FakeResponse(401, {'error': 'invalid_grant'});
    }
    if (bearerOf(request) == 'Bearer a2') {
      return FakeResponse(200, fixture('current_user_show.json'));
    }
    return const FakeResponse(401, {'errors': []});
  }

  setUp(() {
    refreshSucceeds = true;
    store = InMemoryTokenStore(
      const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
    );
    adapter = FakeAdapter(server);
    client = SharetribeClient(
      clientId: 'client-id',
      tokenStore: store,
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  group('given an expired access token and a valid refresh token', () {
    test(
      'when a request gets a 401, then it refreshes once and retries',
      () async {
        final body = await client.getApi('current_user/show');

        expect((body['data'] as Map)['type'], 'currentUser');
        expect(adapter.requestsTo('/v1/auth/token'), hasLength(1));
        final calls = adapter.requestsTo('/v1/api/current_user/show');
        expect(calls.map(bearerOf), ['Bearer a1', 'Bearer a2']);
      },
    );

    test('when the refresh runs, then it uses the refresh_token grant and client ID', () async {
      await client.getApi('current_user/show');

      final form = adapter.requestsTo('/v1/auth/token').single.data as Map;
      expect(form, {
        'client_id': 'client-id',
        'grant_type': 'refresh_token',
        'refresh_token': 'r1',
      });
    });

    test(
      'when the refresh succeeds, then the rotated refresh token is persisted',
      () async {
        await client.getApi('current_user/show');

        final saved = await store.read();
        expect(saved?.accessToken, 'a2');
        expect(saved?.refreshToken, 'r2');
      },
    );

    test(
      'when three requests get a 401 at once, then exactly one refresh runs',
      () async {
        final bodies = await Future.wait([
          client.getApi('current_user/show'),
          client.getApi('current_user/show'),
          client.getApi('current_user/show'),
        ]);

        expect(bodies, hasLength(3));
        expect(adapter.requestsTo('/v1/auth/token'), hasLength(1));
        final bearers = adapter
            .requestsTo('/v1/api/current_user/show')
            .map(bearerOf);
        expect(bearers.where((b) => b == 'Bearer a1'), hasLength(3));
        expect(bearers.where((b) => b == 'Bearer a2'), hasLength(3));
        expect((await store.read())?.refreshToken, 'r2');
      },
    );

    test(
      'when the next request is made, then it uses the new access token',
      () async {
        await client.getApi('current_user/show');
        adapter.requests.clear();

        await client.getApi('current_user/show');

        expect(adapter.requests.map(bearerOf), ['Bearer a2']);
      },
    );
  });

  group('given a refresh token the server rejects', () {
    setUp(() => refreshSucceeds = false);

    test('when a request gets a 401, then tokens are cleared and the 401 is surfaced', () async {
      await expectLater(
        client.getApi('current_user/show'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );

      expect(await store.read(), isNull);
      expect(adapter.requestsTo('/v1/auth/token'), hasLength(1));
    });
  });

  group('given a server that rejects even the refreshed token', () {
    test(
      'when a request gets a 401, then the retry does not refresh again',
      () async {
        adapter = FakeAdapter((request) {
          if (request.path.endsWith('/v1/auth/token')) {
            return FakeResponse(200, tokenBody('a2', 'r2'));
          }
          return const FakeResponse(401, {'errors': []});
        });
        client = SharetribeClient(
          clientId: 'client-id',
          tokenStore: store,
          dio: Dio()..httpClientAdapter = adapter,
        );

        await expectLater(
          client.getApi('current_user/show'),
          throwsA(isA<DioException>()),
        );

        // One refresh, and the retry is not refreshed a second time.
        expect(adapter.requestsTo('/v1/auth/token'), hasLength(1));
        expect(adapter.requestsTo('/v1/api/current_user/show'), hasLength(2));
      },
    );
  });

  group('given a request that carries its own token', () {
    test(
      'when it gets a 401, then the user session is not refreshed',
      () async {
        await expectLater(
          client.postApi('current_user/create', const {}, bearer: 'anon'),
          throwsA(isA<DioException>()),
        );

        expect(adapter.requestsTo('/v1/auth/token'), isEmpty);
        final sent = adapter.requestsTo('/v1/api/current_user/create').single;
        expect(bearerOf(sent), 'Bearer anon');
      },
    );
  });

  group('given no stored tokens', () {
    setUp(() => store = InMemoryTokenStore());

    test('when a request gets a 401, then no refresh is attempted', () async {
      client = SharetribeClient(
        clientId: 'client-id',
        tokenStore: store,
        dio: Dio()..httpClientAdapter = adapter,
      );

      await expectLater(
        client.getApi('current_user/show'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requestsTo('/v1/auth/token'), isEmpty);
      expect(bearerOf(adapter.requests.single), isNull);
    });
  });
}
