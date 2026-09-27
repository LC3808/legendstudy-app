import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';

/// Treat the signed-in user under test as an already-onboarded returning user,
/// so the first-login onboarding gate (router redirect) does not intercept
/// tests that mount the app and assert on Home/MY/materials surfaces. Guests
/// stay null. Tests that specifically exercise onboarding set their own state.
final onboardedProfileOverride = currentProfileProvider.overrideWith((ref) async {
  final id = ref.watch(authStateProvider).value?.userId;
  return id == null
      ? null
      : UserProfile(id: id, onboardingCompletedAt: DateTime(2026));
});
