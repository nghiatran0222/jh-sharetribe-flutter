import 'core/env.dart';
import 'data/mock/mock_auth_repository.dart';
import 'data/mock/mock_listing_repository.dart';
import 'data/sharetribe/live_auth_repository.dart';
import 'data/sharetribe/live_listing_repository.dart';
import 'data/sharetribe/sharetribe_client.dart';
import 'data/sharetribe/token_store.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/listing_repository.dart';

/// The composition root: the one place that decides mock or live (ADR 0004).
///
/// Widget tests build this with an [InMemoryTokenStore], because tests have
/// no platform channels for flutter_secure_storage (ADR 0010).
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.listingRepository,
  });

  /// Builds the repositories for [env]. [tokenStore] overrides the default
  /// [SecureTokenStore]; tests pass an [InMemoryTokenStore].
  factory AppDependencies.fromEnv(
    Env env, {
    TokenStore? tokenStore,
    Duration mockLatency = _mockLatency,
  }) {
    final store = tokenStore ?? SecureTokenStore();
    if (env.mode == SharetribeMode.mock) {
      // Mock mode keeps a fake session in the same store, so session restore
      // and logout behave exactly as they do live.
      return AppDependencies(
        authRepository: MockAuthRepository(store, latency: mockLatency),
        listingRepository: MockListingRepository(store, latency: mockLatency),
      );
    }
    final client = SharetribeClient(clientId: env.clientId, tokenStore: store);
    return AppDependencies(
      authRepository: LiveAuthRepository(client, store),
      listingRepository: LiveListingRepository(client),
    );
  }

  /// Enough delay to see loading states by hand; tests pass `Duration.zero`.
  static const _mockLatency = Duration(milliseconds: 300);

  final AuthRepository authRepository;
  final ListingRepository listingRepository;
}
