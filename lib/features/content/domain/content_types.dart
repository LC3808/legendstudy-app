const contentTypeLabels = {
  'exam': '모의고사',
  'study_material': '학습자료',
  'university_essay': '논술',
  'admissions_info': '입시정보',
  'education_column': '교육칼럼',
  'other': '기타',
};

/// Uses canonical exam metadata, never title parsing. Unknown exams stay generic.
String materialTypeLabel(
  String type, {
  String? examType,
  bool preciseExam = false,
}) {
  if (type == 'exam') {
    if (examType == 'csat') return '수능';
    if (preciseExam && examType == 'national_mock') return '학력평가';
    if (preciseExam && examType == 'evaluation_mock') return '모의평가';
    if (examType == 'national_mock' || examType == 'evaluation_mock') {
      return '모의고사';
    }
    return '시험 자료';
  }
  return contentTypeLabels[type] ?? '기타';
}
