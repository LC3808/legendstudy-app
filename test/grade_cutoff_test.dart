import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/exams/cutoffs/grade_cutoff.dart';
import 'package:legendstudy_app/features/exams/cutoffs/grade_cutoff_panel.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_events.dart';

Map<String, dynamic> row({
  int? raw,
  int? standard,
  int? low,
  int? high,
  String elective = '',
}) => {
  'content_item_id': 'exam',
  'exam_subject_id': 'subject',
  'subject_label': '국어',
  'elective_key': elective,
  'elective_label': elective,
  'academic_year': 2024,
  'grade': 1,
  'raw_score': raw,
  'raw_score_min': low,
  'raw_score_max': high,
  'standard_score': standard,
  'raw_certainty': 'estimated',
  'standard_certainty': 'confirmed',
  'source_url': 'https://legendstudy.com/1516',
  'source_name': '레전드스터디 원본',
};
void main() {
  test(
    'raw first, preserve range, standard fallback, no invented missing score',
    () {
      final a = GradeCutoff(row(raw: 97, standard: 129));
      expect(a.score, '97');
      expect(a.scoreType, '원점수');
      expect(a.certainty, '추정');
      final b = GradeCutoff(row(low: 92, high: 93, standard: 129));
      expect(b.score, '92~93');
      final c = GradeCutoff(row(standard: 129));
      expect(c.scoreType, '표준점수');
      expect(c.certainty, '확정');
      expect(GradeCutoff(row()).score, '—');
      expect(c.estimatedRaw, '—');
      expect(
        GradeCutoff({...row(standard: 130), 'estimated_raw_score': 94})
            .estimatedRaw,
        '—',
      );
      expect(
        GradeCutoff({
          ...row(standard: 130),
          'estimated_raw_score_min': 93,
          'estimated_raw_score_max': 94,
          'estimated_raw_source_url': 'https://example.org/cutoff',
        }).estimatedRaw,
        '93~94',
      );
      expect(() => GradeCutoff(row(low: 93, high: 92)), throwsFormatException);
      expect(() => GradeCutoff(row(low: 93)), throwsFormatException);
      expect(() => GradeCutoff(row(raw: 101)), throwsFormatException);
    },
  );
  test('analytics keeps public exam context, never answer or identity', () {
    final p = sanitizeAnalyticsParams({
      'academic_year': 2024,
      'subject_code': 'korean',
      'exam_code': 'exam',
      'answer': 'private',
      'email': 'private',
    });
    expect(p, {
      'academic_year': 2024,
      'subject_code': 'korean',
      'exam_code': 'exam',
    });
  });
  testWidgets(
    'explicit elective choice and horizontally scrollable raw/standard table',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradeCutoffsProvider('exam').overrideWith(
              (ref) async => [
                GradeCutoff(
                  row(low: 92, high: 93, standard: 129, elective: '언어와 매체'),
                ),
                GradeCutoff(row(raw: 97, standard: 129, elective: '화법과 작문')),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GradeCutoffPanel(
                  contentItemId: 'exam',
                  source: 'materials',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('등급컷 확인'));
      await tester.pumpAndSettle();
      expect(find.text('92~93'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('국어 · 언어와 매체').last);
      await tester.pumpAndSettle();
      expect(find.text('92~93'), findsOneWidget);
      expect(find.text('표준점수 (보조 정보)'), findsNothing);
      expect(find.text('자료 상태'), findsNothing);
      expect(find.text('추정'), findsNothing);
      expect(find.text('표준점수'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing API leaves a recoverable cutoff error without blocking detail',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradeCutoffsProvider('exam')
                .overrideWith((ref) => throw Exception('not deployed')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GradeCutoffPanel(contentItemId: 'exam', source: 'study'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('등급컷 확인'));
      await tester.pumpAndSettle();
      expect(find.text('다시 시도'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
