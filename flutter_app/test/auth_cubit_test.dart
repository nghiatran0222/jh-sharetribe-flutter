import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/app_error.dart';
import 'package:sharetribe_flutter/core/result.dart';
import 'package:sharetribe_flutter/presentation/login/auth_cubit.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('given a stored session', () {
    setUp(() => auth.restoreResult = const Ok(testUser));

    blocTest<AuthCubit, AuthState>(
      'emits [unknown, authenticated] when the session is restored',
      build: () => AuthCubit(auth),
      act: (cubit) => cubit.restoreSession(),
      expect: () => const [AuthUnknown(), AuthAuthenticated(testUser)],
    );
  });

  group('given no stored session', () {
    blocTest<AuthCubit, AuthState>(
      'emits [unknown, unauthenticated] when the session is restored',
      build: () => AuthCubit(auth),
      act: (cubit) => cubit.restoreSession(),
      expect: () => const [AuthUnknown(), AuthUnauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [submitting, authenticated] when login succeeds',
      build: () => AuthCubit(auth),
      act: (cubit) =>
          cubit.logIn(email: 'customer@test.com', password: 'password123'),
      expect: () => const [
        AuthUnauthenticated(submitting: true),
        AuthAuthenticated(testUser),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [submitting, error] when the password is wrong',
      build: () => AuthCubit(auth),
      setUp: () => auth.loginResult = const Err(InvalidCredentials()),
      act: (cubit) => cubit.logIn(email: 'customer@test.com', password: 'nope'),
      expect: () => const [
        AuthUnauthenticated(submitting: true),
        AuthUnauthenticated(error: InvalidCredentials()),
      ],
    );
  });

  group('given a logged-in user', () {
    blocTest<AuthCubit, AuthState>(
      'emits [unauthenticated] and clears the session when logging out',
      build: () => AuthCubit(auth),
      seed: () => const AuthAuthenticated(testUser),
      act: (cubit) => cubit.logOut(),
      expect: () => const [AuthUnauthenticated()],
      verify: (_) => expect(auth.logoutCalls, 1),
    );
  });
}
