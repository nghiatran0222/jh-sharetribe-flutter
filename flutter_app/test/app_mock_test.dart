import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/app.dart';
import 'package:sharetribe_flutter/app_dependencies.dart';
import 'package:sharetribe_flutter/core/env.dart';
import 'package:sharetribe_flutter/data/mock/mock_auth_repository.dart';
import 'package:sharetribe_flutter/data/sharetribe/token_store.dart';

/// The whole app in mock mode: no device, no network (ADR 0004).
void main() {
  late InMemoryTokenStore store;

  setUp(() => store = InMemoryTokenStore());

  /// Advances the test clock so the mock repositories' timers fire, without
  /// pumpAndSettle, which never settles on a progress indicator.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        dependencies: AppDependencies.fromEnv(
          const Env(mode: SharetribeMode.mock),
          tokenStore: store,
          mockLatency: Duration.zero,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> logIn(
    WidgetTester tester, {
    String password = 'password123',
  }) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'customer@test.com',
    );
    await tester.enterText(find.byType(TextFormField).last, password);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle(tester);
  }

  group('given no stored session', () {
    testWidgets('when the app starts, then the login page is shown', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.widgetWithText(AppBar, 'Log in'), findsOneWidget);
      expect(find.text('Listings'), findsNothing);
    });

    testWidgets('when the customer logs in, then the mock listings are shown', (
      tester,
    ) async {
      await pumpApp(tester);

      await logIn(tester);

      expect(find.widgetWithText(AppBar, 'Listings'), findsOneWidget);
      expect(find.text('City bike'), findsOneWidget);
      expect(find.text('Camping tent'), findsOneWidget);
      expect(find.text('Stand-up paddle board'), findsOneWidget);
      expect(find.text('15.00 USD'), findsOneWidget);
      expect(find.text('Pat P'), findsNWidgets(3));
      expect(await store.read(), isNotNull);
    });

    testWidgets(
      'when the password is wrong, then an error is shown and login stays',
      (tester) async {
        await pumpApp(tester);

        await logIn(tester, password: 'wrong');

        expect(find.byKey(const Key('login_error')), findsOneWidget);
        expect(find.text('Wrong email or password.'), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Log in'), findsOneWidget);
      },
    );
  });

  group('given a stored session', () {
    setUp(() async {
      await MockAuthRepository(
        store,
        latency: Duration.zero,
      ).login(email: 'customer@test.com', password: 'password123');
    });

    testWidgets('when the app starts, then it goes straight to the listings', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.widgetWithText(AppBar, 'Listings'), findsOneWidget);
      expect(find.text('City bike'), findsOneWidget);
    });

    testWidgets(
      'when the user logs out, then the tokens are cleared and login is shown',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pump();
        await tester.pump();

        expect(find.widgetWithText(AppBar, 'Log in'), findsOneWidget);
        expect(await store.read(), isNull);
      },
    );

    testWidgets(
      'when the list is pulled down, then the listings are refreshed',
      (tester) async {
        await pumpApp(tester);

        await tester.fling(find.text('City bike'), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('City bike'), findsOneWidget);
        await tester.pumpAndSettle();
      },
    );
  });
}
