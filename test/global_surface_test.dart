import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';

void main() {
  test('global depth preserves the Owner-approved Home shadow exactly', () {
    expect(AppTokens.majorSurfaceShadow, const [
      BoxShadow(color: Color(0x0D1B2A4A), offset: Offset(0, 2), blurRadius: 4),
    ]);
    expect(AppTokens.majorSurfaceBorder, const Color(0xFFC4CCD7));
    expect(AppTokens.primary, const Color(0xFFFFA300));
  });

  testWidgets('nested groups and repeated items never accumulate shadows', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              LsCard(
                child: Column(
                  children: [
                    Text('major'),
                    LsCard(child: Text('nested')),
                  ],
                ),
              ),
              LsCard(level: LsSurfaceLevel.nested, child: Text('list item')),
            ],
          ),
        ),
      ),
    );
    final surfaces = t
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .map((c) => c.decoration! as BoxDecoration)
        .toList();
    expect(
      surfaces.where((d) => d.boxShadow?.isNotEmpty == true),
      hasLength(1),
    );
    expect(surfaces.skip(1).every((d) => d.boxShadow == null), isTrue);
    expect(
      surfaces
          .skip(1)
          .every((d) => d.border == Border.all(color: AppTokens.cardBorder)),
      isTrue,
    );
  });

  testWidgets('Settings is one major group, rows and controls stay flat', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SettingsGroup(
            title: '기본 정보',
            children: [
              LsListRow(title: '학교·학년', onTap: () {}),
              OutlinedButton(onPressed: () {}, child: const Text('inline')),
              const Chip(label: Text('chip')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(LsCard), findsOneWidget);
    expect(t.widget<Chip>(find.byType(Chip)).elevation ?? 0, 0);
    final materials = t.widgetList<Material>(find.byType(Material));
    expect(materials.every((m) => m.elevation == 0), isTrue);
  });
}
