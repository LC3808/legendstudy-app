import 'dart:convert';
import 'dart:io';

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
  test(
    'historical cells match verified existing authority without extrapolation',
    () {
      final registry = jsonDecode(
        File('tool/ingestion/reference/exam-expected-coverage.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      const names = {
        'SEOUL': '서울특별시교육청',
        'BUSAN': '부산광역시교육청',
        'INCHEON': '인천광역시교육청',
        'GYEONGGI': '경기도교육청',
      };
      final verified = <(int, int, int), String>{};
      for (final entry in registry['entries'] as List) {
        final i = entry['identity'];
        if (i['exam_family'] != 'national_mock' ||
            entry['status'] != 'VERIFIED' ||
            (entry['identity_evidence'] as List).isEmpty) {
          continue;
        }
        for (final source in entry['identity_evidence'] as List) {
          expect(
            registry['sources'][source]['verification_status'],
            'VERIFIED',
          );
        }
        verified[(
              i['exam_year'] as int,
              i['grade'] as int,
              i['nominal_month'] as int,
            )] =
            names[i['organizer']]!;
      }
      expect(verified.length, 47);
      for (var year = 2000; year <= 2025; year++) {
        for (var grade = 1; grade <= 3; grade++) {
          for (var month = 1; month <= 12; month++) {
            expect(
              organizer(year, grade, month, 'national_mock'),
              verified[(year, grade, month)],
              reason: '$year/$grade/$month',
            );
          }
        }
        expect(organizer(year, 3, 6, 'evaluation_mock'), '한국교육과정평가원');
        expect(organizer(year, 3, 9, 'evaluation_mock'), '한국교육과정평가원');
        expect(organizer(year, 3, 11, 'csat'), '한국교육과정평가원');
      }
      // Preserve nominal-month exceptions, not the delayed actual exam month.
      expect(organizer(2023, 1, 11, 'national_mock'), '경기도교육청');
      expect(organizer(2023, 1, 12, 'national_mock'), isNull);
      expect(organizer(2024, 3, 4, 'national_mock'), isNull);
      expect(organizer(2024, 3, 5, 'national_mock'), '경기도교육청');
    },
  );
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
