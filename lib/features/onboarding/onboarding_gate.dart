import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../personal/domain/personal_models.dart';

const onboardingRoute = '/onboarding';

/// First-login routing decision. Kept pure so the gate can be unit-tested
/// without a router: given the auth/profile state and the current location,
/// return the path to redirect to, or null to stay.
///
/// Rules:
/// - Guests are never redirected (personalization is account-scoped).
/// - Auth/onboarding routes are never intercepted (recovery, owner-check, the
///   onboarding page itself).
/// - While the profile is loading or errored we wait — no redirect yet.
/// - An authenticated user with no profile row, or one whose
///   `onboarding_completed_at` is null, is sent to onboarding.
String? onboardingRedirect({
  required bool authed,
  required AsyncValue<UserProfile?> profile,
  required String location,
}) {
  if (!authed) return null;
  if (location == onboardingRoute || location.startsWith('/auth')) return null;
  if (profile.isLoading || profile.hasError) return null;
  final value = profile.value;
  if (value != null && value.hasCompletedOnboarding) return null;
  return onboardingRoute;
}
