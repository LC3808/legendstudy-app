import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth_lifecycle_ui_test.dart' as journey;

// All accounts/repositories are local doubles. No Production IO or real login.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  journey.nativeCapture = (name) async {
    await binding.takeScreenshot(name);
    if (const bool.fromEnvironment('AUTH_SYSTEM_CAPTURE')) {
      debugPrint('AUTH_CAPTURE_READY $name');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  };
  journey.main();
}
