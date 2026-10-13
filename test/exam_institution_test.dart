import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/exams/presentation/exam_institution.dart';

ExamMetadata exam({
  String? type,
  int? grade,
  int? month,
  int? year,
  int? academicYear,
  String? institution,
}) => ExamMetadata(
  contentItemId: 'c',
  examType: type,
  gradeLevel: grade,
  examMonth: month,
  year: year,
  academicYear: academicYear,
  institution: institution,
);

void main() {
  const verified = kVerifiedNationalMockMinAcademicYear;

  group('priority 1 — authoritative stored institution', () {
    test('stored value wins over any mapping', () {
      // Would map to 평가원 by type, but the stored value is authoritative.
      expect(
        resolveExamInstitution(
          exam(type: 'csat', institution: '한국교육과정평가원(원문 표기)'),
        ),
        '한국교육과정평가원(원문 표기)',
      );
    });
    test('stored value wins even when the mapping would be null', () {
      expect(
        resolveExamInstitution(
          exam(type: 'school_assessment', institution: '○○고등학교'),
        ),
        '○○고등학교',
      );
    });
    test('blank stored value falls through to the mapping', () {
      expect(resolveExamInstitution(exam(type: 'csat', institution: '  ')), '한국교육과정평가원');
    });
  });

  group('priority 2 — 평가원 (year-independent)', () {
    test('evaluation_mock → 한국교육과정평가원', () {
      expect(resolveExamInstitution(exam(type: 'evaluation_mock', month: 6)), '한국교육과정평가원');
      expect(resolveExamInstitution(exam(type: 'evaluation_mock', month: 9)), '한국교육과정평가원');
    });
    test('csat → 한국교육과정평가원 regardless of year', () {
      expect(resolveExamInstitution(exam(type: 'csat', year: 2009)), '한국교육과정평가원');
    });
  });

  group('priority 2 — 전국연합학력평가 (고1·고2)', () {
    for (final (month, office) in [
      (3, '서울특별시교육청'),
      (6, '부산광역시교육청'),
      (9, '인천광역시교육청'),
      (10, '경기도교육청'),
      (11, '경기도교육청'),
    ]) {
      test('고1 $month월 → $office', () {
        expect(
          resolveExamInstitution(
            exam(type: 'national_mock', grade: 1, month: month, academicYear: verified),
          ),
          office,
        );
      });
      test('고2 $month월 → $office', () {
        expect(
          resolveExamInstitution(
            exam(type: 'national_mock', grade: 2, month: month, academicYear: verified),
          ),
          office,
        );
      });
    }
  });

  group('priority 2 — 전국연합학력평가 (고3 학력평가)', () {
    for (final (month, office) in [
      (3, '서울특별시교육청'),
      (4, '경기도교육청'),
      (5, '경기도교육청'),
      (7, '인천광역시교육청'),
      (10, '서울특별시교육청'),
    ]) {
      test('고3 $month월 → $office', () {
        expect(
          resolveExamInstitution(
            exam(type: 'national_mock', grade: 3, month: month, academicYear: verified),
          ),
          office,
        );
      });
    }
  });

  group('priority 3 — not confirmable → null', () {
    test('year before the verified window is not blanket-mapped', () {
      expect(
        resolveExamInstitution(
          exam(type: 'national_mock', grade: 3, month: 3, academicYear: verified - 1),
        ),
        isNull,
      );
    });
    test('national_mock without a year is not mapped', () {
      expect(
        resolveExamInstitution(exam(type: 'national_mock', grade: 1, month: 3)),
        isNull,
      );
    });
    test('national_mock missing grade or month → null', () {
      expect(
        resolveExamInstitution(exam(type: 'national_mock', month: 3, academicYear: verified)),
        isNull,
      );
      expect(
        resolveExamInstitution(exam(type: 'national_mock', grade: 1, academicYear: verified)),
        isNull,
      );
    });
    test('month outside the grade schedule → null', () {
      expect(
        resolveExamInstitution(
          exam(type: 'national_mock', grade: 3, month: 6, academicYear: verified),
        ),
        isNull,
      );
    });
    test('school_assessment / preliminary / unknown / null type → null', () {
      for (final t in ['school_assessment', 'preliminary', 'mystery', null]) {
        expect(resolveExamInstitution(exam(type: t, month: 3)), isNull, reason: 'type=$t');
      }
    });
    test('year falls back to `year` when academicYear is absent', () {
      expect(
        resolveExamInstitution(
          exam(type: 'national_mock', grade: 1, month: 3, year: verified),
        ),
        '서울특별시교육청',
      );
    });
  });

  group('examInstitutionLabel', () {
    test('prefixes confirmed institutions with 시행기관:', () {
      expect(examInstitutionLabel(exam(type: 'csat')), '시행기관: 한국교육과정평가원');
    });
    test('returns null when not confirmable (no label shown)', () {
      expect(examInstitutionLabel(exam(type: 'school_assessment')), isNull);
    });
  });
}
