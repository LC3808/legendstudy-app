import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';
import 'package:legendstudy_app/features/essay/math_workspace_page.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';

void main() {
  testWidgets('Math history opens above an imperative history route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('fixture')),
          ),
          sharedEssayHistoryProvider('fixture').overrideWith(
            (ref) async => [
              SharedEssayRecord(
                id: 'attempt',
                math: true,
                rewrite: false,
                at: DateTime.utc(2026),
                evaluations: [
                  {'id': 'evaluation', 'state': 'COMPLETED'},
                ],
              ),
            ],
          ),
          mathCatalogProvider('fixture').overrideWith((ref) async => []),
          mathEvaluationAvailableProvider('fixture')
              .overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SharedEssayHistoryPage(),
                ),
              ),
              child: const Text('History'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('처리 상태 · 재첨삭 확인'));
    await tester.pumpAndSettle();
    expect(find.byType(MathWorkspacePage), findsOneWidget);
    expect(
      tester
          .widget<MathWorkspacePage>(find.byType(MathWorkspacePage))
          .evaluationId,
      'evaluation',
    );
    await tester.tap(find.byTooltip('나의 첨삭 기록'));
    await tester.pumpAndSettle();
    expect(find.byType(SharedEssayHistoryPage), findsOneWidget);
    expect(find.byType(MathWorkspacePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
