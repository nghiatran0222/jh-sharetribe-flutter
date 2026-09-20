import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/domain/models/listing.dart';
import 'package:sharetribe_flutter/presentation/listings/listings_cubit.dart';
import 'package:sharetribe_flutter/presentation/listings/listings_page.dart';

import 'support/fake_repositories.dart';

/// Page-level tests with a repository that counts its calls, so a gesture
/// has to actually reach the repository to pass.
void main() {
  late FakeListingRepository repository;

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ListingsCubit(repository)..load(),
          child: const ListingsPage(),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    repository = FakeListingRepository(const Ok([testListing]));
  });

  group('given listings on screen', () {
    testWidgets(
      'when the list is pulled down, then the repository is asked again and the new listings appear',
      (tester) async {
        await pumpPage(tester);
        expect(repository.fetchCalls, 1);
        expect(find.text('City bike'), findsOneWidget);

        repository.result = const Ok([Listing(id: 'l2', title: 'Kayak')]);
        await tester.fling(find.text('City bike'), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        expect(repository.fetchCalls, 2);
        expect(find.text('Kayak'), findsOneWidget);
        expect(find.text('City bike'), findsNothing);
      },
    );
  });

  group('given the marketplace cannot be reached', () {
    setUp(() => repository = FakeListingRepository(networkFailure));

    testWidgets('when the page loads, then the error and a retry are shown', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byKey(const Key('listings_error')), findsOneWidget);
      expect(
        find.text('Network error. Check your connection and try again.'),
        findsOneWidget,
      );

      repository.result = const Ok([testListing]);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(repository.fetchCalls, 2);
      expect(find.text('City bike'), findsOneWidget);
    });
  });

  group('given the marketplace has no listings', () {
    setUp(() => repository = FakeListingRepository(const Ok([])));

    testWidgets('when the page loads, then the empty state is shown', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byKey(const Key('listings_empty')), findsOneWidget);
      expect(find.text('No listings yet.'), findsOneWidget);
    });
  });
}
