import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_search_repository.dart';
import '../domain/search_models.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? _UnavailableSearchRepository()
      : SupabaseSearchRepository(client);
});

class _UnavailableSearchRepository implements SearchRepository {
  @override
  Future<SearchPage> search(SearchQuery query, {int offset = 0}) async =>
      throw const BackendUnavailable('자료를 불러올 수 없어요.');
  @override
  Future<SearchFacets> facets({int offset = 0}) async =>
      throw const BackendUnavailable('필터를 불러올 수 없어요.');
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchResultState>(SearchController.new);

class SearchController extends Notifier<SearchResultState> {
  int _generation = 0;
  SearchQuery query = SearchQuery('');
  @override
  SearchResultState build() => const SearchResultState();

  Future<void> search(SearchQuery next) async {
    query = next;
    final generation = ++_generation;
    state = const SearchResultState();
    try {
      final page = await ref.read(searchRepositoryProvider).search(next);
      if (!ref.mounted || generation != _generation) return;
      state = SearchResultState(
        phase: page.items.isEmpty
            ? (next.isBrowse ? SearchPhase.empty : SearchPhase.noResults)
            : SearchPhase.data,
        items: page.items,
        nextOffset: page.nextOffset,
      );
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = const SearchResultState(phase: SearchPhase.error);
      }
    }
  }

  Future<void> retry() => search(query);
  Future<void> loadMore() async {
    if (state.loadingMore || state.nextOffset == null) return;
    final before = state;
    final generation = _generation;
    state = SearchResultState(
      phase: before.phase,
      items: before.items,
      nextOffset: before.nextOffset,
      loadingMore: true,
    );
    try {
      final page = await ref
          .read(searchRepositoryProvider)
          .search(query, offset: before.nextOffset!);
      if (!ref.mounted || generation != _generation) return;
      state = SearchResultState(
        phase: SearchPhase.data,
        items: {
          for (final item in [...before.items, ...page.items])
            item.content.id: item,
        }.values.toList(),
        nextOffset: page.nextOffset,
      );
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = SearchResultState(
          phase: before.phase,
          items: before.items,
          nextOffset: before.nextOffset,
          moreFailed: true,
        );
      }
    }
  }
}
