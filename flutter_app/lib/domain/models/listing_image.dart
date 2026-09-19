/// One server-sized image variant (e.g. `landscape-crop`) of a listing image.
class ListingImage {
  const ListingImage({
    required this.id,
    required this.url,
    this.width,
    this.height,
  });

  final String id;
  final String url;
  final int? width;
  final int? height;

  @override
  bool operator ==(Object other) =>
      other is ListingImage &&
      other.id == id &&
      other.url == url &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(id, url, width, height);

  @override
  String toString() => 'ListingImage($id, $url)';
}
