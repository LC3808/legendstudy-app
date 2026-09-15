import 'content_item.dart';

abstract interface class ContentRepository {
  Future<List<ContentItem>> fetchRecentContent({int limit = 30});
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  });
  Future<ContentItem?> fetchContentBySlug(String slug);
  Future<List<ContentItem>> fetchContentByIds(List<String> ids);
}
