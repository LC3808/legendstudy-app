// Native storage/clock and production Guest mapper with synthetic HTTP only.
// No credentials, production requests or database fixture operations.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_pages.dart';
import '../test/support/grade_fixture.dart';
import '../test/study_core_test.dart' show TestRepo;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('D3 Guest grade/result native restoration', (t) async {
    final store = NativeStudyLocalStore(),
        original = await NativeStudyLocalStore().read();
    StudyController? c;
    Future<void> wait(bool Function() ready) async {
      for (var i = 0; i < 200; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (ready()) return;
      }
      throw StateError('D3 native smoke timeout');
    }

    Future<void> mount(GradeFixture fixture) async {
      await t.pumpWidget(const SizedBox.shrink());
      c?.dispose();
      c = StudyController(
        NativeStudyClock(),
        store,
        () => TestRepo('unused'),
        scoringRepository: () => fixture.repository,
      );
      c!.identity(null, resolved: true);
      await wait(() => c!.ready);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: AnswerEntryPage(study: c!),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    try {
      await store.write({'version': 3, 'owners': <String, dynamic>{}});
      for (final status in ['confirmed', 'estimated', 'unavailable']) {
        final fixture = GradeFixture(status);
        try {
          await mount(fixture);
          await c!.configureScoring(gradeAvailability(status));
          c!.configureMock(const MockSetup('D3 결과 검증 모의고사', '영어', 60));
          await c!.startMock();
          await c!.selectAnswer(1, 1);
          await c!.selectAnswer(7, 3);
          await c!.end();
          await wait(
            () => c!.attempts.isNotEmpty && c!.attempts.last.result != null,
          );
          await t.pumpAndSettle();
          final a = c!.attempts.last, result = a.result!;
          expect(find.text(result.gradeLabel), findsOneWidget);
          expect(result.gradeStatus, status);
          expect(result.rawScore, 1);
          debugPrint('D3_GUEST PASS $status');
          final link = find.text('정답·등급 기준 출처');
          await t.ensureVisible(link);
          await t.tap(link);
          await t.pumpAndSettle();
          expect(find.text('정답 기준: 검증된 정답 출처'), findsOneWidget);
          await t.tap(find.text('닫기'));
          await t.pumpAndSettle();
          final jump = find.byKey(const ValueKey('review-jump-7'));
          await t.ensureVisible(jump);
          await t.tap(jump);
          await t.pumpAndSettle();
          expect(find.text('7번 · 오답'), findsOneWidget);
          debugPrint('D3_GUEST PASS ${status}_review_source');
          final snapshot = jsonEncode(a.toJson());
          fixture.version = 2;
          final requestCount = fixture.requests.length;
          await mount(fixture);
          expect(jsonEncode(c!.attempts.last.toJson()), snapshot);
          expect(fixture.requests.length, requestCount);
          expect(find.text(result.gradeLabel), findsOneWidget);
          debugPrint('D3_GUEST PASS ${status}_historical_restore');
        } finally {
          fixture.transport.close();
        }
      }
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      c?.dispose();
      await store.write(original);
      expect(jsonEncode(await store.read()), jsonEncode(original));
      debugPrint('D3_GUEST PASS local_fixture_cleanup');
    }
  });
}
