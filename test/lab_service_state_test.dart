import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/lab/lab_coming_soon_page.dart';
import 'package:legendstudy_app/features/lab/lab_page.dart';
import 'package:legendstudy_app/shared/widgets/legendstudy_lab_entry.dart';

Widget _host(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  group('LabComingSoonPage (준비 중)', () {
    testWidgets('shows 준비 중 state, disabled CTA, and future-value copy at 360px',
        (t) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        _host(
          const LabComingSoonPage(
            title: '내신분석 LAB',
            lead: '내신 성적을 입력하면 과목별 강점과 보완이 필요한 영역을 분석하고, 관심 대학을 기준으로 성적을 살펴볼 수 있어요.',
            note: '더 정교한 내신 분석 서비스를 준비하고 있습니다.',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('서비스 준비 중'), findsOneWidget);
      expect(find.text('내신분석 LAB'), findsOneWidget);
      // CTA present but disabled.
      final cta = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, '준비 중'),
      );
      expect(cta.onPressed, isNull);
      expect(t.takeException(), isNull);
    });

    testWidgets('copy makes no 합격/예측/확률 claim', (t) async {
      await t.pumpWidget(
        _host(
          const LabComingSoonPage(
            title: '수능·모의고사 LAB',
            lead: '모의고사·수능 성적을 입력하면 영역별 강점과 보완이 필요한 부분을 분석하고, 관심 대학을 기준으로 성적을 살펴볼 수 있어요.',
            note: '성적 변화까지 한눈에 확인할 수 있도록 준비하고 있습니다.',
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final banned in ['합격', '예측', '확률', '입결', '환산']) {
        expect(find.textContaining(banned), findsNothing, reason: banned);
      }
    });
  });

  group('status badge', () {
    testWidgets('label is text, not color-only', (t) async {
      await t.pumpWidget(
        _host(
          const Column(
            children: [
              LabStatusBadge(available: true),
              LabStatusBadge(available: false),
            ],
          ),
        ),
      );
      expect(find.text('이용 가능'), findsOneWidget);
      expect(find.text('준비 중'), findsOneWidget);
    });
  });

  group('논술 LAB entry (app-first)', () {
    testWidgets('primary is app-internal CTA, web is secondary', (t) async {
      await t.pumpWidget(_host(const LegendStudyLabEntry()));
      await t.pumpAndSettle();
      expect(find.text('논술 LAB 시작하기'), findsOneWidget);
      expect(find.text('웹에서 이용하기 ↗'), findsOneWidget);
      expect(find.textContaining('웹에서도 더 편리하게'), findsOneWidget);
    });
  });
}
