import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_mobile/academic_purple.dart';
import 'package:legendstudy_app/features/essay/math_mobile/coaching_contract.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_mobile_preview.dart';

void main() {
  testWidgets(
    'already-open History updates after hint and explicit disclosure',
    (tester) async {
      Future<void> show(Finder target) async {
        final scroll = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        for (var i = 0; target.evaluate().isEmpty && i < 30; i++) {
          await tester.drag(scroll, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
      }

      final data = mathMobilePreviewSnapshot();
      data['tasks'] = [(data['tasks'] as List).first];
      final hints = <int>[];
      var disclosed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MathCoachingScreen(
            snapshot: CoachingSnapshot(data),
            onRewrite: (_) async {},
            request: (action, payload) async {
              if (action == 'history') {
                return {
                  'attempts': [
                    {
                      'resolve_kind': 'INITIAL',
                      'solution_revealed': disclosed,
                      'exposed_hint_levels': List.of(hints),
                    },
                  ],
                };
              }
              if (action == 'hint') {
                hints.add(payload['level'] as int);
                return {'body': '조건을 다시 확인하세요.'};
              }
              if (action == 'reveal') {
                disclosed = true;
                return {
                  ...data,
                  'disclosed': true,
                  'full_solution': <String, dynamic>{},
                };
              }
              throw StateError('unexpected action');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('학습 기록'));
      await tester.pumpAndSettle();
      Finder hintUsage(String value) => find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is MathContentSection && w.label == '힌트 사용',
        ),
        matching: find.text(value),
      );
      expect(hintUsage('[]'), findsOneWidget);
      await tester.tap(find.text('첨삭 결과'));
      await tester.pumpAndSettle();
      final task = find.text('합성함수 미분의 적용 조건');
      await show(task);
      await tester.tap(task);
      await tester.pumpAndSettle();
      final hint = find.text('개념 힌트 보기');
      await show(hint);
      await tester.tap(hint);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('학습 기록'));
      await tester.pumpAndSettle();
      expect(hintUsage('[1]'), findsOneWidget);
      await tester.tap(find.text('첨삭 결과'));
      await tester.pumpAndSettle();
      final reveal = find.text('전체 풀이 및 해설 보기');
      await show(reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      await tester.tap(find.text('정답·해설 공개'));
      await tester.pumpAndSettle();
      expect(find.byType(MathSolutionPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('학습 기록'));
      await tester.pumpAndSettle();
      expect(find.text('전체 해설 공개됨'), findsOneWidget);
    },
  );
}
