import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/data/json_api.dart';

import 'support/fake_adapter.dart';

void main() {
  group('given a listings/query response with included author and images', () {
    late JsonApiDocument document;

    setUp(
      () => document = JsonApiDocument.parse(fixture('listings_query.json')),
    );

    test('when parsed, then data keeps order, ids and types', () {
      expect(document.data.map((r) => r.type), everyElement('listing'));
      expect(document.data.map((r) => r.id), [
        '5a8f4c3e-0000-4000-8000-000000000001',
        '5a8f4c3e-0000-4000-8000-000000000002',
        '5a8f4c3e-0000-4000-8000-000000000003',
      ]);
      expect(document.data.first.attributes['title'], 'Canoe for a weekend');
    });

    test(
      'when a to-one relationship is read, then it resolves from included',
      () {
        final author = document.data.first.one('author');

        expect(author?.type, 'user');
        expect(author?.id, '5a8f4c3e-0000-4000-8000-0000000000a1');
        expect(
          author?.attributes['profile'],
          containsPair('displayName', 'Pat P'),
        );
      },
    );

    test(
      'when a to-many relationship is read, then it resolves from included',
      () {
        final images = document.data.first.many('images');

        expect(images.map((r) => r.id), [
          '5a8f4c3e-0000-4000-8000-0000000000i1',
        ]);
        expect(
          images.single.attributes['variants'],
          contains('landscape-crop'),
        );
      },
    );

    test('when a relationship is empty, then many returns an empty list', () {
      expect(document.data[1].many('images'), isEmpty);
    });

    test(
      'when a relationship is not in the resource, then one returns null',
      () {
        expect(document.data.first.one('marketplace'), isNull);
        expect(document.data.first.many('reviews'), isEmpty);
      },
    );
  });

  group('given a relationship whose resource is not included', () {
    test('when read, then it is skipped instead of throwing', () {
      final document = JsonApiDocument.parse({
        'data': {
          'id': 'l1',
          'type': 'listing',
          'attributes': {'title': 'x'},
          'relationships': {
            'author': {
              'data': {'id': 'u9', 'type': 'user'},
            },
            'images': {
              'data': [
                {'id': 'i9', 'type': 'image'},
              ],
            },
          },
        },
      });

      expect(document.data.single.one('author'), isNull);
      expect(document.data.single.many('images'), isEmpty);
    });
  });

  group('given a single-resource document', () {
    test('when parsed, then data has one resource', () {
      final document = JsonApiDocument.parse(fixture('current_user_show.json'));

      expect(document.data.single.type, 'currentUser');
      expect(document.data.single.attributes['email'], 'customer@test.com');
    });
  });

  group('given a body that is not JSON:API', () {
    test('when parsed, then it throws FormatException', () {
      expect(
        () => JsonApiDocument.parse({'error': 'nope'}),
        throwsFormatException,
      );
      expect(
        () => JsonApiDocument.parse({
          'data': [
            {'type': 'listing'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
