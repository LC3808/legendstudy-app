// Test-only synthetic scoring, real native clock and atomic file. No production I/O.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_pages.dart';
import '../test/mock_scoring_test.dart' show FakeScoring, availability;
import '../test/study_core_test.dart' show TestRepo;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('scoring guest native persistence smoke', (t) async {
    final store = NativeStudyLocalStore();
    final original = await store.read();
    StudyController? c;
    void mark(String name) => debugPrint('SCORING_FLUTTER PASS $name');
    Future<void> wait(bool Function() ready) async {
      for (var i = 0; i < 200; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (ready()) return;
      }
      throw StateError('Scoring smoke timeout');
    }

    Future<void> mount() async {
      await t.pumpWidget(const SizedBox.shrink());
      c?.dispose();
      c = StudyController(
        NativeStudyClock(),
        store,
        () => TestRepo('unused'),
        scoringRepository: () => FakeScoring(null),
      );
      c!.identity(null, resolved: true);
      await wait(() => c!.ready);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AnswerEntryPage(study: c!),
        ),
      );
      await t.pumpAndSettle();
    }

    try {
      if (const bool.fromEnvironment('SCORING_LIVE_EMPTY_SMOKE')) {
        final transport = http.Client();
        try {
          final papers = await SupabaseScoringRepository(
            AppConfig.fromEnvironment(),
            transport,
          ).availablePapers();
          expect(papers.isEmpty, true);
          mark('production_availability_empty');
        } finally {
          transport.close();
        }
      }
      // Isolate guest namespace; preserve the whole original file in memory/finally.
      await store.write({'version': 3, 'owners': <String, dynamic>{}});
      await mount();
      await c!.configureScoring(availability());
      c!.configureMock(const MockSetup('Synthetic scoring smoke', null, 60));
      await c!.startMock();
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('answer-1-1')));
      await t.pumpAndSettle();
      expect(c!.draft!.answers!.answered, 1);
      mark('guest_answer');
      await c!.pause();
      await t.pumpAndSettle();
      await c!.selectAnswer(2, 1);
      expect(c!.draft!.answers!.answered, 1);
      await mount();
      expect(c!.draft!.answers!.answers, [1, null, null]);
      mark('guest_draft_restore');
      await c!.resume();
      await t.pumpAndSettle();
      mark('guest_pause_resume');
      await Future<void>.delayed(const Duration(seconds: 2));
      await t.tap(find.text('제출하고 채점하기'));
      await t.pumpAndSettle();
      await t.tap(find.text('제출하고 채점하기').last);
      await wait(
        () => c!.attempts.isNotEmpty && c!.attempts.last.result != null,
      );
      await t.pumpAndSettle();
      expect(find.text('2 / 6점'), findsOneWidget);
      mark('guest_submit_raw_score');
      final id = c!.attempts.last.id;
      await mount();
      expect(c!.attempts.last.id, id);
      expect(c!.attempts.last.result!.rawScore, 2);
      mark('guest_result_restore');
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      c?.dispose();
      await store.write(original);
      expect(jsonEncode(await store.read()), jsonEncode(original));
      mark('local_fixture_cleanup');
    }
  });
}
