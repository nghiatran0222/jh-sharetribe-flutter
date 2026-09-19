import 'package:flutter_test/flutter_test.dart';
import 'package:sharetribe_flutter/core/env.dart';

void main() {
  group('given no dart-defines', () {
    test('when Env is read, then mode is mock', () {
      expect(Env.fromDartDefines().mode, SharetribeMode.mock);
    });
  });

  group('given SHARETRIBE_MODE=live', () {
    test('when a client ID is set, then Env is live with that ID', () {
      final env = Env.parse(mode: 'live', clientId: 'abc');

      expect(env.mode, SharetribeMode.live);
      expect(env.clientId, 'abc');
    });

    test('when the client ID is missing, then parse throws', () {
      expect(() => Env.parse(mode: 'live'), throwsArgumentError);
    });
  });

  group('given an unknown SHARETRIBE_MODE', () {
    test('when parsed, then it throws', () {
      expect(() => Env.parse(mode: 'staging'), throwsArgumentError);
    });
  });
}
