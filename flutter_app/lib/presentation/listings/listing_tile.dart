import 'package:flutter/material.dart';

import '../../domain/models/listing.dart';
import '../../domain/models/money.dart';

/// One listing: image, title, price, author.
class ListingTile extends StatelessWidget {
  const ListingTile(this.listing, {super.key});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final image = listing.image;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox.square(
        dimension: 56,
        child: image == null
            ? const _NoImage()
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image.url,
                  fit: BoxFit.cover,
                  // Until the first frame arrives, show the placeholder
                  // rather than an empty box.
                  frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
                      frame == null && !wasSynchronouslyLoaded
                      ? const _NoImage()
                      : child,
                  // Offline, in tests, or a dead URL: show the placeholder.
                  errorBuilder: (_, _, _) => const _NoImage(),
                ),
              ),
      ),
      title: Text(listing.title),
      subtitle: Text(listing.author?.displayName ?? 'Unknown provider'),
      trailing: Text(
        listing.price == null ? '—' : formatPrice(listing.price!),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// Sharetribe money is minor units: 5000 USD cents reads as `50.00 USD`.
String formatPrice(Money price) =>
    '${(price.amount / 100).toStringAsFixed(2)} ${price.currency}';

class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.image_not_supported_outlined, size: 20),
  );
}
