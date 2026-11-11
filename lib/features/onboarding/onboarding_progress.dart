import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Install-local navigation only. No answers, credentials or completion marker.
/// Server profile completion remains authoritative across devices.
class OnboardingProgressStore {
  String _key(String owner) => 'onboarding-step-v1:$owner';

  Future<int> load(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(owner)) ?? 1;
  }

  Future<void> save(String owner, int step) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(_key(owner), step)) {
      throw StateError('Onboarding progress was not saved');
    }
  }

  Future<void> clear(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(owner));
  }
}

final onboardingProgressStoreProvider = Provider(
  (ref) => OnboardingProgressStore(),
);
