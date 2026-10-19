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
/// Historical annual policy confirmed by Owner with the 2025 calendar (Oct19).
String? examOrganizer(ExamMetadata exam) {
  if (exam.examType == 'csat' || exam.examType == 'evaluation_mock') {
    return '한국교육과정평가원';
  }
  // Source123 explicitly identifies the 2014 CSAT preliminary administration.
  if (exam.year == 2012 &&
      exam.gradeLevel == 2 &&
      exam.examMonth == 5 &&
      exam.examType == 'preliminary') {
    return '한국교육과정평가원';
  }
  if (exam.examType != 'national_mock') return null;
  if (exam.year != 2026) {
    final year = exam.year;
    if (year == null || year < 2000 || year > 2025) return null;
    // Owner-confirmed annual organizer policy (Oct19, with 2025 calendar).
    // Use nominal round months; preserve the 2024 schedule transition.
    return switch ((exam.gradeLevel, exam.examMonth)) {
      // Legacy national_mock classification does not change the G3 organizer.
      (3, 6 || 9) => '한국교육과정평가원',
      // Source1084: 경기도학업성취도평가, not the normal June round.
      (2, 5) when year == 2008 => '경기도교육청',
      (1 || 2 || 3, 3) => '서울특별시교육청',
      (1 || 2, 6) => '부산광역시교육청',
      (1 || 2, 9) => '인천광역시교육청',
      (1 || 2, 11) when year <= 2023 => '경기도교육청',
      (1 || 2, 10) when year >= 2024 => '경기도교육청',
      (3, 4) when year <= 2023 => '경기도교육청',
      (3, 5) when year >= 2024 => '경기도교육청',
      (3, 7) => '인천광역시교육청',
      (3, 10) => '서울특별시교육청',
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
