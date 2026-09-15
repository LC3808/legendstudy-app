import 'package:integration_test/integration_test.dart';
import '../test/search_ui_test.dart' as review;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  review.nativeCapture = (name) async {
    await binding.takeScreenshot(name);
  };
  review.main();
}
