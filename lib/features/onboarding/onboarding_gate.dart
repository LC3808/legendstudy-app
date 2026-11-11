import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../personal/domain/personal_models.dart';

const onboardingRoute = '/onboarding';

/// A profile can be created by login before onboarding has even started.
/// Only explicit completion (including an allowed skip) finishes the flow.
bool onboardingProfileReady(AsyncValue<UserProfile?> profile) =>
    !profile.isLoading &&
    !profile.hasError &&
    profile.value?.hasCompletedOnboarding == true;

/// First-login routing decision. Kept pure so the gate can be unit-tested
/// without a router: given the auth/profile state and the current location,
/// return the path to redirect to, or null to stay.
///
/// Rules:
/// - Guests are never redirected (personalization is account-scoped).
/// - Auth/onboarding routes are never intercepted (recovery, owner-check, the
///   onboarding page itself).
/// - While the profile is loading or errored we wait — no redirect yet.
/// - A missing profile or completion marker starts/resumes onboarding.
/// - Completed profiles remain ready even with missing optional fields.
String? onboardingRedirect({
  required bool authed,
  required AsyncValue<UserProfile?> profile,
  required String location,
}) {
  if (!authed) return null;
  if (location == onboardingRoute || location.startsWith('/auth')) return null;
  if (profile.isLoading || profile.hasError) return null;
  if (onboardingProfileReady(profile)) return null;
  return onboardingRoute;
}
