import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/service_availability.dart';
import 'package:legendstudy_app/features/essay/university_catalog.dart';

void main() {
  test('exact Owner 16 remain in unchanged 42 Catalog, other universities unaffected', () {
    const names = {
      '연세대학교',
      '홍익대학교',
      '서울시립대학교',
      '성신여자대학교',
      '을지대학교',
      '단국대학교',
      '삼육대학교',
      '덕성여자대학교',
      '동덕여자대학교',
      '서경대학교',
      '수원대학교',
      '신한대학교',
      '한국공학대학교',
      '한국기술교육대학교',
      '한신대학교',
      '강남대학교',
    };
    expect(essayUniversityCatalog.length, 42);
    expect(
      essayUniversityCatalog
          .where((u) => isUniversityServicePreparing(u['sourceUniversityId']))
          .map((u) => u['name'])
          .toSet(),
      names,
    );
    expect(isUniversityServicePreparing('konkuk'), false);
  });
}
