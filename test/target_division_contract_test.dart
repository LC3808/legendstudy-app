import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';

void main() {
  test('legacy university-only rows preserve identity and display', () {
    final row = InterestedUniversity.fromJson({
      'id': 'target-1', 'university_id': 'university-1',
      'universities': {'name': '연세대학교'},
    });
    expect(row.displayLabel, '연세대학교');
    expect(row.intendedDivision, isNull);
    expect(row.admissionYear, isNull);
    expect(row.id, 'target-1');
  });
  test('multiple divisions retain separate row identities and historical year', () {
    final rows = ['경영학과', '경제학부'].asMap().entries.map((entry) =>
      InterestedUniversity.fromJson({
        'id': 'target-${entry.key}', 'university_id': 'university-1',
        'universities': {'name': '연세대학교'},
        'intended_division': entry.value, 'admission_year': 2027,
      })).toList();
    expect(rows.map((r) => r.id).toSet().length, 2);
    expect(rows.map((r) => r.universityId).toSet().length, 1);
    expect(rows[0].displayLabel, '연세대학교 · 경영학과 · 2027학년도');
    expect(rows[1].displayLabel, '연세대학교 · 경제학부 · 2027학년도');
  });
}
