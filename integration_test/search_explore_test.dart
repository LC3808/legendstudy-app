import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import '../test/search_ui_test.dart' as review;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  review.nativeCapture = (name) async {
    // Allow the native compositor to present the frame pumped by the test.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
    if (const bool.fromEnvironment('SEARCH_SYSTEM_CAPTURE')) {
      debugPrint('SEARCH_CAPTURE_READY $name');
      // Optional host simctl capture includes the OS keyboard/status bar.
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  };
  review.main();
}
