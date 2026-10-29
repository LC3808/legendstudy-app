import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';

void main() {
  final catalog = SourceCatalog([
    {'sourceUniversityId': 'held', 'universityId': 'held-id', 'name': '준비 대학'},
    {
      'sourceUniversityId': 'ready',
      'universityId': 'ready-id',
      'name': '공개 대학',
    },
    {
      'sourceUniversityId': 'ready2',
      'universityId': 'ready2-id',
      'name': '공개 대학 2',
    },
  ], []);
  test('ready first, existing order within each state, independent of registered exams', () {
    expect(
      orderedServiceUniversities(catalog, {
        'ready-id',
        'ready2-id',
      }).map((u) => u['sourceUniversityId']),
      ['ready', 'ready2', 'held'],
    );
  });
  testWidgets(
    'loading and error are not preparing; retry uses same backend provider',
    (tester) async {
      final pending = Completer<Set<String>>();
      int calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('owner')),
            ),
            publicServiceUniversitiesProvider.overrideWith((ref, owner) {
              calls++;
              return calls == 1
                  ? pending.future
                  : Future.value({'ready-id', 'ready2-id'});
            }),
          ],
          child: MaterialApp(
            home: SourceCatalogPage(catalog: Future.value(catalog)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('서비스 확인 중'), findsOneWidget);
      expect(find.text('첨삭 서비스 준비 중'), findsNothing);
      pending.completeError(StateError('network'));
      await tester.pumpAndSettle();
      expect(find.text('일시적으로 확인할 수 없습니다 · 다시 시도'), findsOneWidget);
      await tester.tap(find.text('일시적으로 확인할 수 없습니다 · 다시 시도').first);
      await tester.pumpAndSettle();
      expect(find.text('첨삭 시작하기 →'), findsNothing);
      expect(find.text('첨삭 서비스 준비 중'), findsNothing);
      expect(
        tester.getTopLeft(find.text('공개 대학')).dy,
        lessThan(tester.getTopLeft(find.text('준비 대학')).dy),
      );
      final heldCard = find.ancestor(
        of: find.text('준비 대학'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(heldCard).onTap, isNull);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
