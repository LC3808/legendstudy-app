import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legendstudy_app/features/onboarding/onboarding_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'fresh store restores step and isolates accounts; clear preserves others',
    () async {
      final first = OnboardingProgressStore();
      expect(await first.load('a'), 1);
      await first.save('a', 7);
      await first.save('b', 3);
      final restarted = OnboardingProgressStore();
      expect(await restarted.load('a'), 7);
      expect(await restarted.load('b'), 3);
      await restarted.clear('a');
      expect(await first.load('a'), 1);
      expect(await first.load('b'), 3);
    },
  );
}
