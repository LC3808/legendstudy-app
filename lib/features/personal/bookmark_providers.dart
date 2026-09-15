import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'personal_providers.dart';

enum BookmarkPhase { loading, saved, unsaved, mutating, failure }

class BookmarkState {
  const BookmarkState({required this.phase, this.message});
  const BookmarkState.loading() : this(phase: BookmarkPhase.loading);
  final BookmarkPhase phase;
  final String? message;
  bool get isSaved => phase == BookmarkPhase.saved;
  bool get isMutating => phase == BookmarkPhase.mutating;
}

final bookmarkStateProvider = NotifierProvider.autoDispose
    .family<BookmarkController, BookmarkState, String>(BookmarkController.new);

class BookmarkController extends Notifier<BookmarkState> {
  BookmarkController(this.contentItemId);
  final String contentItemId;
  int _generation = 0;
  bool _mutating = false;

  @override
  BookmarkState build() {
    final generation = ++_generation;
    _mutating = false;
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return const BookmarkState.loading();
    if (auth.hasError) {
      return const BookmarkState(
        phase: BookmarkPhase.failure,
        message: '계정 상태를 확인하지 못했어요.',
      );
    }
    if (auth.value?.userId == null) return const BookmarkState(phase: BookmarkPhase.unsaved);
    _load(contentItemId, generation);
    return const BookmarkState.loading();
  }

  Future<void> _load(String contentItemId, int generation) async {
    try {
      final saved = await ref.read(bookmarkRepositoryProvider).isBookmarked(contentItemId);
      if (!ref.mounted || generation != _generation) return;
      state = BookmarkState(phase: saved ? BookmarkPhase.saved : BookmarkPhase.unsaved);
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = const BookmarkState(
        phase: BookmarkPhase.failure,
        message: '저장 상태를 불러오지 못했어요.',
      );
    }
  }

  Future<void> toggle() async {
    if (_mutating || state.phase == BookmarkPhase.loading) return;
    if (state.phase == BookmarkPhase.failure) {
      _load(contentItemId, _generation);
      return;
    }
    final auth = ref.read(authStateProvider);
    if (auth.value?.userId == null) return;
    final owner = auth.value!.userId;
    final wasSaved = state.isSaved;
    final generation = _generation;
    _mutating = true;
    state = BookmarkState(phase: BookmarkPhase.mutating);
    try {
      final repository = ref.read(bookmarkRepositoryProvider);
      if (wasSaved) {
        await repository.deleteBookmark(contentItemId);
      } else {
        await repository.addBookmark(contentItemId);
      }
      if (!ref.mounted || generation != _generation || ref.read(authStateProvider).value?.userId != owner) return;
      state = BookmarkState(phase: wasSaved ? BookmarkPhase.unsaved : BookmarkPhase.saved);
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = BookmarkState(
        phase: wasSaved ? BookmarkPhase.saved : BookmarkPhase.unsaved,
        message: '저장하지 못했습니다. 다시 시도해 주세요.',
      );
    } finally {
      if (ref.mounted && generation == _generation) _mutating = false;
    }
  }
}
