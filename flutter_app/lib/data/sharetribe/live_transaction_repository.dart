import '../../core/result.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../json_api.dart';
import 'guard.dart';
import 'sharetribe_client.dart';

/// [TransactionRepository] against the Marketplace API.
///
/// `transactions/initiate` picks the process version by alias, so the app
/// starts every new request on `release-2` while transactions already
/// running on v1 keep their own rules (ADR 0003).
class LiveTransactionRepository implements TransactionRepository {
  LiveTransactionRepository(
    this._client, {
    this.processAlias = simpleRequestAlias,
  });

  final SharetribeClient _client;
  final String processAlias;

  @override
  Future<Result<Transaction>> requestListing({
    required String listingId,
    String note = '',
  }) => guard(() async {
    final body = await _client.postApi('transactions/initiate', {
      'processAlias': processAlias,
      'transition': transitionRequest,
      'params': {
        'listingId': listingId,
        if (note.trim().isNotEmpty)
          'protectedData': {'customerNote': note.trim()},
      },
    });
    return Transaction.fromJsonApi(JsonApiDocument.parse(body).data.single);
  });
}
