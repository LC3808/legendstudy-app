import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
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
            ? '등급 정보 준비 중'
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
      expect(old.gradeLabel, '등급 정보 준비 중');
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
  testWidgets(
    'result navigation returns to Study or Home without resubmission',
    (t) async {
      final choices = List<int?>.filled(100, 1);
      final attempt = ScoringAttempt(
        id: 'done',
        title: '시험',
        draft: gradeDraft('confirmed', choices),
        result: gradeResult('confirmed', choices),
        outcome: ScoringOutcome.complete,
      );
      final router = GoRouter(
        initialLocation: '/study',
        routes: [
          GoRoute(
            path: '/study',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: SingleChildScrollView(
                            child: ScoringResultView(
                              attempt: attempt,
                              guest: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                child: const Text('결과 열기'),
              ),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('홈 도착')),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await t.tap(find.text('결과 열기'));
      await t.pumpAndSettle();
      expect(find.text('제출하고 채점하기'), findsNothing);
      await t.tap(find.text('다시 학습으로'));
      await t.pumpAndSettle();
      expect(find.text('결과 열기'), findsOneWidget);
      await t.tap(find.text('결과 열기'));
      await t.pumpAndSettle();
      await t.tap(find.text('홈으로'));
      await t.pumpAndSettle();
      expect(find.text('홈 도착'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      '100 answers, semantics, source, jumps at 360x640 scale $scale',
      (t) async {
        t.view.physicalSize = const Size(360, 640);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final sem = t.ensureSemantics();
        final choices = List<int?>.generate(
          100,
          (i) => i == 0
              ? 1
              : i == 6
              ? 3
              : null,
        );
        final base = gradeResult('estimated', choices);
        final result = base.withSources(
          ScoringSource.fromJson({
            ...sourceJson(),
            'source_name': '아주 긴 출처 이름 ' * 10,
          }),
          base.cutoffSource,
        );
        Uri? opened;
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              externalOpenerProvider.overrideWithValue((uri) async {
                opened = uri;
                return true;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ScoringResultView(
                    attempt: ScoringAttempt(
                      id: 'test',
                      title: '아주 긴 모의고사 시험 제목 ' * 10,
                      draft: gradeDraft('estimated', choices),
                      result: result,
                      outcome: ScoringOutcome.complete,
                    ),
                    guest: true,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull);
        await t.ensureVisible(find.text('예상 9등급'));
        expect(find.bySemanticsLabel('예상 9등급, 예상 등급컷 기준'), findsOneWidget);
        final source = find.text('정답·등급 기준 출처');
        await t.ensureVisible(source);
        await t.tap(source);
        await t.pumpAndSettle();
        expect(find.text('확인: 2026.09.14'), findsNWidgets(2));
        await t.ensureVisible(find.text('정답 기준 원문 보기'));
        await t.tap(find.text('정답 기준 원문 보기'));
        await t.pumpAndSettle();
        expect(opened, Uri.parse('https://example.com/source/1'));
        await t.tap(find.text('닫기'));
        await t.pumpAndSettle();
        final jump = find.byKey(const ValueKey('review-jump-100'));
        await t.ensureVisible(jump);
        expect(t.getSize(jump).width, greaterThanOrEqualTo(48));
        expect(t.getSize(jump).height, greaterThanOrEqualTo(48));
        await t.tap(jump);
        await t.pumpAndSettle();
        expect(
          find.bySemanticsLabel('100번, 내 답 미응답, 정답 1번, 미응답, 1점'),
          findsOneWidget,
        );
        await t.ensureVisible(find.text('7번 · 오답'));
        expect(
          find.bySemanticsLabel('7번, 내 답 3번, 정답 1번, 오답, 1점'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
        sem.dispose();
      },
    );
  }
}
