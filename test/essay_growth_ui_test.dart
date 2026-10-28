import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/essay_growth_page.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('growth page is a BETA surface with a clear empty state ($scale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('owner')),
            ),
            sharedEssayHistoryProvider(
              'owner',
            ).overrideWith((ref) async => <SharedEssayRecord>[]),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const EssayGrowthPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('성장 분석'), findsOneWidget);
      expect(find.byType(LabBetaBadge), findsOneWidget);
      expect(find.text('BETA'), findsOneWidget);
      expect(
        find.text('아직 완료된 첨삭 기록이 없어요. 첨삭을 받으면 성장 변화를 볼 수 있어요.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('growth page lists a completed lineage for review', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('owner')),
          ),
          sharedEssayHistoryProvider('owner').overrideWith(
            (ref) async => [
              SharedEssayRecord(
                id: 'run-1',
                math: false,
                exam: true,
                at: DateTime.utc(2026, 10, 20),
                rewrite: false,
                examData: const {
                  'university': '한양대학교',
                  'displayExam': '2026학년도 수시 논술',
                  'completed_at': '2026-10-20T01:00:00Z',
                },
                evaluations: const [
                  {'id': 'run-1/q1', 'state': 'COMPLETED'},
                ],
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: EssayGrowthPage()),
      ),
    );
    await tester.pumpAndSettle();
    // Card title is now "대학명 · 시험명"; the newest exam is expanded by default.
    expect(find.textContaining('한양대학교'), findsOneWidget);
    expect(find.text('1회차'), findsOneWidget);
    expect(find.text('회차별 결과 보기 (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('growth paginates exams 5 at a time and expands only the newest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('owner')),
          ),
          sharedEssayHistoryProvider('owner').overrideWith(
            (ref) async => [
              for (var i = 0; i < 7; i++)
                SharedEssayRecord(
                  id: 'run-$i',
                  math: false,
                  exam: true,
                  at: DateTime.utc(2026, 10, 20 - i),
                  rewrite: false,
                  examData: {
                    'university': '대학$i',
                    'displayExam': '2026 수시',
                    'completed_at': '2026-10-${20 - i}T01:00:00Z',
                  },
                  evaluations: const [
                    {'id': 'placeholder/q1', 'state': 'COMPLETED'},
                  ],
                ),
            ],
          ),
        ],
        child: const MaterialApp(home: EssayGrowthPage()),
      ),
    );
    await tester.pumpAndSettle();
    // Accordion: only the newest exam's round list is expanded.
    expect(find.textContaining('회차별 결과 보기'), findsOneWidget);
    // Pagination: the 6th/7th oldest exams are not rendered on the first page
    // of five (they load as the student scrolls).
    expect(find.textContaining('대학5'), findsNothing);
    expect(find.textContaining('대학6'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('step progress bar names the active stage and runs until done', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: StepProgressBar(
              steps: ['제출', '첨삭 중', '결과'],
              activeIndex: 1,
            ),
          ),
        ),
      ),
    );
    expect(find.text('첨삭 중'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: StepProgressBar(
              steps: ['제출', '첨삭 중', '결과'],
              activeIndex: 2,
              done: true,
            ),
          ),
        ),
      ),
    );
    // Completed: no running bar remains.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
