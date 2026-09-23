import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/supabase/supabase_providers.dart';
import '../personal/personal_providers.dart';
import 'data/neis_school_repository.dart';
import 'domain/school.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return NeisSchoolRepository(client, ref.watch(appConfigProvider));
});
final schoolSearchProvider = FutureProvider.autoDispose
    .family<List<School>, String>(
      (ref, query) => ref.watch(schoolRepositoryProvider).search(query),
    );

final schoolSelectionProvider = AsyncNotifierProvider<SchoolSelection, School?>(
  SchoolSelection.new,
);

class SchoolSelection extends AsyncNotifier<School?> {
  int _generation = 0;
  @override
  Future<School?> build() async {
    _generation++;
    final auth = ref.watch(authStateProvider);
    // Watching the AsyncValue clears previous-user state even while auth is loading.
    if (auth.isLoading) return null;
    if (auth.hasError) throw const SchoolServiceException();
    if (auth.value?.isAuthenticated != true) return null;
    final repository = ref.watch(schoolRepositoryProvider);
    final profile = await ref
        .watch(profileRepositoryProvider)
        .fetchCurrentProfile();
    if (profile?.neisOfficeCode == null || profile?.neisSchoolCode == null) {
      return null;
    }
    final school = await repository.find(
      profile!.neisOfficeCode!,
      profile.neisSchoolCode!,
    );
    if (school == null) throw const SchoolServiceException();
    return school;
  }

  Future<bool> select(School? school) async {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading || auth.hasError || state.isLoading) {
      throw const SchoolServiceException();
    }
    final owner = auth.value?.userId;
    final generation = _generation;
    if (owner != null) {
      await ref
          .read(profileRepositoryProvider)
          .updateSchoolSelection(
            officeCode: school?.officeCode,
            schoolCode: school?.schoolCode,
          );
    }
    if (!ref.mounted ||
        generation != _generation ||
        ref.read(authStateProvider).value?.userId != owner) {
      return false;
    }
    state = AsyncData(school);
    // Dependents invalidate through the selection change.
    return true;
  }
}

// HomeMealCard invalidates this value at the next meaningful KST boundary and
// on app resume. Keeping the clock as a plain provider makes the boundary
// timer lifecycle-owned by the widget that displays it.
final mealNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final koreanMealClockProvider = Provider<DateTime>(
  (ref) => ref.watch(mealNowProvider)(),
);
final mealBoundaryRefreshEnabledProvider = Provider<bool>((ref) => true);

// Kept as a date-only compatibility provider for existing consumers/tests.
final koreanTodayProvider = StreamProvider.autoDispose<String>(
  (ref) => Stream.value(koreanDate(ref.watch(koreanMealClockProvider))),
);

final todayMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final selection = ref.watch(schoolSelectionProvider);
  if (selection.isLoading) return [];
  if (selection.hasError) throw const SchoolServiceException();
  final school = selection.value;
  if (school == null) return [];
  final repository = ref.watch(schoolRepositoryProvider);
  final clock = ref.watch(koreanTodayProvider);
  final date = clock.value ?? await ref.watch(koreanTodayProvider.future);
  if (date == null) throw const SchoolServiceException();
  return repository.meals(school, date);
});

final tomorrowMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final selection = ref.watch(schoolSelectionProvider);
  if (selection.isLoading) return [];
  if (selection.hasError) throw const SchoolServiceException();
  final school = selection.value;
  if (school == null) return [];
  final repository = ref.watch(schoolRepositoryProvider);
  final instant = ref.watch(koreanMealClockProvider);
  return repository.meals(school, koreanDateOffset(instant, 1));
});

final nextHomeMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final school = ref.watch(schoolSelectionProvider).value;
  final now = ref.watch(koreanMealClockProvider);
  final repository = ref.watch(schoolRepositoryProvider);
  final today = await ref.watch(todayMealsProvider.future);
  final tomorrow = await ref.watch(tomorrowMealsProvider.future);
  if (school == null ||
      !mealDisplayPlan(
        now: now,
        today: today,
        tomorrow: tomorrow,
      ).primaryIsTomorrow) {
    return tomorrow;
  }
  final base = now.add(const Duration(days: 1));
  return nextAvailableHomeMeals(base, (date) {
    if (!ref.mounted) throw const SchoolServiceException();
    return date == koreanDateOffset(now, 1)
        ? Future.value(tomorrow)
        : repository.meals(school, date);
  });
}, retry: (_, _) => null);
