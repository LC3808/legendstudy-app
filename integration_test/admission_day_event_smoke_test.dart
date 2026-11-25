import 'package:integration_test/integration_test.dart';
import '../test/admission_day_event_test.dart' as admission;

// Only fake repositories/MockClient; never contacts production or real accounts.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  admission.main();
}
