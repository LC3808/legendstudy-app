import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import '../test/inline_bookmark_journey_test.dart' as journey;

// All accounts/repositories are local doubles. No Production IO or real login.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  journey.nativeCapture = (name) async {
    await binding.takeScreenshot(name);
    if (const bool.fromEnvironment('INLINE_SYSTEM_CAPTURE')) {
      debugPrint('INLINE_CAPTURE_READY $name');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  };
  journey.main();
}
