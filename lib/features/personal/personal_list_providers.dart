import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import '../content/content_providers.dart';
import '../content/domain/content_item.dart';
import 'domain/personal_models.dart';
import 'personal_providers.dart';

enum PersonalListKind { bookmarks, recentViews }

class PersonalMaterial {
  const PersonalMaterial({required this.entry, required this.item});
  final PersonalContentEntry entry;
  final ContentItem item;
}

final personalMaterialListProvider = AsyncNotifierProvider.autoDispose
    .family<
      PersonalMaterialListController,
      List<PersonalMaterial>,
      PersonalListKind
    >(PersonalMaterialListController.new);

final homeRecentMaterialListProvider =
    AsyncNotifierProvider.autoDispose<
      HomeRecentMaterialListController,
      List<PersonalMaterial>
    >(HomeRecentMaterialListController.new);

class PersonalMaterialListController
    extends AsyncNotifier<List<PersonalMaterial>> {
  PersonalMaterialListController(this.kind);
  final PersonalListKind kind;
  int _generation = 0;

  @override
  Future<List<PersonalMaterial>> build() async {
    final generation = ++_generation;
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return [];
    if (auth.hasError) {
      throw const BackendUnavailable('계정 상태를 확인하지 못했어요.');
    }
    if (auth.value?.userId == null) return [];

    final entries = kind == PersonalListKind.bookmarks
        ? await ref.read(bookmarkRepositoryProvider).fetchOwnBookmarks()
        : await ref.read(recentViewRepositoryProvider).fetchOwnRecentViews();
    return _hydrate(ref, entries, () => generation == _generation);
  }
}

class HomeRecentMaterialListController
    extends AsyncNotifier<List<PersonalMaterial>> {
  int _generation = 0;

  @override
  Future<List<PersonalMaterial>> build() async {
    final generation = ++_generation;
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return [];
    if (auth.hasError) {
      throw const BackendUnavailable('계정 상태를 확인하지 못했어요.');
    }
    if (auth.value?.userId == null) return [];
    final entries = await ref
        .read(recentViewRepositoryProvider)
        .fetchOwnRecentViews(limit: 6);
    return _hydrate(ref, entries, () => generation == _generation);
  }
}

Future<List<PersonalMaterial>> _hydrate(
  Ref ref,
  List<PersonalContentEntry> entries,
  bool Function() isCurrent,
) async {
  if (!ref.mounted || !isCurrent()) return [];
  if (entries.isEmpty) return [];

  final repository = ref.read(contentRepositoryProvider);
  final ids = entries.map((entry) => entry.contentItemId).toList();
  final content = await repository.fetchContentByIds(ids);
  if (!ref.mounted || !isCurrent()) return [];
  final byId = {for (final item in content) item.id: item};
  // Missing/inactive content is intentionally omitted; it is never fetched
  // through a private or inactive path and cannot leak cached content.
  return [
    for (final entry in entries)
      if (byId[entry.contentItemId] case final item?)
        PersonalMaterial(entry: entry, item: item),
  ];
}
