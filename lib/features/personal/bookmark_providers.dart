import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'personal_providers.dart';
import 'personal_list_providers.dart';

enum BookmarkPhase { loading, saved, unsaved, mutating, failure }

class BookmarkState {
  const BookmarkState({
    required this.phase,
    this.message,
    this.optimisticSaved = false,
  });
  const BookmarkState.loading() : this(phase: BookmarkPhase.loading);
  final BookmarkPhase phase;
  final String? message;
  final bool optimisticSaved;
  bool get isSaved =>
      phase == BookmarkPhase.saved || (isMutating && optimisticSaved);
  bool get isMutating => phase == BookmarkPhase.mutating;
}

// Detail and list observe the same owner-scoped state. Requests registered in
// one build turn are coalesced, never one isBookmarked request per result tile.
final bookmarkStoreProvider =
    NotifierProvider.autoDispose<BookmarkStore, Map<String, BookmarkState>>(
      BookmarkStore.new,
    );
final bookmarkStateProvider = NotifierProvider.autoDispose
    .family<BookmarkController, BookmarkState, String>(BookmarkController.new);

class BookmarkController extends Notifier<BookmarkState> {
  BookmarkController(this.contentItemId);
  final String contentItemId;
  @override
  BookmarkState build() {
    final auth = ref.watch(authStateProvider);
    final value = ref.watch(
      bookmarkStoreProvider.select((s) => s[contentItemId]),
    );
    if (auth.isLoading) return const BookmarkState.loading();
    if (auth.hasError) {
      return const BookmarkState(
        phase: BookmarkPhase.failure,
        message: '계정 상태를 확인하지 못했어요.',
      );
    }
    if (auth.value?.userId == null) {
      return const BookmarkState(phase: BookmarkPhase.unsaved);
    }
    if (value != null) return value;
    scheduleMicrotask(() {
      if (ref.mounted) {
        ref.read(bookmarkStoreProvider.notifier).ensure(contentItemId);
      }
    });
    return const BookmarkState.loading();
  }

  Future<void> toggle() =>
      ref.read(bookmarkStoreProvider.notifier).toggle(contentItemId);
}

class BookmarkStore extends Notifier<Map<String, BookmarkState>> {
  int _generation = 0;
  final _queued = <String>{};
  bool _scheduled = false;
  @override
  Map<String, BookmarkState> build() {
    ref.watch(
      authStateProvider.select(
        (auth) => (
          owner: auth.value?.userId,
          loading: auth.isLoading,
          error: auth.hasError,
        ),
      ),
    );
    _generation++;
    _queued.clear();
    _scheduled = false;
    return {};
  }

  bool _current(int generation, String? owner) =>
      ref.mounted &&
      generation == _generation &&
      ref.read(authStateProvider).value?.userId == owner;
  void _put(String id, BookmarkState value) => state = {...state, id: value};

  void ensure(String id) {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading ||
        auth.hasError ||
        auth.value?.userId == null ||
        state.containsKey(id)) {
      return;
    }
    _put(id, const BookmarkState.loading());
    _queued.add(id);
    if (_scheduled) return;
    _scheduled = true;
    final generation = _generation;
    scheduleMicrotask(() {
      if (!ref.mounted || generation != _generation) return;
      _scheduled = false;
      final ids = _queued.toList();
      _queued.clear();
      unawaited(_load(ids, generation, auth.value!.userId!));
    });
  }

  Future<void> _load(List<String> ids, int generation, String owner) async {
    final keep = ref.keepAlive();
    final repository = ref.read(bookmarkRepositoryProvider);
    try {
      for (var offset = 0; offset < ids.length; offset += 100) {
        if (!_current(generation, owner)) return;
        final batch = ids.skip(offset).take(100).toList();
        try {
          final saved = await repository.fetchBookmarkedIds(batch);
          if (!_current(generation, owner)) return;
          state = {
            ...state,
            for (final id in batch)
              id: BookmarkState(
                phase: saved.contains(id)
                    ? BookmarkPhase.saved
                    : BookmarkPhase.unsaved,
              ),
          };
        } catch (_) {
          if (!_current(generation, owner)) return;
          state = {
            ...state,
            for (final id in batch)
              id: const BookmarkState(
                phase: BookmarkPhase.failure,
                message: '저장 상태를 불러오지 못했어요. 다시 시도해 주세요.',
              ),
          };
        }
      }
    } finally {
      keep.close();
    }
  }

  Future<void> toggle(String id) async {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading || auth.hasError || auth.value?.userId == null) return;
    final before = state[id];
    if (before == null ||
        before.isMutating ||
        before.phase == BookmarkPhase.loading) {
      return;
    }
    if (before.phase == BookmarkPhase.failure) {
      state = {...state}..remove(id);
      ensure(id);
      return;
    }
    final generation = _generation;
    final owner = auth.value!.userId;
    // Keep an in-flight operation shared even if its last tile is disposed.
    final keep = ref.keepAlive();
    _put(
      id,
      BookmarkState(
        phase: BookmarkPhase.mutating,
        optimisticSaved: !before.isSaved,
      ),
    );
    try {
      final repository = ref.read(bookmarkRepositoryProvider);
      if (before.isSaved) {
        await repository.deleteBookmark(id);
      } else {
        await repository.addBookmark(id);
      }
      if (!_current(generation, owner)) return;
      _put(
        id,
        BookmarkState(
          phase: before.isSaved ? BookmarkPhase.unsaved : BookmarkPhase.saved,
        ),
      );
      ref.invalidate(personalMaterialListProvider(PersonalListKind.bookmarks));
    } catch (_) {
      if (!_current(generation, owner)) return;
      _put(
        id,
        BookmarkState(
          phase: before.isSaved ? BookmarkPhase.saved : BookmarkPhase.unsaved,
          message: '저장 변경을 완료하지 못했어요. 다시 시도해 주세요.',
        ),
      );
    } finally {
      keep.close();
    }
  }
}
