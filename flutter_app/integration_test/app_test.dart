import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sharetribe_flutter/app.dart';
import 'package:sharetribe_flutter/app_dependencies.dart';
import 'package:sharetribe_flutter/core/env.dart';
import 'package:sharetribe_flutter/data/sharetribe/token_store.dart';

/// End-to-end on a real device or simulator, in mock mode (ADR 0016).
///
/// Unlike `test/app_mock_test.dart`, this runs on a real engine with a real
/// [SecureTokenStore], so it is the only test that exercises Keychain /
/// Keystore and session restore across a relaunch.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_test.dart -d `<device>`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// The same wiring `main.dart` uses: mock repositories, real token store.
  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(
      App(dependencies: AppDependencies.fromEnv(Env.fromDartDefines())),
    );
    await tester.pump();
  }

  /// Pumps real frames until [finder] matches. `pumpAndSettle` cannot be used
  /// here: a CircularProgressIndicator never stops animating.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for: $finder');
  }

  Future<void> logIn(WidgetTester tester, {required String password}) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'customer@test.com',
    );
    await tester.enterText(find.byType(TextFormField).last, password);
    // On a real engine the software keyboard shrinks the viewport, which can
    // push the button out of reach; close it and scroll the button into view.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    final button = find.widgetWithText(FilledButton, 'Log in');
    await tester.ensureVisible(button);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(button);
  }

  setUp(() => SecureTokenStore().clear());
  tearDownAll(() => SecureTokenStore().clear());

  group('given a device with no stored session', () {
    testWidgets('when the customer logs in, then the listings are shown', (
      tester,
    ) async {
      await launchApp(tester);
      await waitFor(tester, find.widgetWithText(AppBar, 'Log in'));
      await binding.takeScreenshot('01-login');

      await logIn(tester, password: 'password123');
      await waitFor(tester, find.text('City bike'));

      expect(find.widgetWithText(AppBar, 'Listings'), findsOneWidget);
      expect(find.text('Camping tent'), findsOneWidget);
      expect(find.text('Stand-up paddle board'), findsOneWidget);
      expect(find.text('15.00 USD'), findsOneWidget);
      // Let the listing images decode before the screenshot is taken.
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot('02-listings');

      // The real Keychain / Keystore now holds the session.
      expect(await SecureTokenStore().read(), isNotNull);
    });

    testWidgets('when the password is wrong, then an error is shown', (
      tester,
    ) async {
      await launchApp(tester);
      await waitFor(tester, find.widgetWithText(AppBar, 'Log in'));

      await logIn(tester, password: 'wrong');
      await waitFor(tester, find.byKey(const Key('login_error')));

      expect(find.text('Wrong email or password.'), findsOneWidget);
      await binding.takeScreenshot('03-login-error');
      expect(await SecureTokenStore().read(), isNull);
    });
  });

  group('given a session stored on the device', () {
    testWidgets(
      'when the app is relaunched, then it restores the session and logout clears it',
      (tester) async {
        await launchApp(tester);
        await waitFor(tester, find.widgetWithText(AppBar, 'Log in'));
        await logIn(tester, password: 'password123');
        await waitFor(tester, find.text('City bike'));

        // Relaunch: a fresh widget tree, reading the tokens off the device.
        await launchApp(tester);
        await waitFor(tester, find.text('City bike'));
        expect(find.widgetWithText(AppBar, 'Listings'), findsOneWidget);

        await tester.tap(find.byKey(const Key('logout_button')));
        await waitFor(tester, find.widgetWithText(AppBar, 'Log in'));
        expect(await SecureTokenStore().read(), isNull);
      },
    );
  });
}
