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
