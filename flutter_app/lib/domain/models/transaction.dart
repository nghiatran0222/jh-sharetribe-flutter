import '../../data/json_api.dart';

/// The process alias the app starts transactions on (ADR 0003). `release-1`
/// stays on version 1 and is never used by the app.
const simpleRequestAlias = 'simple-request/release-2';

/// The customer's opening transition (`sharetribe/simple-request*/process.edn`).
/// Process names are used verbatim (ADR 0011).
const transitionRequest = 'transition/request';

/// One run of the `simple-request` process between a customer and a provider.
class Transaction {
  const Transaction({
    required this.id,
    required this.lastTransition,
    this.processName = '',
  });

  /// Maps a `transaction` resource from `transactions/initiate`.
  factory Transaction.fromJsonApi(JsonApiResource resource) => Transaction(
    id: resource.id,
    lastTransition: (resource.attributes['lastTransition'] ?? '') as String,
    processName: (resource.attributes['processName'] ?? '') as String,
  );

  final String id;

  /// The transition that put the transaction in its current state, e.g.
  /// `transition/request`.
  final String lastTransition;
  final String processName;

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.lastTransition == lastTransition &&
      other.processName == processName;

  @override
  int get hashCode => Object.hash(id, lastTransition, processName);

  @override
  String toString() => 'Transaction($id, $lastTransition)';
}
