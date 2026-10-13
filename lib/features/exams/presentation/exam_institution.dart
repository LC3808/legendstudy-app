import '../domain/exam_metadata.dart';

/// Official administering institution ("시행기관") resolution for mock-exam
/// materials, shown in place of the generic "출처: 레전드스터디 닷컴" label.
///
/// This is display-only: it never alters the material's stored source/provenance
/// or download URL, and never queries the database. It only interprets exam
/// metadata the app already fetches.
///
/// Resolution priority (STEP 2 Owner direction, 2026-10-13):
///   1. authoritative institution stored on the exam metadata ([ExamMetadata.institution]),
///   2. a verified mapping by exam type / grade / year / month,
///   3. otherwise `null` — an unconfirmed institution is NEVER asserted.

/// 한국교육과정평가원 — administers the 6월·9월 모의평가 (`evaluation_mock`) and
/// the 11월 수능 (`csat`). Year-independent and certain.
const String kceppInstitution = '한국교육과정평가원';

/// Academic years from this value onward use the verified 전국연합학력평가
/// 시·도교육청 assignment below. The assignment is institutionally stable for
/// the recent period (부산 6월 since 2014, 인천 9월 since 2010, per 위키백과),
/// and cross-checked for 2022–2026 against 위키백과 / 나무위키 / EBSi — all
/// consistent. Earlier years are intentionally NOT blanket-mapped (older
/// rotations varied) and resolve to `null` (검토 대상) unless authoritative
/// [ExamMetadata.institution] metadata exists. Owner/data-confirmable; a future
/// convention change would also need a verified update here or priority-1 data.
const int kVerifiedNationalMockMinAcademicYear = 2022;

/// Resolve the institution to display, or `null` when it cannot be confirmed.
String? resolveExamInstitution(ExamMetadata exam) {
  // (1) Authoritative stored value always wins.
  final stored = exam.institution?.trim();
  if (stored != null && stored.isNotEmpty) return stored;

  // (2) Verified mapping by exam type.
  switch (exam.examType) {
    case 'evaluation_mock': // 평가원 모의평가 (6월·9월)
    case 'csat': // 수능
      return kceppInstitution;
    case 'national_mock': // 전국연합학력평가 — 시·도교육청 (연도 민감)
      return _nationalMockOffice(exam);
    default:
      // school_assessment / preliminary / unknown → 확인 불가 (검토 대상)
      return null;
  }
}

/// 전국연합학력평가 administering 시·도교육청 by grade + month, gated to the
/// verified academic-year window. Any gap (missing grade/month/year, an
/// out-of-window year, or a month outside the grade's schedule) returns `null`.
String? _nationalMockOffice(ExamMetadata exam) {
  final grade = exam.gradeLevel;
  final month = exam.examMonth;
  if (grade == null || month == null) return null;
  final year = exam.academicYear ?? exam.year;
  if (year == null || year < kVerifiedNationalMockMinAcademicYear) return null;

  // 고1·고2: 3월 서울 / 6월 부산 / 9월 인천 / 연말 경기.
  // 연말 시험은 수능 일정에 따라 11월에, 2024학년도에는 10월에 시행 — 둘 다 경기.
  if (grade == 1 || grade == 2) {
    return switch (month) {
      3 => '서울특별시교육청',
      6 => '부산광역시교육청',
      9 => '인천광역시교육청',
      10 || 11 => '경기도교육청',
      _ => null,
    };
  }
  // 고3 학력평가: 3월 서울 / 경기 / 7월 인천 / 10월 서울.
  // 경기 주관 시험은 4월에, 2024학년도에는 5월에 시행 — 둘 다 경기.
  // (고3 6월·9월 모의평가와 11월 수능은 평가원 → `evaluation_mock`/`csat`에서 처리)
  if (grade == 3) {
    return switch (month) {
      3 => '서울특별시교육청',
      4 || 5 => '경기도교육청',
      7 => '인천광역시교육청',
      10 => '서울특별시교육청',
      _ => null,
    };
  }
  return null;
}

/// Full display label (e.g. "시행기관: 한국교육과정평가원"), or `null` when the
/// institution cannot be confirmed and no label should be shown.
String? examInstitutionLabel(ExamMetadata exam) {
  final name = resolveExamInstitution(exam);
  return name == null ? null : '시행기관: $name';
}
