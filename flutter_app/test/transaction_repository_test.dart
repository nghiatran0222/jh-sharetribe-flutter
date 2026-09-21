import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/data/mock/mock_transaction_repository.dart';
import 'package:sharetribe_flutter/data/sharetribe/live_transaction_repository.dart';
import 'package:sharetribe_flutter/data/sharetribe/sharetribe_client.dart';
import 'package:sharetribe_flutter/data/sharetribe/token_store.dart';
import 'package:sharetribe_flutter/domain/models/transaction.dart';

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
    store = InMemoryTokenStore(
      const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
    );
    handler = (_) => FakeResponse(200, fixture('transaction_initiate.json'));
    adapter = FakeAdapter((r) => handler(r));
  });

  group('given a logged-in customer and a listing', () {
    test(
      'when they request it, then transition/request is sent on release-2',
      () async {
        await LiveTransactionRepository(client()).requestListing(
          listingId: 'listing-1',
          note: 'Is it available next weekend?',
        );

        final sent = adapter.requestsTo('/v1/api/transactions/initiate').single;
        expect(sent.method, 'POST');
        expect(sent.data, {
          'processAlias': 'simple-request/release-2',
          'transition': 'transition/request',
          'params': {
            'listingId': 'listing-1',
            'protectedData': {'customerNote': 'Is it available next weekend?'},
          },
        });
        expect(bearerOf(sent), 'Bearer a1');
      },
    );

    test('when the note is empty, then no protectedData is sent', () async {
      await LiveTransactionRepository(client())
          .requestListing(listingId: 'listing-1', note: '   ');

      final params =
          (adapter.requestsTo('/v1/api/transactions/initiate').single.data
              as Map)['params'];
      expect(params, {'listingId': 'listing-1'});
    });

    test(
      'when the request succeeds, then the transaction is returned',
      () async {
        final result = await LiveTransactionRepository(client())
            .requestListing(listingId: 'listing-1');

        final transaction = result.valueOrNull!;
        expect(transaction.lastTransition, transitionRequest);
        expect(transaction.processName, 'simple-request');
        expect(transaction.id, isNotEmpty);
      },
    );

    test('when the alias is overridden, then that alias is sent', () async {
      await LiveTransactionRepository(
        client(),
        processAlias: 'simple-request/release-1',
      ).requestListing(listingId: 'listing-1');

      final body =
          adapter.requestsTo('/v1/api/transactions/initiate').single.data
              as Map;
      expect(body['processAlias'], 'simple-request/release-1');
    });
  });

  group('given the marketplace rejects the transition', () {
    /// Sharetribe answers 409 with a code naming the rule that was broken.
    Future<AppError?> rejectedWith(String code) async {
      handler = (_) => FakeResponse(409, {
        'errors': [
          {'code': code, 'status': 409, 'title': code},
        ],
      });
      final result = await LiveTransactionRepository(client())
          .requestListing(listingId: 'listing-1');
      return result.errorOrNull;
    }

    test(
      'when the alias cannot be resolved, then the message names it',
      () async {
        final error = await rejectedWith('transaction-unknown-alias');

        expect(
          error,
          isA<ServerError>().having(
            (e) => e.code,
            'code',
            'transaction-unknown-alias',
          ),
        );
        expect(error!.message, contains('simple-request/release-2'));
      },
    );

    test(
      'when the listing uses another process, then the message says so',
      () async {
        final error = await rejectedWith('transaction-invalid-transition');

        expect(error!.message, contains('different transaction process'));
      },
    );

    test(
      'when the customer owns the listing, then the message says so',
      () async {
        final error = await rejectedWith(
          'transaction-same-author-and-customer',
        );

        expect(error!.message, contains('cannot request your own listing'));
      },
    );

    test(
      'when the body carries no code, then the status is still reported',
      () async {
        handler = (_) => const FakeResponse(409, {'errors': []});

        final result = await LiveTransactionRepository(client())
            .requestListing(listingId: 'listing-1');

        expect(
          result.errorOrNull,
          isA<ServerError>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.code, 'code', ''),
        );
        expect(result.errorOrNull!.message, contains('409'));
      },
    );
  });

  group('given no network', () {
    setUp(() => handler = (_) => throw FakeConnectionError());

    test('when they request a listing, then it returns NetworkError', () async {
      final result = await LiveTransactionRepository(client())
          .requestListing(listingId: 'listing-1');

      expect(result.errorOrNull, isA<NetworkError>());
    });
  });

  group('given mock mode and a logged-in customer', () {
    late MockTransactionRepository transactions;

    setUp(() => transactions = MockTransactionRepository(store));

    test(
      'when they request a listing, then a pending request is recorded',
      () async {
        final result = await transactions.requestListing(
          listingId: 'mock-listing-1',
        );

        expect(result.valueOrNull?.lastTransition, transitionRequest);
        expect(transactions.requests, contains('mock-listing-1'));
      },
    );

    test('when they request the same listing twice, then it returns AlreadyRequested', () async {
      await transactions.requestListing(listingId: 'mock-listing-1');

      final again = await transactions.requestListing(
        listingId: 'mock-listing-1',
      );

      expect(again.errorOrNull, isA<AlreadyRequested>());
    });
  });

  group('given mock mode with no session', () {
    test('when they request a listing, then it returns Unauthorized', () async {
      final result = await MockTransactionRepository(InMemoryTokenStore())
          .requestListing(listingId: 'mock-listing-1');

      expect(result.errorOrNull, isA<Unauthorized>());
    });
  });
}
