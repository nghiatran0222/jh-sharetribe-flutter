import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/listing.dart';
import '../../domain/repositories/listing_repository.dart';

sealed class ListingsState {
  const ListingsState();
}

final class ListingsLoading extends ListingsState {
  const ListingsLoading();
}

/// Loaded, possibly empty.
final class ListingsLoaded extends ListingsState {
  const ListingsLoaded(this.listings);

  final List<Listing> listings;

  @override
  bool operator ==(Object other) =>
      other is ListingsLoaded && _sameIds(other.listings, listings);

  @override
  int get hashCode => Object.hashAll(listings.map((l) => l.id));

  static bool _sameIds(List<Listing> a, List<Listing> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);

  @override
  String toString() => 'ListingsLoaded(${listings.length})';
}

final class ListingsFailed extends ListingsState {
  const ListingsFailed(this.error);

  final AppError error;

  @override
  bool operator ==(Object other) =>
      other is ListingsFailed && other.error.runtimeType == error.runtimeType;

  @override
  int get hashCode => error.runtimeType.hashCode;

  @override
  String toString() => 'ListingsFailed($error)';
}

/// The catalog for the listings page.
class ListingsCubit extends Cubit<ListingsState> {
  ListingsCubit(this._listings) : super(const ListingsLoading());

  final ListingRepository _listings;

  /// Loads the listings. A pull-to-refresh passes `showLoading: false` so the
  /// current list stays on screen while the new one arrives.
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(const ListingsLoading());
    switch (await _listings.fetchListings()) {
      case Ok(:final value):
        emit(ListingsLoaded(value));
      case Err(:final error):
        emit(ListingsFailed(error));
    }
  }

  Future<void> refresh() => load(showLoading: false);
}
