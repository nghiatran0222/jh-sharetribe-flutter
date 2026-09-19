/// Where the repositories get their data (ADR 0004).
enum SharetribeMode { mock, live }

/// Run configuration from dart-defines: `SHARETRIBE_MODE` (`mock` | `live`,
/// default `mock`) and `SHARETRIBE_CLIENT_ID` (live only, never committed).
class Env {
  const Env({required this.mode, this.clientId = ''});

  /// Reads the dart-defines passed to `flutter run` / `flutter test`.
  factory Env.fromDartDefines() => Env.parse(
    mode: const String.fromEnvironment('SHARETRIBE_MODE', defaultValue: 'mock'),
    clientId: const String.fromEnvironment('SHARETRIBE_CLIENT_ID'),
  );

  /// Throws [ArgumentError] on an unknown mode, or live mode without a
  /// client ID, so a misconfigured build fails at startup.
  factory Env.parse({required String mode, String clientId = ''}) {
    final parsed = SharetribeMode.values.where((m) => m.name == mode.trim());
    if (parsed.isEmpty) {
      throw ArgumentError.value(
        mode,
        'SHARETRIBE_MODE',
        'must be "mock" or "live"',
      );
    }
    final env = Env(mode: parsed.single, clientId: clientId.trim());
    if (env.mode == SharetribeMode.live && env.clientId.isEmpty) {
      throw ArgumentError(
        'SHARETRIBE_MODE=live needs --dart-define=SHARETRIBE_CLIENT_ID=<id>',
      );
    }
    return env;
  }

  final SharetribeMode mode;
  final String clientId;
}
