import 'package:integration_test/integration_test.dart';
import '../test/study_home_polish_test.dart' as polish;

// Only fake repositories and memory stores: never initializes Supabase or app storage.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  polish.nativeCapture = (name) async {
    await binding.takeScreenshot(name);
  };
  polish.main();
}
