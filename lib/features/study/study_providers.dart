import 'dart:async';
import 'focus/focus_service.dart';
import 'focus/study_focus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/supabase/supabase_providers.dart';
import 'data/study_local.dart';
import 'data/study_repository.dart';
import 'application/study_controller.dart';

final focusServiceProvider = Provider<FocusService>(
  (ref) => NativeFocusService(),
);
final studyFocusProvider = Provider<StudyFocusController>((ref) {
  final focus = StudyFocusController(ref.watch(focusServiceProvider));
  ref.onDispose(focus.dispose);
  return focus;
});
final studyClockProvider = Provider<StudyClock>((ref) => NativeStudyClock());
final studyLocalStoreProvider = Provider<StudyLocalStore>(
  (ref) => NativeStudyLocalStore(),
);
final studyHttpProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
final studyRepositoryFactoryProvider = Provider<StudyRepository Function()>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider),
      config = ref.watch(appConfigProvider),
      transport = ref.watch(studyHttpProvider);
  return () => SupabaseStudyRepository.bind(client, config, transport);
});
final studyRefreshProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(seconds: 30), (n) => n),
);
final studyControllerProvider =
    ChangeNotifierProvider.autoDispose<StudyController>((ref) {
      final controller = StudyController(
        ref.watch(studyClockProvider),
        ref.watch(studyLocalStoreProvider),
        ref.watch(studyRepositoryFactoryProvider),
      );
      final focus = ref.watch(studyFocusProvider);
      void observeFocus() => focus.observe(
        session: controller.recovery ? null : controller.draft?.id,
        ready: controller.ready,
      );
      controller.addListener(observeFocus);
      ref.listen(studyRefreshProvider, (_, next) {
        if (next.hasValue) unawaited(controller.tick());
      });
      ref.listen(
        authStateProvider,
        (_, next) => controller.identity(
          next.value?.userId,
          resolved: !next.isLoading && !next.hasError,
        ),
        fireImmediately: true,
      );
      return controller;
    });
