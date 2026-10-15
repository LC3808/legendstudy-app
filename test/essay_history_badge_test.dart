import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';

void main() {
  testWidgets('registry track/session badges wrap at360 and200%', (tester) async {
    tester.view.physicalSize = const Size(360,800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(body: Padding(padding: EdgeInsets.all(20),child: EssayExamBadges(data:{'track':'인문계열','session':'오후 2'}))),
    )));
    expect(find.text('인문계열'),findsOneWidget);
    expect(find.text('오후 2'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'History identity, free lineage and readable badges at 360/$scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedEssayRecord row(String id, String? parent) => SharedEssayRecord(
          id: id,
          math: false,
          exam: true,
          rewrite: parent != null,
          at: DateTime.utc(2026, 10, 14),
          evaluations: const [],
          examData: {
            'university': '한양대학교',
            'displayExam': '2024 수시 논술 · 인문 오후 2',
            if (parent != null) 'parent_id': parent,
          },
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('owner')),
              ),
              sharedEssayHistoryProvider('owner').overrideWith(
                (ref) async => [row('free', 'first'), row('first', null)],
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const SharedEssayHistoryPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('한양대학교'), findsNWidgets(2));
        expect(find.text('최초 첨삭'), findsOneWidget);
        expect(find.text('무료 재첨삭'), findsOneWidget);
        expect(find.text('추가 유료 첨삭'), findsNothing);
        final tiles = find.byType(ListTile);
        expect(
          tester
              .getTopLeft(
                find.descendant(of: tiles.first, matching: find.text('한양대학교')),
              )
              .dy,
          lessThan(tester.getTopLeft(find.text('최초 첨삭')).dy),
        );
        final badge = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is EssayHistoryBadge && w.record.id == 'first',
            ),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect(
          (badge.decoration as BoxDecoration).color,
          AppTokens.textPrimary,
        );
        await tester.ensureVisible(find.text('무료 재첨삭'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
