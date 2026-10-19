import '../domain/exam_metadata.dart';

String formatDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
String examSummary(ExamMetadata exam) => [
  if (exam.gradeLevel != null) '고${exam.gradeLevel}',
  if (exam.examMonth != null) '${exam.examMonth}월',
  if (exam.year != null) '${exam.year}년',
  if (exam.examType != null)
    switch (exam.examType) {
      'school_assessment' => '학교 평가',
      'national_mock' => '전국연합',
      'evaluation_mock' => '평가원',
      'csat' => '수능',
      'preliminary' => '예비시험',
      _ => '기타',
    },
].join(' · ');
List<String> examDetails(ExamMetadata exam) => [
  if (examSummary(exam).isNotEmpty) examSummary(exam),
  if (exam.academicYear != null) '${exam.academicYear}학년도',
  if (exam.examDate != null) '시험일 ${formatDate(exam.examDate!)}',
  if (exam.examRound?.trim().isNotEmpty ?? false) '회차 ${exam.examRound}',
  if (exam.curriculumVersion?.trim().isNotEmpty ?? false)
    '교육과정 ${exam.curriculumVersion}',
];

/// Verified exam authority, never the material host or a month-only inference.
/// 2026 calendar: https://www.ice.go.kr/upload/ice/na/bbs_570/2026/04/16f9bd0249ccf5ec99fdaa3e12a5df18.pdf
/// Unknown historical national exams remain hidden until individually verified.
String? examOrganizer(ExamMetadata exam) {
  if (exam.examType == 'csat' || exam.examType == 'evaluation_mock') {
    return '한국교육과정평가원';
  }
  if (exam.examType != 'national_mock') return null;
  if (exam.year != 2026) {
    // Exact verified identity cells from the existing ingestion authority:
    // tool/ingestion/reference/exam-expected-coverage.json (identity_evidence).
    // Nominal exam month, not postponed administration month; no year fallback.
    return switch ((exam.year, exam.gradeLevel, exam.examMonth)) {
      (2020, 3, 3) ||
      (2021, 1, 3) ||
      (2021, 2, 3) ||
      (2021, 3, 3) ||
      (2021, 3, 10) ||
      (2022, 1, 3) ||
      (2022, 2, 3) ||
      (2022, 3, 3) ||
      (2022, 3, 10) ||
      (2023, 1, 3) ||
      (2023, 2, 3) ||
      (2023, 3, 3) ||
      (2023, 3, 10) ||
      (2024, 1, 3) ||
      (2024, 2, 3) ||
      (2024, 3, 3) ||
      (2024, 3, 10) => '서울특별시교육청',
      (2021, 1, 11) ||
      (2021, 2, 11) ||
      (2021, 3, 4) ||
      (2022, 1, 11) ||
      (2022, 2, 11) ||
      (2022, 3, 4) ||
      (2023, 1, 11) ||
      (2023, 2, 11) ||
      (2023, 3, 4) ||
      (2024, 1, 10) ||
      (2024, 2, 10) ||
      (2024, 3, 5) => '경기도교육청',
      (2021, 2, 6) ||
      (2022, 1, 6) ||
      (2022, 2, 6) ||
      (2023, 1, 6) ||
      (2023, 2, 6) ||
      (2024, 1, 6) ||
      (2024, 2, 6) => '부산광역시교육청',
      (2021, 2, 9) ||
      (2021, 3, 7) ||
      (2022, 1, 9) ||
      (2022, 2, 9) ||
      (2022, 3, 7) ||
      (2023, 1, 9) ||
      (2023, 2, 9) ||
      (2023, 3, 7) ||
      (2024, 1, 9) ||
      (2024, 2, 9) ||
      (2024, 3, 7) => '인천광역시교육청',
      _ => null,
    };
  }
  return switch ((exam.gradeLevel, exam.examMonth)) {
    (1 || 2 || 3, 3) => '서울특별시교육청',
    (1 || 2, 6) => '부산광역시교육청',
    (1 || 2, 9) => '인천광역시교육청',
    (1 || 2, 10) => '경기도교육청',
    (3, 5) => '경기도교육청',
    (3, 7) => '인천광역시교육청',
    (3, 10) => '서울특별시교육청',
    _ => null,
  };
}
