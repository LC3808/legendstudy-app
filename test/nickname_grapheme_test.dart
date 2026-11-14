import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/features/profile/nickname_validation.dart';

void main() {
  for (final char in [
    '가',
    'a',
    '👨‍👩‍👧‍👦',
    '👍🏽',
    '🇰🇷',
    'e\u0301',
    '가',
  ]) {
    test('20/21 visible characters: $char', () {
      expect(nicknameValidationError(char * 20), isNull);
      expect(nicknameValidationError(char * 21), isNotNull);
    });
  }
  test('unchanged legacy name is preserved', () {
    final old = '가' * 80;
    expect(nicknameValidationError(old, previous: old), isNull);
    expect(nicknameValidationError('$old! ', previous: old), isNotNull);
  });
}
