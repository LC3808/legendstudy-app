import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'domain/day_target.dart';
import 'domain/day_target_repository.dart';
import 'data/supabase_day_target_repository.dart';

final dayTargetRepositoryProvider = Provider<DayTargetRepository>(
  (ref) => SupabaseDayTargetRepository(ref.watch(supabaseClientProvider)),
);
final dayTargetProvider =
    AsyncNotifierProvider<DayTargetController, DayTarget?>(
      DayTargetController.new,
    );

class DayTargetController extends AsyncNotifier<DayTarget?> {
  int _generation = 0;
  bool _saving = false;
  @override
  Future<DayTarget?> build() async {
    _generation++;
    _saving = false;
    final identity = ref.watch(
      authStateProvider.select(
        (auth) => (auth.isLoading, auth.hasError, auth.value?.userId),
      ),
    );
    if (identity.$1) return null;
    if (identity.$2) {
      throw const BackendUnavailable('Authentication unavailable');
    }
    if (identity.$3 == null) return null;
    return ref.watch(dayTargetRepositoryProvider).fetchCurrentTarget();
  }

  Future<bool> setTarget(DayTarget? target) async {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading ||
        auth.hasError ||
        state.isLoading ||
        state.hasError ||
        _saving) {
      throw const BackendUnavailable('Target not ready');
    }
    final owner = auth.value?.userId;
    final generation = _generation;
    _saving = true;
    try {
      DayTarget? confirmed = target;
      if (owner != null) {
        final repository = ref.read(dayTargetRepositoryProvider);
        if (target == null) {
          await repository.clearCurrentTarget();
        } else {
          confirmed = await repository.saveCurrentTarget(
            target.date,
            target.label,
          );
        }
      }
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(authStateProvider).value?.userId != owner) {
        return false;
      }
      state = AsyncData(confirmed);
      return true;
    } finally {
      if (ref.mounted && generation == _generation) _saving = false;
    }
  }
}

final dayTargetClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});
