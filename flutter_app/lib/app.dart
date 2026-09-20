import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_dependencies.dart';
import 'domain/repositories/listing_repository.dart';
import 'presentation/listings/listings_cubit.dart';
import 'presentation/listings/listings_page.dart';
import 'presentation/login/auth_cubit.dart';
import 'presentation/login/login_page.dart';

/// Wires the repositories and Cubits, then shows login or listings.
class App extends StatelessWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: dependencies.listingRepository,
      child: BlocProvider(
        create: (_) => AuthCubit(dependencies.authRepository)..restoreSession(),
        child: MaterialApp(
          title: 'Sharetribe',
          theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
          home: const _Home(),
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => switch (state) {
        AuthUnknown() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthUnauthenticated() => const LoginPage(),
        // Keyed by user, so logging in as someone else reloads the listings.
        AuthAuthenticated(:final user) => BlocProvider(
          key: ValueKey(user.id),
          create: (context) =>
              ListingsCubit(context.read<ListingRepository>())..load(),
          child: const ListingsPage(),
        ),
      },
    );
  }
}
