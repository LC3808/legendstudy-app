import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/content_item.dart';
import '../domain/content_repository.dart';

class SupabaseContentRepository implements ContentRepository {
  SupabaseContentRepository(this.client);
  final SupabaseClient client;
  static const projection =
      'id,slug,content_type,title,summary,source_url,published_at,source_updated_at,feed_updated_at,thumbnail_url,is_active';
  int _limit(int limit) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', '1..100');
    }
    return limit;
  }

  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async {
    final rows = await client
        .from('content_items')
        .select(projection)
        .eq('is_active', true)
        .order('feed_updated_at', ascending: false, nullsFirst: false)
        .order('id', ascending: false)
        .limit(_limit(limit));
    return rows.map(ContentItem.fromJson).toList();
  }

  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
  }) async {
    _limit(limit);
    final text = query.trim();
    if (text.isEmpty) return [];
    // PostgREST interprets * as a LIKE wildcard even inside quoted strings.
    if (text.length > 200 || text.contains('*')) {
      throw const FormatException('검색어는 200자 이내로 입력하고 * 문자는 제외해 주세요.');
    }
    final tokens = text.split(RegExp(r'\s+'));
    if (tokens.length > 8) throw const FormatException('검색어는 8단어 이내로 입력해 주세요.');
    var request = client
        .from('content_items')
        .select(projection)
        .eq('is_active', true);
    for (final token in tokens) {
      final literal = token
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      // Quoting escapes PostgREST grammar delimiters, quotes and backslashes.
      final pattern = jsonEncode('%$literal%');
      request = request.or('title.ilike.$pattern,summary.ilike.$pattern');
    }
    final rows = await request
        .order('feed_updated_at', ascending: false, nullsFirst: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows.map(ContentItem.fromJson).toList();
  }

  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async {
    final row = await client
        .from('content_items')
        .select(projection)
        .eq('is_active', true)
        .eq('slug', slug)
        .maybeSingle();
    return row == null ? null : ContentItem.fromJson(row);
  }
}
