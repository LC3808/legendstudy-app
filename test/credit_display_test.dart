import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/credit_display.dart';

void main() {
  final cases = jsonDecode(
    File('test/fixtures/credit_display.json').readAsStringSync(),
  ) as List;
  for (final row in cases) {
    test('WEB/APP label ${row[0]} ${row[1]}', () {
      expect(
        creditEntryLabel(row[0] as String, row[1] as String?, row[2] as num),
        row[3],
      );
      expect(row[3], isNot(contains('크레딧')));
    });
  }
}
