import '../../data/json_api.dart';
import 'listing_image.dart';
import 'money.dart';
import 'user.dart';

/// The image variant the app asks for with `fields.image`.
const defaultImageVariant = 'landscape-crop';

/// Something a provider offers.
class Listing {
  const Listing({
    required this.id,
    required this.title,
    this.description = '',
    this.price,
    this.author,
    this.image,
  });

  /// The only place a JSON:API listing becomes a [Listing] (ADR 0011).
  ///
  /// [resource] comes from `JsonApiDocument`, with `author` and `images`
  /// resolved from `included`. [image] is the first image's [imageVariant];
  /// a missing image or variant maps to null, never an error.
  factory Listing.fromJsonApi(
    JsonApiResource resource, {
    String imageVariant = defaultImageVariant,
  }) {
    final attributes = resource.attributes;
    final author = resource.one('author');
    final images = resource.many('images');
    return Listing(
      id: resource.id,
      title: (attributes['title'] ?? '') as String,
      description: (attributes['description'] ?? '') as String,
      price: _money(attributes['price']),
      author: author == null ? null : User.fromJsonApi(author),
      image: images.isEmpty ? null : _variant(images.first, imageVariant),
    );
  }

  final String id;
  final String title;
  final String description;

  /// Null when the listing has no price.
  final Money? price;

  /// The provider. Null when `author` was not included.
  final User? author;

  /// Null when the listing has no image or the variant is missing.
  final ListingImage? image;

  static Money? _money(Object? raw) {
    if (raw is! Map) return null;
    final amount = raw['amount'];
    final currency = raw['currency'];
    if (amount is! int || currency is! String) return null;
    return Money(amount: amount, currency: currency);
  }

  static ListingImage? _variant(JsonApiResource image, String name) {
    final variants = image.attributes['variants'];
    if (variants is! Map) return null;
    final variant = variants[name];
    if (variant is! Map || variant['url'] is! String) return null;
    return ListingImage(
      id: image.id,
      url: variant['url'] as String,
      width: variant['width'] as int?,
      height: variant['height'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Listing &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.price == price &&
      other.author == author &&
      other.image == image;

  @override
  int get hashCode => Object.hash(id, title, description, price, author, image);

  @override
  String toString() => 'Listing($id, $title)';
}
