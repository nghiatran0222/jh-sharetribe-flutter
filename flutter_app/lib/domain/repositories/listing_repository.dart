import '../../core/result.dart';
import '../models/listing.dart';

/// Catalog: the marketplace's listings. Implemented by the mock and the live
/// repository.
abstract interface class ListingRepository {
  /// Listings with their author and image; needs a logged-in user.
  Future<Result<List<Listing>>> fetchListings();
}
