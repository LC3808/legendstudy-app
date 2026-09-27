import 'package:supabase_flutter/supabase_flutter.dart';

/// App discovery only. Source archives and saved/history detail remain intact.
abstract final class DiscoveryPolicy {
  static const firstExamYear = 2010;
  static const examProjection =
      'discovery_exam:exams!exams_content_type(content_item_id)';

  static PostgrestFilterBuilder<T> exams<T>(PostgrestFilterBuilder<T> query) =>
      query.or('year.gte.$firstExamYear');

  static PostgrestFilterBuilder<T> content<T>(
    PostgrestFilterBuilder<T> query,
  ) => query
      .gte('discovery_exam.year', firstExamYear)
      .or('content_type.neq.exam,discovery_exam.not.is.null');
}
