import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import '../test/materials_delivery_journey_test.dart' as journey;

// All repositories and the external opener are test doubles. No Production IO.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  journey.nativeCapture = (name) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
    if (const bool.fromEnvironment('DELIVERY_SYSTEM_CAPTURE')) {
      debugPrint('DELIVERY_CAPTURE_READY $name');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  };
  journey.main();
}
