import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/essay_credit_source.dart';

void main() {
  Map<String, dynamic> fixture() => {
    'version': 'essay-credit-source-v1',
    'grant_id': '11111111-1111-4111-8111-111111111111',
    'source': 'purchase',
    'beta': 0,
    'signup_bonus': 0,
    'purchase': 3,
    'other': 0,
  };
  test('paid fallback preserves server selected grant and balances', () {
    final source = EssayCreditSource.parse(fixture(), 1);
    expect(source.label, '유료 Credit');
    expect(source.paid, 3);
    expect(source.grantId, fixture()['grant_id']);
  });
  test('free rewrite never requires a paid grant', () {
    expect(
      EssayCreditSource.parse({
        ...fixture(),
        'source': 'included',
        'grant_id': null,
      }, 0).grantId,
      isNull,
    );
    expect(() => EssayCreditSource.parse(fixture(), 0), throwsFormatException);
  });
  test('usageLabel names the server-confirmed source in one line', () {
    expect(EssayCreditSource.parse(fixture(), 1).usageLabel, '유료 Credit 사용');
    expect(
      EssayCreditSource.parse({...fixture(), 'source': 'beta'}, 1).usageLabel,
      '베타 테스트 Credit 사용',
    );
    expect(
      EssayCreditSource.parse(
        {...fixture(), 'source': 'signup_bonus'},
        1,
      ).usageLabel,
      '무료 Credit 사용',
    );
    expect(
      EssayCreditSource.parse(
        {...fixture(), 'source': 'admin_grant'},
        1,
      ).usageLabel,
      '관리자 지급 Credit 사용',
    );
    // Every known source maps to a usage label (confirmation never shows a blank).
    for (final source in EssayCreditSource.labels.keys) {
      expect(EssayCreditSource.usageLabels[source], isNotNull);
    }
  });
  test('invalid source or balance fails closed', () {
    for (final patch in [
      {'source': 'unknown'},
      {'grant_id': null},
      {'grant_id': 'invalid'},
      {'purchase': -1},
      {'beta': 1.5},
      {'signup_bonus': '3'},
      {'version': 'unknown'},
    ]) {
      expect(
        () => EssayCreditSource.parse({...fixture(), ...patch}, 1),
        throwsFormatException,
      );
    }
  });
}
