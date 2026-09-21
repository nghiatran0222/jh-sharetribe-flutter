import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/listing.dart';
import '../listings/listing_tile.dart';
import '../login/auth_cubit.dart';
import 'request_cubit.dart';

/// One listing, with a note and a Request button that starts a transaction
/// on `simple-request/release-2` (P4b).
class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage(this.listing, {super.key});

  final Listing listing;

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final price = listing.price;
    // `transition/request` is a customer transition: Sharetribe refuses a
    // request on your own listing (transaction-same-author-and-customer).
    final auth = context.watch<AuthCubit>().state;
    final ownListing =
        auth is AuthAuthenticated && auth.user.id == listing.author?.id;
    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: BlocBuilder<RequestCubit, RequestState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              listing.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (price != null) formatPrice(price),
                if (listing.author != null) 'by ${listing.author!.displayName}',
              ].join('  ·  '),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (listing.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(listing.description),
            ],
            const SizedBox(height: 24),
            if (ownListing)
              const Card(
                key: Key('own_listing'),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'This is your listing. Only a customer can request it; '
                    'as the provider you accept or decline requests in '
                    'Console.',
                  ),
                ),
              )
            else if (state is RequestSent)
              _Sent(key: const Key('request_sent'), state: state)
            else ...[
              TextField(
                key: const Key('request_note'),
                controller: _note,
                enabled: state is! RequestSending,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message to the provider (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (state is RequestFailed) ...[
                const SizedBox(height: 12),
                Text(
                  state.error.message,
                  key: const Key('request_error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('request_button'),
                onPressed: state is RequestSending
                    ? null
                    : () => context.read<RequestCubit>().request(
                        listingId: listing.id,
                        note: _note.text,
                      ),
                child: state is RequestSending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Sent extends StatelessWidget {
  const _Sent({super.key, required this.state});

  final RequestSent state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Request sent',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // v2: the provider must accept or decline, and an unanswered
            // request expires after three days (ADR 0007).
            const Text(
              'Waiting for the provider to accept or decline. '
              'Unanswered requests expire after 3 days.',
            ),
          ],
        ),
      ),
    );
  }
}
