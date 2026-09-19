import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/data/sharetribe/live_auth_repository.dart';
import 'package:sharetribe_flutter/data/sharetribe/live_listing_repository.dart';
import 'package:sharetribe_flutter/data/sharetribe/sharetribe_client.dart';
import 'package:sharetribe_flutter/data/sharetribe/token_store.dart';

import 'support/fake_adapter.dart';

void main() {
  late InMemoryTokenStore store;
  late FakeAdapter adapter;
  late FakeResponse Function(RequestOptions) handler;

  SharetribeClient client() => SharetribeClient(
    clientId: 'client-id',
    tokenStore: store,
    dio: Dio()..httpClientAdapter = adapter,
  );

  setUp(() {
    store = InMemoryTokenStore();
    handler = (_) => const FakeResponse(500);
    adapter = FakeAdapter((r) => handler(r));
  });

  group('given a sandbox user with valid credentials', () {
    setUp(() {
      handler = (r) {
        if (r.path.endsWith('/v1/auth/token')) {
          return FakeResponse(200, tokenBody('a1', 'r1'));
        }
        if (r.path.endsWith('/v1/api/current_user/show') &&
            bearerOf(r) == 'Bearer a1') {
          return FakeResponse(200, fixture('current_user_show.json'));
        }
        return const FakeResponse(401);
      };
    });

    test(
      'when they log in, then the password grant with scope=user is sent',
      () async {
        await LiveAuthRepository(
          client(),
          store,
        ).login(email: 'customer@test.com', password: 'password123');

        final token = adapter.requestsTo('/v1/auth/token').single;
        expect(token.contentType, Headers.formUrlEncodedContentType);
        expect(token.data, {
          'client_id': 'client-id',
          'grant_type': 'password',
          'username': 'customer@test.com',
          'password': 'password123',
          'scope': 'user',
        });
      },
    );

    test(
      'when they log in, then tokens are stored and the current user returns',
      () async {
        final result = await LiveAuthRepository(
          client(),
          store,
        ).login(email: 'customer@test.com', password: 'password123');

        expect(result.valueOrNull?.email, 'customer@test.com');
        expect(result.valueOrNull?.displayName, 'Casey C');
        final saved = await store.read();
        expect(saved?.accessToken, 'a1');
        expect(saved?.refreshToken, 'r1');
      },
    );

    test(
      'when the session is restored, then the current user returns',
      () async {
        await store.save(
          const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
        );

        final result = await LiveAuthRepository(
          client(),
          store,
        ).restoreSession();

        expect(result.valueOrNull?.email, 'customer@test.com');
      },
    );

    test('when they log out, then tokens are cleared and the refresh token is revoked', () async {
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));

      final result = await LiveAuthRepository(client(), store).logout();

      expect(result, isA<Ok<void>>());
      expect(await store.read(), isNull);
      final revoke = adapter.requestsTo('/v1/auth/revoke').single;
      expect(revoke.data, {'client_id': 'client-id', 'token': 'r1'});
    });
  });

  group('given wrong credentials', () {
    setUp(
      () =>
          handler = (_) => const FakeResponse(401, {'error': 'invalid_grant'}),
    );

    test(
      'when they log in, then it returns InvalidCredentials and stores nothing',
      () async {
        final result = await LiveAuthRepository(
          client(),
          store,
        ).login(email: 'customer@test.com', password: 'wrong');

        expect(result.errorOrNull, isA<InvalidCredentials>());
        expect(await store.read(), isNull);
      },
    );
  });

  group('given stored tokens the server no longer accepts', () {
    setUp(() => handler = (_) => const FakeResponse(401));

    test(
      'when the session is restored, then it returns null and clears tokens',
      () async {
        await store.save(
          const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
        );

        final result = await LiveAuthRepository(
          client(),
          store,
        ).restoreSession();

        expect(result, isA<Ok<Object?>>());
        expect(result.valueOrNull, isNull);
        expect(await store.read(), isNull);
      },
    );
  });

  group('given no stored tokens', () {
    test(
      'when the session is restored, then it returns null without a request',
      () async {
        final result = await LiveAuthRepository(
          client(),
          store,
        ).restoreSession();

        expect(result.valueOrNull, isNull);
        expect(adapter.requests, isEmpty);
      },
    );
  });

  group('given no network', () {
    setUp(() => handler = (_) => throw FakeConnectionError());

    test('when they log in, then it returns NetworkError', () async {
      final result = await LiveAuthRepository(
        client(),
        store,
      ).login(email: 'customer@test.com', password: 'password123');

      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('when listings are fetched, then it returns NetworkError', () async {
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));

      final result = await LiveListingRepository(client()).fetchListings();

      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('when they log out, then tokens are still cleared', () async {
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));

      final result = await LiveAuthRepository(client(), store).logout();

      expect(result, isA<Ok<void>>());
      expect(await store.read(), isNull);
    });
  });

  group('given a new email', () {
    setUp(() {
      handler = (r) {
        if (r.path.endsWith('/v1/auth/token')) {
          final form = r.data as Map;
          return form['grant_type'] == 'client_credentials'
              ? const FakeResponse(200, {
                  'access_token': 'anon',
                  'token_type': 'bearer',
                  'expires_in': 3600,
                  'scope': 'public-read',
                })
              : FakeResponse(200, tokenBody('a1', 'r1'));
        }
        if (r.path.endsWith('/v1/api/current_user/create')) {
          return bearerOf(r) == 'Bearer anon'
              ? FakeResponse(200, fixture('current_user_show.json'))
              : const FakeResponse(401);
        }
        if (r.path.endsWith('/v1/api/current_user/show')) {
          return FakeResponse(200, fixture('current_user_show.json'));
        }
        return const FakeResponse(404);
      };
    });

    test('when they sign up, then the account is created with an anonymous token and they are logged in', () async {
      final result = await LiveAuthRepository(client(), store).signUp(
        email: 'customer@test.com',
        password: 'password123',
        firstName: 'Casey',
        lastName: 'Customer',
      );

      expect(result.valueOrNull?.email, 'customer@test.com');
      expect(adapter.requestsTo('/v1/api/current_user/create').single.data, {
        'email': 'customer@test.com',
        'password': 'password123',
        'firstName': 'Casey',
        'lastName': 'Customer',
      });
      expect((await store.read())?.accessToken, 'a1');
    });
  });

  group('given an email that already has an account', () {
    setUp(() {
      handler = (r) => r.path.endsWith('/v1/auth/token')
          ? FakeResponse(200, tokenBody('anon', 'unused'))
          : const FakeResponse(409, {'errors': []});
    });

    test('when they sign up, then it returns EmailTaken', () async {
      final result = await LiveAuthRepository(client(), store).signUp(
        email: 'customer@test.com',
        password: 'password123',
        firstName: 'Casey',
        lastName: 'Customer',
      );

      expect(result.errorOrNull, isA<EmailTaken>());
      expect(await store.read(), isNull);
    });
  });

  group('given a logged-in user and published listings', () {
    setUp(() async {
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      handler = (r) => r.path.endsWith('/v1/api/listings/query')
          ? FakeResponse(200, fixture('listings_query.json'))
          : const FakeResponse(404);
    });

    test('when listings are fetched, then author, images and the image variant are requested', () async {
      await LiveListingRepository(client()).fetchListings();

      final request = adapter.requestsTo('/v1/api/listings/query').single;
      expect(request.method, 'GET');
      expect(request.queryParameters, containsPair('include', 'author,images'));
      expect(
        request.queryParameters,
        containsPair('fields.image', 'variants.landscape-crop'),
      );
      expect(request.headers['Accept'], 'application/json');
      expect(bearerOf(request), 'Bearer a1');
    });

    test(
      'when listings are fetched, then they are mapped with author and image',
      () async {
        final result = await LiveListingRepository(client()).fetchListings();

        final items = result.valueOrNull!;
        expect(items.map((l) => l.title), [
          'Canoe for a weekend',
          'Tent, no photos',
          'Kayak, variant missing',
        ]);
        expect(items.first.author?.displayName, 'Pat P');
        expect(
          items.first.image?.url,
          'https://sharetribe.imgix.net/canoe.jpg?w=800',
        );
        expect(items[2].image, isNull);
      },
    );
  });

  group('given a response that is not JSON:API', () {
    setUp(() async {
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      handler = (_) => const FakeResponse(200, {'unexpected': true});
    });

    test(
      'when listings are fetched, then it returns UnexpectedError',
      () async {
        final result = await LiveListingRepository(client()).fetchListings();

        expect(result.errorOrNull, isA<UnexpectedError>());
      },
    );
  });

  group('given a server error', () {
    setUp(() async {
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      handler = (_) => const FakeResponse(503);
    });

    test(
      'when listings are fetched, then it returns ServerError with the status',
      () async {
        final result = await LiveListingRepository(client()).fetchListings();

        expect(
          result.errorOrNull,
          isA<ServerError>().having((e) => e.statusCode, 'status', 503),
        );
      },
    );
  });
}
