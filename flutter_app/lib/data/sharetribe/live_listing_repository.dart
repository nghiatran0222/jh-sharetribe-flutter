import '../../core/result.dart';
import '../../domain/models/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../json_api.dart';
import 'guard.dart';
import 'sharetribe_client.dart';

/// [ListingRepository] against the Sharetribe Marketplace API.
class LiveListingRepository implements ListingRepository {
  LiveListingRepository(
    this._client, {
    this.imageVariant = defaultImageVariant,
    this.perPage = 50,
  });

  final SharetribeClient _client;
  final String imageVariant;
  final int perPage;

  @override
  Future<Result<List<Listing>>> fetchListings() => guard(() async {
    final body = await _client.getApi(
      'listings/query',
      query: {
        'include': 'author,images',
        'fields.image': 'variants.$imageVariant',
        'perPage': perPage,
      },
    );
    return [
      for (final resource in JsonApiDocument.parse(body).data)
        if (resource.type == 'listing')
          Listing.fromJsonApi(resource, imageVariant: imageVariant),
    ];
  });
}
