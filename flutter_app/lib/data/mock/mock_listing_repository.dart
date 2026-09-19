import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../json_api.dart';
import '../sharetribe/token_store.dart';
import 'mock_data.dart';

/// Offline [ListingRepository] over [mockListingsQuery]. Like live mode,
/// listings need a logged-in user.
class MockListingRepository implements ListingRepository {
  MockListingRepository(this._store, {this.latency = Duration.zero});

  final TokenStore _store;
  final Duration latency;

  @override
  Future<Result<List<Listing>>> fetchListings() async {
    await Future<void>.delayed(latency);
    if (await _store.read() == null) return const Err(Unauthorized());
    final document = JsonApiDocument.parse(mockListingsQuery);
    return Ok([for (final r in document.data) Listing.fromJsonApi(r)]);
  }
}
