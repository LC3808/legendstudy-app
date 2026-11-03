import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/domain/school_search_policy.dart';

School school(String name, String type, [String code = '1']) => School(
  officeCode: 'B10',
  schoolCode: code,
  name: name,
  schoolType: type,
  address: '',
);
void main() {
  test('level intent is suffix based, never a contained syllable', () {
    for (final q in ['별내', '별내고', '별가람', '진접', '중앙', '중동', '중']) {
      expect(schoolSearchType(q), '고등학교', reason: q);
    }
    for (final q in ['별내중', '별가람중', '중앙중', '별내중학교', ' 별내 중학교 ']) {
      expect(schoolSearchType(q), '중학교', reason: q);
    }
    expect(schoolSearchQuery('별내고'), '별내고등학교');
    expect(schoolSearchQuery('중앙중'), '중앙중학교');
  });
  test(
    'exact, prefix, contains; type metadata excludes elementary/unknown',
    () {
      final rows = [
        school('서울중앙고등학교', '고등학교'),
        school('중앙고등학교', '초등학교'),
        school('중앙중학교', '중학교'),
        school('중앙여자고등학교', '고등학교'),
        school('중앙고등학교', '고등학교'),
        school('중앙고등학교', ''),
      ];
      expect(rankSchoolResults('중앙', rows).map((s) => s.name), [
        '중앙고등학교',
        '중앙여자고등학교',
        '서울중앙고등학교',
      ]);
      expect(rankSchoolResults('중앙고등학교', rows).first.name, '중앙고등학교');
      expect(rankSchoolResults('중앙중', rows).single.schoolType, '중학교');
      expect(rankSchoolResults('중앙초등학교', rows), isEmpty);
    },
  );
}
