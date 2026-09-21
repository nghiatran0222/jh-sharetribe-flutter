import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/listing.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../listing_detail/listing_detail_page.dart';
import '../listing_detail/request_cubit.dart';
import '../login/auth_cubit.dart';
import 'listing_tile.dart';
import 'listings_cubit.dart';

/// The listings, with loading, empty and error states, pull-to-refresh and
/// logout.
class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logOut(),
          ),
        ],
      ),
      body: BlocBuilder<ListingsCubit, ListingsState>(
        builder: (context, state) => switch (state) {
          ListingsLoading() => const Center(child: CircularProgressIndicator()),
          ListingsFailed(:final error) => _Message(
            key: const Key('listings_error'),
            icon: Icons.error_outline,
            text: error.message,
            onRetry: () => context.read<ListingsCubit>().load(),
          ),
          ListingsLoaded(:final listings) when listings.isEmpty => _Message(
            key: const Key('listings_empty'),
            icon: Icons.inventory_2_outlined,
            text: 'No listings yet.',
            onRetry: () => context.read<ListingsCubit>().load(),
          ),
          ListingsLoaded(:final listings) => RefreshIndicator(
            onRefresh: context.read<ListingsCubit>().refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => ListingTile(
                listings[i],
                onTap: () => _openDetail(context, listings[i]),
              ),
            ),
          ),
        },
      ),
    );
  }
}

/// The detail page owns a `RequestCubit` for that one listing (P4b).
void _openDetail(BuildContext context, Listing listing) {
  final transactions = context.read<TransactionRepository>();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => RequestCubit(transactions),
        child: ListingDetailPage(listing),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.text,
    required this.onRetry,
  });

  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
