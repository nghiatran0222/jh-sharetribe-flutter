import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/data/mock/mock_auth_repository.dart';
import 'package:sharetribe_flutter/data/mock/mock_listing_repository.dart';
import 'package:sharetribe_flutter/data/sharetribe/token_store.dart';

void main() {
  late InMemoryTokenStore store;
  late MockAuthRepository auth;
  late MockListingRepository listings;

  setUp(() {
    store = InMemoryTokenStore();
    auth = MockAuthRepository(store);
    listings = MockListingRepository(store);
  });

  group('given the mock users', () {
    test(
      'when the customer logs in, then it returns the user and stores a token',
      () async {
        final result = await auth.login(
          email: 'customer@test.com',
          password: 'password123',
        );

        expect(result.valueOrNull?.email, 'customer@test.com');
        expect(await store.read(), isNotNull);
      },
    );

    test('when the provider logs in, then it returns the provider', () async {
      final result = await auth.login(
        email: 'provider@test.com',
        password: 'password123',
      );

      expect(result.valueOrNull?.email, 'provider@test.com');
    });

    test(
      'when the password is wrong, then it returns InvalidCredentials',
      () async {
        final result = await auth.login(
          email: 'customer@test.com',
          password: 'nope',
        );

        expect(result.errorOrNull, isA<InvalidCredentials>());
        expect(await store.read(), isNull);
      },
    );

    test(
      'when the email is unknown, then it returns InvalidCredentials',
      () async {
        final result = await auth.login(
          email: 'who@test.com',
          password: 'password123',
        );

        expect(result.errorOrNull, isA<InvalidCredentials>());
      },
    );
  });

  group('given a logged-in customer', () {
    setUp(
      () => auth.login(email: 'customer@test.com', password: 'password123'),
    );

    test(
      'when the session is restored, then it returns the customer',
      () async {
        final result = await MockAuthRepository(store).restoreSession();

        expect(result.valueOrNull?.email, 'customer@test.com');
      },
    );

    test('when listings are fetched, then three listings with author and image return', () async {
      final result = await listings.fetchListings();

      final items = result.valueOrNull!;
      expect(items, hasLength(3));
      expect(items.map((l) => l.title), everyElement(isNotEmpty));
      expect(items.map((l) => l.price), everyElement(isNotNull));
      expect(items.map((l) => l.author?.email), everyElement(isNull));
      expect(items.map((l) => l.author?.displayName), everyElement(isNotEmpty));
      expect(
        items.map((l) => l.image?.url),
        everyElement(startsWith('https://')),
      );
    });

    test('when the user logs out, then tokens are cleared and restore returns null', () async {
      final result = await auth.logout();

      expect(result, isA<Ok<void>>());
      expect(await store.read(), isNull);
      expect((await auth.restoreSession()).valueOrNull, isNull);
    });
  });

  group('given no session', () {
    test('when the session is restored, then it returns null', () async {
      final result = await auth.restoreSession();

      expect(result, isA<Ok<Object?>>());
      expect(result.valueOrNull, isNull);
    });

    test('when listings are fetched, then it returns Unauthorized', () async {
      final result = await listings.fetchListings();

      expect(result.errorOrNull, isA<Unauthorized>());
    });

    test('when a new user signs up, then they are logged in', () async {
      final result = await auth.signUp(
        email: 'new@test.com',
        password: 'password123',
        firstName: 'New',
        lastName: 'User',
      );

      expect(result.valueOrNull?.displayName, 'New U');
      expect((await auth.restoreSession()).valueOrNull?.email, 'new@test.com');
    });

    test('when someone signs up with an existing email, then it returns EmailTaken', () async {
      final result = await auth.signUp(
        email: 'Customer@Test.com',
        password: 'x',
        firstName: 'A',
        lastName: 'B',
      );

      expect(result.errorOrNull, isA<EmailTaken>());
    });
  });
}
