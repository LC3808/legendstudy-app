import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/exams/presentation/exam_labels.dart';

void main() {
  String? organizer(int? year, int? grade, int? month, String? type) =>
      examOrganizer(
        ExamMetadata(
          contentItemId: 'exam',
          year: year,
          gradeLevel: grade,
          examMonth: month,
          examType: type,
        ),
      );
  test('official 2026 grade-specific calendar, not month-only rules', () {
    for (final grade in [1, 2]) {
      expect(organizer(2026, grade, 9, 'national_mock'), '인천광역시교육청');
      expect(organizer(2026, grade, 6, 'national_mock'), '부산광역시교육청');
      expect(organizer(2026, grade, 10, 'national_mock'), '경기도교육청');
    }
    expect(organizer(2026, 3, 5, 'national_mock'), '경기도교육청');
    expect(organizer(2026, 3, 7, 'national_mock'), '인천광역시교육청');
    expect(organizer(2026, 3, 10, 'national_mock'), '서울특별시교육청');
    for (final grade in [1, 2, 3]) {
      expect(organizer(2026, grade, 3, 'national_mock'), '서울특별시교육청');
    }
  });
  test('evaluation mocks and CSAT use canonical type, not school month', () {
    for (final month in [6, 9]) {
      expect(organizer(2026, 3, month, 'evaluation_mock'), '한국교육과정평가원');
      expect(organizer(2026, 3, month, 'national_mock'), isNull);
    }
    expect(organizer(2025, 3, 11, 'csat'), '한국교육과정평가원');
  });
  test('unknown year grade month type cannot invent organizer', () {
    for (final year in [null, 2025, 2027]) {
      expect(organizer(year, 1, 9, 'national_mock'), isNull);
    }
    expect(organizer(2026, null, 9, 'national_mock'), isNull);
    expect(organizer(2026, 1, 4, 'national_mock'), isNull);
    expect(organizer(2026, 3, 9, null), isNull);
    expect(organizer(2026, 3, 9, 'other'), isNull);
  });
}
