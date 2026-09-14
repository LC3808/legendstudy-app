import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/presentation/home_meal_card.dart';
import 'package:legendstudy_app/features/school/presentation/neis_attribution.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'day7_school_test.dart' show schoolA, meal;

class FixedSchool extends SchoolSelection {
  FixedSchool(this.school);
  final School? school;
  @override
  Future<School?> build() async => school;
}

void main() {
  void viewport(WidgetTester tester, double scale) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );

  Future<void> verifyDialog(WidgetTester tester, String label) async {
    final action = find.widgetWithText(TextButton, label);
    final rect = tester.getRect(action);
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('정보 출처'), findsOneWidget);
    expect(
      find.text('학교·급식 정보는 교육부 및 시·도교육청의 NEIS 데이터를 이용합니다.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  }

  for (final scale in [1.0, 2.0]) {
    for (final state in ['none', 'data', 'empty']) {
      testWidgets(
        'Home $state school title keeps accessible action without attribution at ${scale}x',
        (tester) async {
          viewport(tester, scale);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                schoolSelectionProvider.overrideWith(
                  () => FixedSchool(state == 'none' ? null : schoolA),
                ),
                todayMealsProvider.overrideWith(
                  (ref) async => state == 'data' ? [meal] : [],
                ),
              ],
              child: host(const HomeMealCard()),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              state == 'none'
                  ? '학교를 설정하면 오늘 급식을 볼 수 있어요.'
                  : state == 'empty'
                  ? '오늘 등록된 급식 정보가 없어요.'
                  : '오늘의 급식',
            ),
            findsOneWidget,
          );
          final settings = tester.getRect(
            find.widgetWithText(TextButton, '학교 설정'),
          );
          expect(settings.width, greaterThanOrEqualTo(48));
          expect(settings.height, greaterThanOrEqualTo(48));
          final row = find
              .ancestor(
                of: find.widgetWithText(TextButton, '학교 설정'),
                matching: find.byType(scale == 1.0 ? Row : Column),
              )
              .first;
          expect(
            find.descendant(
              of: row,
              matching: find.text(
                state == 'none' ? '우리 학교 · 오늘 급식' : schoolA.name,
              ),
            ),
            findsOneWidget,
          );
          expect(find.byType(NeisAttribution), findsNothing);
          expect(find.textContaining('NEIS'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('School footer compact accessible dialog at ${scale}x', (
      tester,
    ) async {
      viewport(tester, scale);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolSelectionProvider.overrideWith(() => FixedSchool(schoolA)),
            schoolSearchProvider('').overrideWith((ref) async => []),
          ],
          child: host(const SchoolPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('선택한 학교'), findsOneWidget);
      expect(find.text(schoolA.name), findsOneWidget);
      expect(
        find.text('학교·급식 정보 출처: 교육부·시도교육청 / 나이스 교육정보 개방 포털'),
        findsNothing,
      );
      await verifyDialog(tester, '출처: 교육부·시도교육청 NEIS');
      expect(tester.takeException(), isNull);
    });
  }
}
