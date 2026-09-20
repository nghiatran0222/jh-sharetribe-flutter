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

/// Title, description and price in cents for each mock listing. The first
/// three are asserted by name in tests; the rest exist so the list scrolls
/// and paging-sized responses are realistic (more than one screen).
const _catalog = <(String, String, int)>[
  ('City bike', 'A reliable 7-speed city bike.', 1500),
  ('Camping tent', 'Two-person tent, easy setup.', 2500),
  ('Stand-up paddle board', 'Inflatable, pump included.', 4000),
  ('Road bike', 'Carbon frame, 11-speed.', 3500),
  ('Mountain bike', 'Full suspension, 29 inch.', 3800),
  ('Kayak', 'Single-seat, paddle included.', 3000),
  ('Canoe', 'Two-person canoe with paddles.', 5000),
  ('Surfboard', '7ft funboard, leash included.', 2800),
  ('Wetsuit', '4/3mm, size M.', 1200),
  ('Snowboard', 'All-mountain, 156cm.', 3200),
  ('Ski set', 'Skis, poles and boots, size 42.', 4200),
  ('Sleeping bag', 'Comfort to -5C.', 900),
  ('Camping stove', 'Two burners, gas not included.', 800),
  ('Cool box', '40 litres, keeps cold 36h.', 700),
  ('Hiking backpack', '60 litres, rain cover.', 1100),
  ('Trekking poles', 'Aluminium, adjustable.', 500),
  ('Espresso machine', 'Portable, hand pump.', 1400),
  ('Projector', '1080p, HDMI and USB-C.', 2600),
  ('PA speaker', '300W with stand and cable.', 4500),
  ('DJ controller', 'Two decks, USB powered.', 5200),
  ('DSLR camera', '24MP with 18-55mm lens.', 4800),
  ('Drone', '4K camera, two batteries.', 6500),
  ('Pressure washer', '1800W, 3 nozzles.', 1600),
  ('Garden trailer', 'Tows behind a bike.', 1000),
];

/// The mock marketplace: every listing above, by the provider, with an image.
final Map<String, Object?> mockListingsQuery = {
  'data': [
    for (final (i, (title, description, amount)) in _catalog.indexed)
      _listing('${i + 1}', title, description, amount),
  ],
  'included': [
    {
      'id': 'mock-user-provider',
      'type': 'user',
      'attributes': {
        'profile': {'displayName': 'Pat P', 'abbreviatedName': 'PP'},
      },
    },
    for (var i = 1; i <= _catalog.length; i++) _image('$i'),
  ],
};
