import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for `integration_test/app_test.dart`. Writes each screenshot the
/// test takes to `docs/screenshots/` (ADR 0016).
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('../docs/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
