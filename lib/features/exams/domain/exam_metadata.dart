class ExamMetadata {
  const ExamMetadata({
    required this.contentItemId,
    this.year,
    this.academicYear,
    this.examMonth,
    this.examDate,
    this.gradeLevel,
    this.examType,
    this.examRound,
    this.curriculumVersion,
  });
  final String contentItemId;
  final int? year, academicYear, examMonth, gradeLevel;
  final DateTime? examDate;
  final String? examType, examRound, curriculumVersion;
  factory ExamMetadata.fromJson(Map<String, dynamic> json) => ExamMetadata(
    contentItemId: json['content_item_id'] as String,
    year: json['year'] as int?,
    academicYear: json['academic_year'] as int?,
    examMonth: json['exam_month'] as int?,
    gradeLevel: json['grade_level'] as int?,
    examDate: json['exam_date'] == null
        ? null
        : DateTime.parse(json['exam_date'] as String),
    examType: json['exam_type'] as String?,
    examRound: json['exam_round'] as String?,
    curriculumVersion: json['curriculum_version'] as String?,
  );
}
