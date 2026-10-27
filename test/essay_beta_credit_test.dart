import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/essay_beta_credit.dart';

void main() {
  Map<String, dynamic> fixture() => {
    'version': 'essay-beta-credit-v1',
    'active': true,
    'available': 2,
    'expires_at': '2026-10-27T15:00:00Z',
  };
  test('uses server balance and absolute KST midnight timestamp', () {
    final value = EssayBetaCredit.parse(fixture())!;
    expect(value.available, 2);
    expect(value.expiresAt, DateTime.utc(2026, 10, 27, 15));
  });
  test('inactive campaign has no beta balance', () {
    expect(
      EssayBetaCredit.parse({
        'version': 'essay-beta-credit-v1',
        'active': false,
      }),
      isNull,
    );
  });
  test('invalid balance and expiry never displayed', () {
    for (final count in [-1, 3, 1.5, '2']) {
      expect(
        () => EssayBetaCredit.parse({...fixture(), 'available': count}),
        throwsFormatException,
      );
    }
    expect(
      () => EssayBetaCredit.parse({...fixture(), 'expires_at': 'invalid'}),
      throwsFormatException,
    );
    expect(
      () => EssayBetaCredit.parse({...fixture(), 'version': 'other'}),
      throwsFormatException,
    );
  });
}
