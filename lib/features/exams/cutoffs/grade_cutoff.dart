import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/exam_metadata.dart';

bool supportsGradeCutoff(ExamMetadata? exam) =>
    exam != null &&
    exam.gradeLevel == 3 &&
    (exam.academicYear ?? 0) >= 2024 &&
    (exam.academicYear ?? 0) <= 2027 &&
    ((exam.examType == 'evaluation_mock' && [6, 9].contains(exam.examMonth)) ||
        (exam.examType == 'csat' &&
            exam.examMonth == 11 &&
            exam.academicYear! < 2027));

class GradeCutoff {
  GradeCutoff(this.data) {
    if (grade < 1 ||
        grade > 9 ||
        data['exam_subject_id'] is! String ||
        data['subject_label'] is! String ||
        data['academic_year'] is! int) {
      throw const FormatException('Invalid cutoff reference');
    }
    for (final key in [
      'raw_score',
      'raw_score_min',
      'raw_score_max',
      'standard_score',
    ]) {
      final n = data[key];
      if (n != null &&
          (n is! int || n < 0 || n > (key == 'standard_score' ? 200 : 100))) {
        throw const FormatException('Invalid score');
      }
    }
    if ((data['raw_score_min'] == null) != (data['raw_score_max'] == null) ||
        (data['raw_score_min'] != null &&
            (data['raw_score_min'] as int) > (data['raw_score_max'] as int)) ||
        (data['raw_score'] != null && data['raw_score_min'] != null)) {
      throw const FormatException('Invalid score range');
    }
  }
  final Map<String, dynamic> data;
  int get grade => data['grade'] as int;
  int get year => data['academic_year'] as int;
  String get key => '${data['exam_subject_id']}:${data['elective_key'] ?? ''}';
  String get label => [
    data['subject_label'],
    data['elective_label'],
  ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  bool get hasRaw => data['raw_score'] != null || data['raw_score_min'] != null;
  String get scoreType => hasRaw
      ? '원점수'
      : data['standard_score'] != null
      ? '표준점수'
      : '자료 없음';
  String get score =>
      data['raw_score']?.toString() ??
      (data['raw_score_min'] != null
          ? '${data['raw_score_min']}~${data['raw_score_max']}'
          : data['standard_score']?.toString()) ??
      '—';
  String get certainty => scoreType == '자료 없음'
      ? '자료 없음'
      : certaintyLabel(data[hasRaw ? 'raw_certainty' : 'standard_certainty']);
  static String certaintyLabel(Object? value) => switch (value) {
    'confirmed' => '확정',
    'estimated' => '추정',
    _ => '확정 여부 미제공',
  };
}

final gradeCutoffsProvider = FutureProvider.autoDispose
    .family<List<GradeCutoff>, String>((ref, id) async {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return [];
      final rows = await client
          .rpc<dynamic>(
            'grade_cutoff_lookup',
            params: {'p_content_item_id': id},
          )
          .timeout(const Duration(seconds: 15));
      if (rows is! List) throw const FormatException('Invalid cutoff response');
      final seen = <String>{};
      return rows.map((r) {
        final row = GradeCutoff(Map<String, dynamic>.from(r as Map));
        if (row.data['content_item_id'] != id ||
            !seen.add('${row.key}:${row.grade}')) {
          throw const FormatException('Mismatched or duplicate cutoff');
        }
        return row;
      }).toList();
    }, retry: (_, _) => null);

/// Existing Registry only, including exams without a ready answer-key version.
final cutoffExamsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return [];
      final rows = await client
          .from('exams')
          .select(
            'content_item_id,academic_year,exam_month,exam_type,grade_level,content_items!inner(is_active)',
          )
          .eq('content_items.is_active', true)
          .eq('grade_level', 3)
          .gte('academic_year', 2024)
          .lte('academic_year', 2027)
          .inFilter('exam_type', ['evaluation_mock', 'csat'])
          .order('academic_year', ascending: false)
          .order('exam_month', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 15));
      return rows
          .where((r) => supportsGradeCutoff(ExamMetadata.fromJson(r)))
          .toList();
    }, retry: (_, _) => null);
