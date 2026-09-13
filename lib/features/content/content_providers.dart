import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_content_repository.dart';
import 'domain/content_repository.dart';
import 'domain/content_item.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? _UnavailableContentRepository(
          ref.watch(backendIssueProvider) ?? '서버 연결을 초기화하지 못했습니다.',
        )
      : SupabaseContentRepository(client);
});
final recentContentProvider = FutureProvider<List<ContentItem>>(
  (ref) => ref.watch(contentRepositoryProvider).fetchRecentContent(),
  retry: (_, _) => null,
);
final contentSearchProvider = FutureProvider.autoDispose
    .family<List<ContentItem>, String>((ref, query) {
      if (query.trim().isEmpty) return Future.value([]);
      return ref.watch(contentRepositoryProvider).searchContent(query);
    }, retry: (_, _) => null);

class _UnavailableContentRepository implements ContentRepository {
  const _UnavailableContentRepository(this.message);
  final String message;
  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async =>
      throw BackendUnavailable(message);
  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) async => throw BackendUnavailable(message);
  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async =>
      throw BackendUnavailable(message);
}

typedef ContentFilter = ({String query, String? contentType});
final filteredContentProvider = FutureProvider.autoDispose
    .family<List<ContentItem>, ContentFilter>(
      (ref, filter) => filter.contentType == null
          ? ref.watch(contentSearchProvider(filter.query).future)
          : ref
                .watch(contentRepositoryProvider)
                .searchContent(filter.query, contentType: filter.contentType),
      retry: (_, _) => null,
    );
