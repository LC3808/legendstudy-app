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
    this.institution,
  });
  final String contentItemId;
  final int? year, academicYear, examMonth, gradeLevel;
  final DateTime? examDate;
  final String? examType, examRound, curriculumVersion;

  /// Authoritative administering institution ("시행기관") when the data carries
  /// one. It is read defensively and is normally null today: the `exams`
  /// projection does not yet select such a column, so [institution] is the
  /// highest-priority source once that metadata exists (requires a DB change,
  /// handled separately). See `resolveExamInstitution`.
  final String? institution;

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
    // Accept either naming if a future projection provides it; absent → null.
    institution:
        (json['institution'] ?? json['administering_institution']) as String?,
  );
}
