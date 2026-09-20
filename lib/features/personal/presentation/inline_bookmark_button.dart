import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../bookmark_providers.dart';

class InlineBookmarkButton extends ConsumerStatefulWidget {
  const InlineBookmarkButton({required this.contentItemId, super.key});
  final String contentItemId;
  @override
  ConsumerState<InlineBookmarkButton> createState() =>
      _InlineBookmarkButtonState();
}

class _InlineBookmarkButtonState extends ConsumerState<InlineBookmarkButton> {
  bool routing = false;
  Future<void> act() async {
    if (routing) return;
    FocusScope.of(context).unfocus();
    final owner = ref.read(authStateProvider).value?.userId;
    if (owner == null) {
      setState(() => routing = true);
      try {
        final login = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('자료 저장'),
            content: const Text('자료를 저장하려면 로그인해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('로그인'),
              ),
            ],
          ),
        );
        if (login == true && mounted) await context.push('/auth');
        // Preserve the mounted search route; never auto-save after login.
      } finally {
        if (mounted) setState(() => routing = false);
      }
      return;
    }
    final id = widget.contentItemId;
    await ref.read(bookmarkStateProvider(id).notifier).toggle();
    if (!mounted || ref.read(authStateProvider).value?.userId != owner) return;
    final message = ref.read(bookmarkStateProvider(id)).message;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final state = ref.watch(bookmarkStateProvider(widget.contentItemId));
    final busy =
        state.isMutating || state.phase == BookmarkPhase.loading || routing;
    final label = state.phase == BookmarkPhase.loading
        ? '저장 상태 불러오는 중'
        : state.isMutating
        ? (state.isSaved ? '저장 중' : '저장 해제 중')
        : auth.value?.userId == null
        ? '자료 저장, 로그인 필요'
        : state.phase == BookmarkPhase.failure
        ? '저장 상태 다시 불러오기'
        : state.isSaved
        ? '저장 해제'
        : '자료 저장';
    return Semantics(
      selected: state.isSaved,
      child: IconButton(
        key: ValueKey('bookmark-${widget.contentItemId}'),
        tooltip: label,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: busy || auth.hasError ? null : act,
        icon: Icon(
          state.phase == BookmarkPhase.loading
              ? Icons.more_horiz
              : state.phase == BookmarkPhase.failure
              ? Icons.refresh
              : state.isSaved
              ? Icons.bookmark
              : Icons.bookmark_border,
        ),
      ),
    );
  }
}
