import 'package:supabase_flutter/supabase_flutter.dart';

/// Owner Oct09: every active material is discoverable, including older exams.
/// Repositories enforce is_active; historical year alone never hides a source.
abstract final class DiscoveryPolicy {
  static const examProjection =
      'discovery_exam:exams!exams_content_type(content_item_id)';
  static PostgrestFilterBuilder<T> exams<T>(PostgrestFilterBuilder<T> query) =>
      query;
  static PostgrestFilterBuilder<T> content<T>(
    PostgrestFilterBuilder<T> query,
  ) => query;
}
