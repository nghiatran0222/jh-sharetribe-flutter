import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/domain/models/listing.dart';
import 'package:sharetribe_flutter/domain/models/user.dart';
import 'package:sharetribe_flutter/domain/repositories/auth_repository.dart';
import 'package:sharetribe_flutter/domain/models/transaction.dart';
import 'package:sharetribe_flutter/domain/repositories/listing_repository.dart';
import 'package:sharetribe_flutter/domain/repositories/transaction_repository.dart';

const testUser = User(
  id: 'u1',
  displayName: 'Casey C',
  email: 'customer@test.com',
);

/// An [AuthRepository] that answers with whatever the test sets, and records
/// the calls. Hand-written: the repo has no mocking package (ADR 0014).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult = const Ok(testUser),
    this.restoreResult = const Ok(null),
  });

  Result<User> loginResult;
  Result<User?> restoreResult;
  int logoutCalls = 0;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async => loginResult;

  @override
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async => loginResult;

  @override
  Future<Result<User?>> restoreSession() async => restoreResult;

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    return const Ok(null);
  }
}

class FakeListingRepository implements ListingRepository {
  FakeListingRepository([this.result = const Ok(<Listing>[])]);

  Result<List<Listing>> result;
  int fetchCalls = 0;

  @override
  Future<Result<List<Listing>>> fetchListings() async {
    fetchCalls++;
    return result;
  }
}

const testListing = Listing(id: 'l1', title: 'City bike');
const networkFailure = Err<List<Listing>>(NetworkError());

/// A [TransactionRepository] that answers with whatever the test sets.
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository([this.result = const Ok(testTransaction)]);

  Result<Transaction> result;
  final List<({String listingId, String note})> calls = [];

  @override
  Future<Result<Transaction>> requestListing({
    required String listingId,
    String note = '',
  }) async {
    calls.add((listingId: listingId, note: note));
    return result;
  }
}

const testTransaction = Transaction(
  id: 'tx1',
  lastTransition: transitionRequest,
  processName: 'simple-request',
);
