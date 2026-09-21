import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../sharetribe/guard.dart';
import '../sharetribe/token_store.dart';

/// Offline [TransactionRepository]. Keeps the requests it created in memory,
/// so a mock run behaves like the real one: a request needs a session, and
/// the same listing cannot be requested twice.
class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository(this._store, {this.latency = Duration.zero});

  final TokenStore _store;
  final Duration latency;

  /// listing id -> the transaction started for it.
  final Map<String, Transaction> requests = {};

  @override
  Future<Result<Transaction>> requestListing({
    required String listingId,
    String note = '',
  }) async {
    await Future<void>.delayed(latency);
    final session = await guard(_store.read);
    if (session case Err(:final error)) return Err(error);
    if (session.valueOrNull == null) return const Err(Unauthorized());
    if (requests.containsKey(listingId)) {
      return const Err(AlreadyRequested());
    }
    final transaction = Transaction(
      id: 'mock-tx-${requests.length + 1}',
      lastTransition: transitionRequest,
      processName: 'simple-request',
    );
    requests[listingId] = transaction;
    return Ok(transaction);
  }
}
