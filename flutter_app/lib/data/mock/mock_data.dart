/// Offline data for mock mode (ADR 0004). Listings are a JSON:API
/// `listings/query` body, so mock mode goes through the same
/// `JsonApiDocument` + `Listing.fromJsonApi` path as live mode.
library;

/// A mock account. Password for both: `password123`.
class MockAccount {
  const MockAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  /// Sharetribe's default display name: first name + last initial.
  String get displayName => '$firstName ${lastName.isEmpty ? '' : lastName[0]}';
}

const mockAccounts = [
  MockAccount(
    id: 'mock-user-customer',
    email: 'customer@test.com',
    password: 'password123',
    firstName: 'Casey',
    lastName: 'Customer',
  ),
  MockAccount(
    id: 'mock-user-provider',
    email: 'provider@test.com',
    password: 'password123',
    firstName: 'Pat',
    lastName: 'Provider',
  ),
];

Map<String, Object?> _listing(
  String n,
  String title,
  String description,
  int amount,
) => {
  'id': 'mock-listing-$n',
  'type': 'listing',
  'attributes': {
    'title': title,
    'description': description,
    'state': 'published',
    'price': {'amount': amount, 'currency': 'USD'},
  },
  'relationships': {
    'author': {
      'data': {'id': 'mock-user-provider', 'type': 'user'},
    },
    'images': {
      'data': [
        {'id': 'mock-image-$n', 'type': 'image'},
      ],
    },
  },
};

Map<String, Object?> _image(String n) => {
  'id': 'mock-image-$n',
  'type': 'image',
  'attributes': {
    'variants': {
      'landscape-crop': {
        'name': 'landscape-crop',
        'width': 800,
        'height': 600,
        'url': 'https://picsum.photos/seed/sharetribe-$n/800/600',
      },
    },
  },
};

/// Three published listings by the provider, with author and images.
final Map<String, Object?> mockListingsQuery = {
  'data': [
    _listing('1', 'City bike', 'A reliable 7-speed city bike.', 1500),
    _listing('2', 'Camping tent', 'Two-person tent, easy setup.', 2500),
    _listing('3', 'Stand-up paddle board', 'Inflatable, pump included.', 4000),
  ],
  'included': [
    {
      'id': 'mock-user-provider',
      'type': 'user',
      'attributes': {
        'profile': {'displayName': 'Pat P', 'abbreviatedName': 'PP'},
      },
    },
    _image('1'),
    _image('2'),
    _image('3'),
  ],
};
