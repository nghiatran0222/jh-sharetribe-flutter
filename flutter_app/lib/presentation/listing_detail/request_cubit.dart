import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_error.dart';
import '../../core/result.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

sealed class RequestState {
  const RequestState();
}

/// Nothing sent yet.
final class RequestIdle extends RequestState {
  const RequestIdle();

  @override
  bool operator ==(Object other) => other is RequestIdle;

  @override
  int get hashCode => 0;
}

final class RequestSending extends RequestState {
  const RequestSending();

  @override
  bool operator ==(Object other) => other is RequestSending;

  @override
  int get hashCode => 1;
}

/// The provider now has a pending request (v2, ADR 0007).
final class RequestSent extends RequestState {
  const RequestSent(this.transaction);

  final Transaction transaction;

  @override
  bool operator ==(Object other) =>
      other is RequestSent && other.transaction == transaction;

  @override
  int get hashCode => transaction.hashCode;
}

final class RequestFailed extends RequestState {
  const RequestFailed(this.error);

  final AppError error;

  @override
  bool operator ==(Object other) =>
      other is RequestFailed && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

/// Sends `transition/request` for one listing (P4b, ADR 0005).
class RequestCubit extends Cubit<RequestState> {
  RequestCubit(this._transactions) : super(const RequestIdle());

  final TransactionRepository _transactions;

  Future<void> request({required String listingId, String note = ''}) async {
    if (state is RequestSending || state is RequestSent) return;
    emit(const RequestSending());
    switch (await _transactions.requestListing(
      listingId: listingId,
      note: note,
    )) {
      case Ok(:final value):
        emit(RequestSent(value));
      case Err(:final error):
        emit(RequestFailed(error));
    }
  }
}
