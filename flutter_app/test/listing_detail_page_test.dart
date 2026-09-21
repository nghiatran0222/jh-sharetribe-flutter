import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/domain/models/listing.dart';
import 'package:sharetribe_flutter/domain/models/money.dart';
import 'package:sharetribe_flutter/domain/models/user.dart';
import 'package:sharetribe_flutter/presentation/listing_detail/listing_detail_page.dart';
import 'package:sharetribe_flutter/presentation/listing_detail/request_cubit.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakeTransactionRepository transactions;

  const listing = Listing(
    id: 'l1',
    title: 'City bike',
    description: 'A reliable 7-speed city bike.',
    price: Money(amount: 1500, currency: 'USD'),
    author: User(id: 'u2', displayName: 'Pat P'),
  );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RequestCubit(transactions),
          child: const ListingDetailPage(listing),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() => transactions = FakeTransactionRepository());

  group('given a listing the customer has not requested', () {
    testWidgets(
      'when the page opens, then the listing and a Request button are shown',
      (tester) async {
        await pumpPage(tester);

        expect(find.text('City bike'), findsWidgets);
        expect(find.text('15.00 USD  ·  by Pat P'), findsOneWidget);
        expect(find.text('A reliable 7-speed city bike.'), findsOneWidget);
        expect(find.byKey(const Key('request_button')), findsOneWidget);
      },
    );

    testWidgets(
      'when they request it with a note, then the note reaches the repository',
      (tester) async {
        await pumpPage(tester);

        await tester.enterText(
          find.byKey(const Key('request_note')),
          'Free next weekend?',
        );
        await tester.tap(find.byKey(const Key('request_button')));
        await tester.pumpAndSettle();

        expect(transactions.calls, [
          (listingId: 'l1', note: 'Free next weekend?'),
        ]);
      },
    );

    testWidgets(
      'when the request succeeds, then the pending explanation replaces the button',
      (tester) async {
        await pumpPage(tester);

        await tester.tap(find.byKey(const Key('request_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('request_sent')), findsOneWidget);
        expect(find.text('Request sent'), findsOneWidget);
        expect(find.textContaining('expire after 3 days'), findsOneWidget);
        expect(find.byKey(const Key('request_button')), findsNothing);
      },
    );

    testWidgets(
      'when the request fails, then the error is shown and it can be retried',
      (tester) async {
        transactions.result = const Err(NetworkError());
        await pumpPage(tester);

        await tester.tap(find.byKey(const Key('request_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('request_error')), findsOneWidget);
        expect(
          find.text('Network error. Check your connection and try again.'),
          findsOneWidget,
        );

        transactions.result = const Ok(testTransaction);
        await tester.tap(find.byKey(const Key('request_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('request_sent')), findsOneWidget);
        expect(transactions.calls, hasLength(2));
      },
    );
  });

  group('given a request already sent', () {
    testWidgets(
      'when the button is tapped twice, then only one request is sent',
      (tester) async {
        await pumpPage(tester);

        await tester.tap(find.byKey(const Key('request_button')));
        await tester.pumpAndSettle();
        // The button is gone, so a second tap is impossible by construction.
        expect(find.byKey(const Key('request_button')), findsNothing);
        expect(transactions.calls, hasLength(1));
      },
    );
  });
}
