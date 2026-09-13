import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/exam_metadata.dart';
import '../domain/exam_repository.dart';

class SupabaseExamRepository implements ExamRepository {
  SupabaseExamRepository(this.client);
  final SupabaseClient client;
  static const projection =
      'content_item_id,content_type,year,academic_year,exam_month,exam_date,sort_date,grade_level,exam_type,exam_round,curriculum_version';
  @override
  Future<Map<String, ExamMetadata>> fetchForContentIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    if (ids.length > 100) {
      throw ArgumentError('At most 100 content IDs per page.');
    }
    final rows = await client
        .from('exams')
        .select(projection)
        .inFilter('content_item_id', ids)
        .limit(100);
    return {
      for (final row in rows)
        row['content_item_id'] as String: ExamMetadata.fromJson(row),
    };
  }
}
