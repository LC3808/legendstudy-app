import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/content_resource.dart';
import '../domain/resource_repository.dart';

class SupabaseResourceRepository implements ResourceRepository {
  SupabaseResourceRepository(this.client);
  final SupabaseClient client;
  static const projection =
      'id,content_item_id,exam_subject_id,resource_type,title,source_label,source_url,link_kind,file_url,mime_type,file_extension,file_size,display_order,is_active,'
      'occurrence:exam_subjects!resources_subject_same_content(id,content_item_id,subject_id,raw_subject_label,taxonomy_version,mapping_status,display_order,is_active,'
      'subject:subjects!exam_subjects_versioned_mapping(id,code,name,category,taxonomy_version,curriculum_version,parent_id,sort_order,is_active))';
  @override
  Future<List<ContentResource>> fetchForContent(String contentItemId) async {
    final result = <ContentResource>[];
    // Page resources separately from parents; left embedding never filters out a
    // resource whose mapped taxonomy row is inactive or missing.
    for (var offset = 0; ; offset += 100) {
      final rows = await client
          .from('resources')
          .select(projection)
          .eq('content_item_id', contentItemId)
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + 99);
      result.addAll(rows.map(ContentResource.fromJson));
      if (rows.length < 100) return result;
    }
  }
}
