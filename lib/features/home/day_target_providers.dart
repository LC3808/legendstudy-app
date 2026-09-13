import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'domain/day_target.dart';

/// Temporary selection only. No preferences file or profile writes before DB approval.
final dayTargetProvider = NotifierProvider<DayTargetController, DayTarget?>(
  DayTargetController.new,
);

class DayTargetController extends Notifier<DayTarget?> {
  @override
  DayTarget? build() {
    ref.watch(
      authStateProvider.select(
        (auth) => (auth.isLoading, auth.hasError, auth.value?.userId),
      ),
    );
    return null;
  }

  void setTarget(DayTarget? target) {
    state = target;
  }
}

final dayTargetClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});
