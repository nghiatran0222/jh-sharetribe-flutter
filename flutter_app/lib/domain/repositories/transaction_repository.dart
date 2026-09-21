import '../../core/result.dart';
import '../models/transaction.dart';

/// Transactions: starting a request on the `simple-request` process.
///
/// In v2 a request lands in `state/pending` and waits for the provider to
/// accept or decline (ADR 0007).
abstract interface class TransactionRepository {
  /// Sends `transition/request` on `simple-request/release-2` for [listingId].
  /// [note] is optional and reaches the provider as protected data.
  Future<Result<Transaction>> requestListing({
    required String listingId,
    String note,
  });
}
