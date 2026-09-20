import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/data/json_api.dart';
import 'package:sharetribe_flutter/domain/models/listing.dart';

import 'support/fake_adapter.dart';

/// The API contract check (ADR 0015).
///
/// `listings_query_live.json` is a real `GET /v1/api/listings/query` response
/// from the `nghiatran-test` marketplace, captured in P7 with
/// `include=author,images&fields.image=variants.landscape-crop&perPage=5`.
/// Ids, the provider's display name and the signed image URLs were replaced;
/// every field name, nesting level and value type is exactly as Sharetribe
/// returned it. If Sharetribe's shapes and our parser ever diverge, this is
/// the test that fails — the hand-written fixtures cannot catch that, because
/// the same person wrote them and the parser.
void main() {
  late List<Listing> listings;
  late Map<String, Object?> body;

  setUp(() {
    body = fixture('listings_query_live.json');
    listings = [
      for (final resource in JsonApiDocument.parse(body).data)
        Listing.fromJsonApi(resource),
    ];
  });

  group('given a real listings/query response from Sharetribe', () {
    test('when parsed, then every listing keeps its title and id', () {
      expect(listings, hasLength(5));
      expect(listings.map((l) => l.title), [
        'Bamboo Cutting Board',
        'Sweet Cherry Tomatoes',
        'Wall-Mounted Spice Rack',
        'Silicone Wine Glasses',
        'Pet Grooming Kit',
      ]);
      expect(listings.map((l) => l.id), everyElement(isNotEmpty));
    });

    test('when parsed, then prices keep Sharetribe minor units', () {
      final price = listings.first.price!;

      expect(price.amount, 4999);
      expect(price.currency, 'USD');
      expect(listings.map((l) => l.price?.amount), [
        4999,
        1899,
        899,
        1299,
        599,
      ]);
    });

    test(
      'when parsed, then the author relationship resolves from included',
      () {
        expect(
          listings.map((l) => l.author?.displayName),
          everyElement('Sandbox P'),
        );
        // A listing author is a public user: no email is exposed.
        expect(listings.map((l) => l.author?.email), everyElement(isNull));
      },
    );

    test('when parsed, then the requested image variant is used', () {
      final image = listings.first.image!;

      expect(image.url, contains('sharetribe.imgix.net'));
      expect(image.width, isNotNull);
      expect(image.height, isNotNull);
      expect(listings.map((l) => l.image), everyElement(isNotNull));
    });

    test(
      'when a different variant is requested, then no image is returned',
      () {
        // The live query asked only for landscape-crop, so nothing else exists.
        final other = [
          for (final r in JsonApiDocument.parse(body).data)
            Listing.fromJsonApi(r, imageVariant: 'square-small'),
        ];

        expect(other.map((l) => l.image), everyElement(isNull));
      },
    );

    test(
      'when read, then meta reports more pages than this response holds',
      () {
        // The app fetches one page (perPage: 50). Paging is not implemented;
        // this pins the shape the live API returns, for when it is.
        final meta = body['meta']! as Map<String, Object?>;

        expect(meta['totalItems'], 10);
        expect(meta['totalPages'], 2);
        expect(meta['perPage'], 5);
      },
    );
  });
}
