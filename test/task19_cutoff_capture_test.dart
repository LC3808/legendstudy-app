import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:legendstudy_app/features/credits/essay_beta_credit.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/exams/cutoffs/grade_cutoff.dart';
import 'package:legendstudy_app/features/exams/cutoffs/grade_cutoff_panel.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/analytics/analytics_providers.dart';
import 'package:legendstudy_app/features/analytics/analytics_guard.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';

import 'core_ux_test.dart' as preview;

import 'package:legendstudy_app/core/theme/app_theme.dart';

class _Analytics implements AnalyticsService {
  final events = <Map<String, Object?>>[];
  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    events.add({'name': name, ...?params});
  }

  @override
  void setScreen(String s) {}
  @override
  void setUserId(String? s) {}
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  test('scope excludes future CSAT, provincial mocks and lower grades', () {
    ExamMetadata e(int y, int m, String t, {int grade = 3}) => ExamMetadata(
      contentItemId: 'x',
      academicYear: y,
      examMonth: m,
      examType: t,
      gradeLevel: grade,
    );
    expect(supportsGradeCutoff(e(2027, 11, 'csat')), false);
    expect(supportsGradeCutoff(e(2027, 9, 'evaluation_mock')), true);
    expect(supportsGradeCutoff(e(2026, 11, 'csat')), true);
    expect(supportsGradeCutoff(e(2026, 6, 'national_mock')), false);
    expect(supportsGradeCutoff(e(2026, 6, 'evaluation_mock', grade: 2)), false);
    expect(supportsGradeCutoff(null), false);
  });
  testWidgets(
    'beta notice at 320x640 keeps dismiss and primary CTA reachable',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('fixture')),
            ),
            essayBetaCreditProvider.overrideWith(
              (ref) async => EssayBetaCredit.parse({
                'version': 'essay-beta-credit-v2',
                'active': true,
                'available': 1,
                'status': 'active',
                'ends_at': '2026-11-10T15:00:00Z',
                'campaign_id': 'fixture',
                'policy_version': 'daily-v2',
                'notice_seen': false,
                'expires_at': '2026-11-10T15:00:00Z',
              }),
            ),
          ],
          child: RepaintBoundary(
            key: preview.frame,
            child: MaterialApp(
              theme: AppTheme.light.copyWith(
                textTheme: AppTheme.light.textTheme.apply(
                  fontFamily: 'CorePreview',
                ),
              ),
              home: const Scaffold(
                body: EssayBetaCreditEntry(child: Text('논술 LAB')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('논술 LAB 베타 서비스 안내'), findsOneWidget);
      expect(find.text('무료 첨삭 시작하기').hitTestable(), findsOneWidget);
      await preview.capture(tester, 'task19-beta-small');
      expect(tester.takeException(), isNull);
    },
  );
  for (final source in ['materials', 'study']) {
    testWidgets(
      '$source uses real corpus in mocked API, explicit choice and one event',
      (tester) async {
        resetAnalyticsOnce();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final registry = (jsonDecode(
          File('data/grade_cutoffs/task19/registry_snapshot.json')
              .readAsStringSync(),
        ) as List).cast<Map<String, dynamic>>();
        final exam = registry.firstWhere(
          (e) =>
              e['academic_year'] == (source == 'study' ? 2026 : 2024) &&
              e['exam_month'] == (source == 'study' ? 9 : 6),
        );
        final id = exam['content_item_id'] as String;
        final rows =
            (jsonDecode(
                  File('data/grade_cutoffs/task19/reviewed_rows.json')
                      .readAsStringSync(),
                ) as List)
                .cast<Map<String, dynamic>>()
                .where((r) => r['content_item_id'] == id)
                .map(
                  (r) => GradeCutoff({
                    ...r,
                    'academic_year': exam['academic_year'],
                    'subject_label': (exam['subjects'] as List)
                        .cast<Map<String, dynamic>>()
                        .firstWhere(
                          (s) => s['id'] == r['exam_subject_id'],
                        )['label'],
                  }),
                )
                .toList();
        final analytics = _Analytics();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              analyticsServiceProvider.overrideWithValue(analytics),
              gradeCutoffsProvider(id).overrideWith((ref) async => rows),
              cutoffExamsProvider.overrideWith((ref) async => [exam]),
            ],
            child: preview.app(
              source == 'study'
                  ? const GradeCutoffBrowser()
                  : ListView(
                      children: [
                        const Text('2024학년도 6월 모의평가 · 자료'),
                        GradeCutoffPanel(contentItemId: id, source: source),
                      ],
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (source == 'study') {
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('2026학년도 9월 모의평가').last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('등급컷 확인'));
        await tester.pumpAndSettle();
        expect(analytics.events, isEmpty);
        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(rows.first.label).last);
        await tester.pumpAndSettle();
        expect(find.text(source == 'study' ? '표준점수' : '원점수'), findsOneWidget);
        expect(analytics.events.length, 1);
        expect(analytics.events.single['source'], source);
        expect(analytics.events.single['exam_code'], id);
        await preview.capture(tester, 'task19-cutoff-$source');
        await tester.tap(find.text('등급컷 확인'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('등급컷 확인'));
        await tester.pumpAndSettle();
        expect(analytics.events.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
