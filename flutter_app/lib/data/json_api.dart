/// JSON:API denormalizer for Sharetribe Marketplace API responses.
///
/// Sharetribe returns `data` (one resource or a list) plus `included`
/// (related resources, e.g. `author`, `images`) linked through
/// `relationships`. This is the only place that walks those raw maps;
/// models are built from [JsonApiResource] by their `fromJsonApi` factories.
library;

/// A parsed JSON:API response body.
class JsonApiDocument {
  JsonApiDocument._(this.data);

  /// Parses a decoded response body. Throws [FormatException] when the body
  /// has no `data`, or a resource has no `id` or `type`.
  factory JsonApiDocument.parse(Map<String, Object?> body) {
    if (!body.containsKey('data')) {
      throw const FormatException('JSON:API body has no "data"');
    }
    final index = <(String, String), JsonApiResource>{};
    final included = body['included'];
    if (included is List) {
      for (final raw in included) {
        final resource = JsonApiResource._parse(raw, index);
        index[(resource.type, resource.id)] = resource;
      }
    }
    final rawData = body['data'];
    final data = switch (rawData) {
      null => const <JsonApiResource>[],
      List() => [for (final raw in rawData) JsonApiResource._parse(raw, index)],
      _ => [JsonApiResource._parse(rawData, index)],
    };
    return JsonApiDocument._(data);
  }

  /// The primary resources, in response order. A single-resource response
  /// becomes a one-element list.
  final List<JsonApiResource> data;
}

/// One resource, with its relationships resolvable against `included`.
class JsonApiResource {
  JsonApiResource._(
    this.id,
    this.type,
    this.attributes,
    this._links,
    this._index,
  );

  factory JsonApiResource._parse(
    Object? raw,
    Map<(String, String), JsonApiResource> index,
  ) {
    if (raw is! Map) {
      throw const FormatException('JSON:API resource is not an object');
    }
    final id = _id(raw['id']);
    final type = raw['type'];
    if (id == null || type is! String) {
      throw const FormatException('JSON:API resource needs "id" and "type"');
    }
    final attributes = raw['attributes'];
    final relationships = raw['relationships'];
    return JsonApiResource._(
      id,
      type,
      attributes is Map ? Map<String, Object?>.from(attributes) : const {},
      relationships is Map
          ? Map<String, Object?>.from(relationships)
          : const {},
      index,
    );
  }

  final String id;
  final String type;
  final Map<String, Object?> attributes;
  final Map<String, Object?> _links;
  final Map<(String, String), JsonApiResource> _index;

  /// The related resource for a to-one relationship, or null when the
  /// relationship is absent, empty, or its resource was not included.
  JsonApiResource? one(String relationship) {
    final data = _linkData(relationship);
    return data is Map ? _resolve(data) : null;
  }

  /// The related resources for a to-many relationship that were included,
  /// in order. Empty when the relationship is absent.
  List<JsonApiResource> many(String relationship) {
    final data = _linkData(relationship);
    if (data is! List) return const [];
    return [
      for (final ref in data)
        if (ref is Map) ?_resolve(ref),
    ];
  }

  Object? _linkData(String relationship) {
    final link = _links[relationship];
    return link is Map ? link['data'] : null;
  }

  JsonApiResource? _resolve(Map<Object?, Object?> ref) {
    final id = _id(ref['id']);
    final type = ref['type'];
    if (id == null || type is! String) return null;
    return _index[(type, id)];
  }

  /// Sharetribe ids are UUID strings; tolerate the SDK's `{uuid: ...}` shape.
  static String? _id(Object? raw) => switch (raw) {
    String() => raw,
    Map() when raw['uuid'] is String => raw['uuid'] as String,
    _ => null,
  };
}
