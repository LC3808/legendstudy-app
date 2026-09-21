import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import '../test/account_ux_render_test.dart' as account;
import '../test/auth_lifecycle_ui_test.dart' as lifecycle;

// Local fixtures only. No provider login, real account or Production mutation.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> capture(String name) async {
    await binding.takeScreenshot(name);
    if (const bool.fromEnvironment('AUTH_SYSTEM_CAPTURE')) {
      debugPrint('AUTH_CAPTURE_READY $name');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  account.nativeCapture = capture;
  lifecycle.nativeCapture = capture;
  account.main();
  lifecycle.main();
}
