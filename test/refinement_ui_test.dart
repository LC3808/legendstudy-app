import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/credits/credit_balance.dart';
import 'package:legendstudy_app/features/profile/presentation/aspirations_card.dart';
import 'package:legendstudy_app/features/profile/data/intended_major_repository.dart';
import 'package:legendstudy_app/features/universities/application/university_providers.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';

class Interests extends InterestedUniversitiesController {
  Interests(this.values);
  final List<InterestedUniversity> values;
  @override
  Future<List<InterestedUniversity>> build() async => values;
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'compact Credit visual and touch geometry at 360 scale $scale',
      (t) async {
        t.view.physicalSize = const Size(360, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              creditBalanceProvider.overrideWith(
                (ref) async => CreditBalance.fromJson({
                  'dto_version': 'credit-v1',
                  'spendable': 11,
                  'paid': 0,
                  'free': 11,
                  'other': 0,
                  'next_expiry': null,
                }),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: CreditBalanceCard(compact: true, showTopUp: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final button = find.byType(OutlinedButton);
        expect(t.getSize(button).height, greaterThanOrEqualTo(48));
        final style = t.widget<OutlinedButton>(button).style!;
        expect(style.minimumSize!.resolve({})!.height, 28);
        expect(style.padding!.resolve({})!.vertical, 8);
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final populated in [false, true]) {
    testWidgets(
      'aspirations use canonical interests and show only existing applications $populated',
      (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              interestedUniversitiesProvider.overrideWith(
                () => Interests(
                  populated
                      ? [
                          const InterestedUniversity(
                            id: '1',
                            universityId: 'u',
                            name: '희망대학',
                            intendedDivision: '공학',
                          ),
                        ]
                      : [],
                ),
              ),
              intendedMajorProvider.overrideWith(
                (ref) async => populated ? '공학' : null,
              ),
              applicationLabelsProvider.overrideWith(
                (ref) async => populated ? ['지원대학 · 수학과'] : [],
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: AspirationsCard())),
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text('지원 대학·학과'),
          populated ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('희망대학·학과를 설정해 주세요.'),
          populated ? findsNothing : findsOneWidget,
        );
        if (populated) {
          expect(find.text('희망대학 · 공학'), findsOneWidget);
          expect(find.text('지원대학 · 수학과'), findsOneWidget);
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}
