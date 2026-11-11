import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_result_view.dart';

import 'support/grade_fixture.dart';

void main() {
  for (final scenario in [
    ('confirmed', 100, 1),
    ('confirmed', 0, 9),
    ('confirmed', 90, 1),
    ('confirmed', 89, 2),
    ('estimated', 82, 2),
    ('unavailable', 82, null),
  ]) {
    test('grade status/boundary ${scenario.$1} ${scenario.$2}', () {
      final result = gradeResult(
        scenario.$1,
        List.generate(100, (i) => i < scenario.$2 ? 1 : null),
      );
      expect(result.grade, scenario.$3);
      expect(
        result.gradeLabel,
        scenario.$1 == 'unavailable'
            ? '등급 산출 불가'
            : '${scenario.$1 == 'estimated' ? '예상 ' : ''}${scenario.$3}등급',
      );
      final restored = ScoreResult.fromJson(
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), result.toJson());
      expect(restored.gradeLabel, result.gradeLabel);
    });
  }
  test(
    'malformed grades/basis rejected; legacy cache never invents provenance',
    () {
      final j = gradeResult('confirmed', List.filled(100, 1)).toJson();
      for (final patch in [
        {'grade': null},
        {'grade': 0},
        {'grade': 10},
        {'grade_status': 'unavailable'},
        {'cutoff_source': sourceJson('estimated')},
      ]) {
        expect(
          () => ScoreResult.fromJson({...j, ...patch}),
          throwsFormatException,
        );
      }
      expect(
        () => ScoringSource.fromJson({
          ...sourceJson('confirmed'),
          'basis': 'raw_estimate',
        }),
        throwsFormatException,
      );
      for (final url in [
        'javascript:alert(1)',
        'https://a:b@example.com',
        'https://example.com/\n',
      ]) {
        expect(
          () => ScoringSource.fromJson({...sourceJson(), 'source_url': url}),
          throwsFormatException,
        );
      }
      j.remove('key_source');
      j.remove('cutoff_source');
      final old = ScoreResult.fromJson(j);
      expect(old.grade, 1);
      expect(old.gradeLabel, '등급 산출 불가');
      expect(old.keySource, isNull);
    },
  );
  test('all wrong / blank / mixed retain distinct review and counts', () {
    for (final choices in [
      List<int?>.filled(100, 2),
      List<int?>.filled(100, null),
      List<int?>.generate(
        100,
        (i) => i < 82
            ? 1
            : i < 89
            ? 2
            : null,
      ),
    ]) {
      final s = gradeResult('estimated', choices);
      expect(s.correctCount, choices.where((v) => v == 1).length);
      expect(s.wrong.length, choices.where((v) => v == 2).length);
      expect(s.unanswered.length, choices.where((v) => v == null).length);
      expect(s.correctCount + s.wrong.length + s.unanswered.length, 100);
    }
  });
  for (final status in ['confirmed', 'estimated', 'unavailable']) {
    test(
      'Guest/Auth presentation parity and historical readback $status',
      () async {
        final guest = GradeFixture(status),
            auth = GradeFixture(status, owner: 'A');
        addTearDown(guest.transport.close);
        addTearDown(auth.transport.close);
        final a = ScoringAttempt(
          id: 'attempt',
          title: '시험',
          draft: gradeDraft(status, List.generate(100, (i) => i < 82 ? 1 : 2)),
        );
        final g = await guest.repository.submit(a),
            s = await auth.repository.submit(a);
        expect(g.gradeLabel, s.gradeLabel);
        expect(g.keySource!.toJson(), s.keySource!.toJson());
        expect(g.cutoffSource?.toJson(), s.cutoffSource?.toJson());
        final before = jsonEncode(s.toJson());
        auth.version = 2;
        final retry = await auth.repository.submit(a);
        expect(jsonEncode(retry.toJson()), before);
        expect(auth.requests.every((r) => r.method == 'POST'), true);
        expect(guest.requests.every((r) => r.method == 'GET'), true);
        auth.malformed = true;
        await expectLater(auth.repository.submit(a), throwsFormatException);
      },
    );
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'separate answer page, question jump and account guard at scale $scale',
      (t) async {
        t.view.physicalSize = const Size(360, 640);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final sem = t.ensureSemantics();

        final session = ValueNotifier(true);
        addTearDown(session.dispose);
        final choices = List<int?>.generate(
          100,
          (i) => i == 6
              ? 3
              : i == 99
              ? null
              : 1,
        );
        final result = gradeResult('unavailable', choices);
        final before = jsonEncode(result.toJson());
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ScoringResultView(
                  attempt: ScoringAttempt(
                    id: 'done',
                    title: '[2024년 11월 시행] 2025학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/수학',
                    draft: gradeDraft('unavailable', choices),
                    result: result,
                    outcome: ScoringOutcome.complete,
                  ),
                  guest: false,
                  sessionChanges: session,
                  canReadResult: () => session.value,
                ),
              ),
            ),
          ),
        );
        expect(find.text('2025학년도 수능 기출'), findsOneWidget);
        expect(find.text('등급 산출 불가'), findsNothing);
        expect(find.text('서버에서 채점한 결과'), findsNothing);
        expect(find.text('정답·등급 기준 출처'), findsNothing);
        expect(find.text('다시 학습으로'), findsNothing);
        expect(find.text('홈으로'), findsNothing);
        expect(find.text('7번 · 오답'), findsNothing);
        final button = find.widgetWithText(FilledButton, '답안 확인');
        await t.ensureVisible(button);
        await t.tap(button);
        await t.pumpAndSettle();
        expect(find.byType(ScoringAnswersPage), findsOneWidget);
        expect(find.text('98 / 100점'), findsNothing);
        expect(find.text('1번 · 정답'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pageBack();
        await t.pumpAndSettle();
        final jump = find.byKey(const ValueKey('review-jump-100'));
        await t.ensureVisible(jump);
        expect(t.getSize(jump).height, greaterThanOrEqualTo(48));
        expect(find.text('100번'), findsOneWidget);
        await t.tap(jump);
        await t.pumpAndSettle();
        expect(find.text('100번 · 미응답').hitTestable(), findsOneWidget);
        expect(
          find.bySemanticsLabel('100번, 내 답 미응답, 정답 ①, 미응답, 배점 1점'),
          findsOneWidget,
        );
        await t.ensureVisible(find.text('7번 · 오답'));
        expect(
          t.widget<Text>(find.text('7번 · 오답')).style!.color,
          AppTokens.dangerInk,
        );
        expect(
          t.widget<Text>(find.text('1번 · 정답')).style!.color,
          AppTokens.info,
        );
        expect(t.takeException(), isNull);
        session.value = false;
        await t.pumpAndSettle();
        expect(find.text('7번 · 오답'), findsNothing);
        expect(find.text('이 계정의 결과를 확인할 수 없어요.'), findsOneWidget);
        expect(jsonEncode(result.toJson()), before);
        sem.dispose();
      },
    );
  }
}
