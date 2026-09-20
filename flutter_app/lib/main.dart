import 'package:flutter/material.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'core/env.dart';

void main() {
  final env = Env.fromDartDefines();
  runApp(App(dependencies: AppDependencies.fromEnv(env)));
}
