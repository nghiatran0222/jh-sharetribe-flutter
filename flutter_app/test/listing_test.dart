import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/data/json_api.dart';
import 'package:sharetribe_flutter/domain/models/listing.dart';
import 'package:sharetribe_flutter/domain/models/listing_image.dart';
import 'package:sharetribe_flutter/domain/models/money.dart';
import 'package:sharetribe_flutter/domain/models/user.dart';

import 'support/fake_adapter.dart';

void main() {
  group('given a listings/query response with included author and images', () {
    late List<JsonApiResource> resources;

    setUp(() {
      resources = JsonApiDocument.parse(fixture('listings_query.json')).data;
    });

    test('when mapped, then title, price, author and image are set', () {
      final listing = Listing.fromJsonApi(resources.first);

      expect(listing.id, '5a8f4c3e-0000-4000-8000-000000000001');
      expect(listing.title, 'Canoe for a weekend');
      expect(listing.description, 'Two-person canoe with paddles.');
      expect(listing.price, const Money(amount: 5000, currency: 'USD'));
      expect(
        listing.author,
        const User(
          id: '5a8f4c3e-0000-4000-8000-0000000000a1',
          displayName: 'Pat P',
        ),
      );
      expect(
        listing.image,
        const ListingImage(
          id: '5a8f4c3e-0000-4000-8000-0000000000i1',
          url: 'https://sharetribe.imgix.net/canoe.jpg?w=800',
          width: 800,
          height: 600,
        ),
      );
    });

    test('when a listing has no images and no price, then both are null', () {
      final listing = Listing.fromJsonApi(resources[1]);

      expect(listing.title, 'Tent, no photos');
      expect(listing.image, isNull);
      expect(listing.price, isNull);
      expect(listing.author?.displayName, 'Pat P');
    });

    test('when the requested image variant is missing, then image is null', () {
      final listing = Listing.fromJsonApi(resources[2]);

      expect(listing.image, isNull);
      expect(listing.price, const Money(amount: 3500, currency: 'EUR'));
    });

    test('when another variant is requested, then that variant is used', () {
      final listing = Listing.fromJsonApi(
        resources[2],
        imageVariant: 'square-small',
      );

      expect(
        listing.image?.url,
        'https://sharetribe.imgix.net/kayak.jpg?w=240',
      );
    });

    test('when the author is not included, then author is null', () {
      final listing = Listing.fromJsonApi(resources[2]);

      expect(listing.author, isNull);
    });
  });
}
