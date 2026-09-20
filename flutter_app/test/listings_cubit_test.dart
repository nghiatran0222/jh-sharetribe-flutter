import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/presentation/listings/listings_cubit.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakeListingRepository listings;

  setUp(() => listings = FakeListingRepository());

  group('given published listings', () {
    setUp(() => listings.result = const Ok([testListing]));

    blocTest<ListingsCubit, ListingsState>(
      'emits [loading, loaded] when load is called',
      build: () => ListingsCubit(listings),
      act: (cubit) => cubit.load(),
      expect: () => const [
        ListingsLoading(),
        ListingsLoaded([testListing]),
      ],
    );

    blocTest<ListingsCubit, ListingsState>(
      'emits [loaded] without a loading state when pulled to refresh',
      build: () => ListingsCubit(listings),
      seed: () => const ListingsLoaded([]),
      act: (cubit) => cubit.refresh(),
      expect: () => const [
        ListingsLoaded([testListing]),
      ],
    );
  });

  group('given no listings', () {
    blocTest<ListingsCubit, ListingsState>(
      'emits [loading, loaded with none] when load is called',
      build: () => ListingsCubit(listings),
      act: (cubit) => cubit.load(),
      expect: () => const [ListingsLoading(), ListingsLoaded([])],
    );
  });

  group('given the marketplace cannot be reached', () {
    setUp(() => listings.result = networkFailure);

    blocTest<ListingsCubit, ListingsState>(
      'emits [loading, failed] when load is called',
      build: () => ListingsCubit(listings),
      act: (cubit) => cubit.load(),
      expect: () => const [ListingsLoading(), ListingsFailed(NetworkError())],
    );
  });
}
