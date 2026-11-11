import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';

/// Server-authoritative unread count for the home bell badge. Returns 0 when
/// signed out or unavailable — the badge must never block the home screen and
/// is never counted locally (a stale local count would lie across devices).
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final auth = ref.watch(authStateProvider).asData?.value;
  final repo = ref.watch(notificationRepositoryProvider);
  if (repo == null || auth == null || !auth.isAuthenticated) return 0;
  try {
    return await repo.unreadCount().timeout(notificationRequestTimeout);
  } catch (_) {
    return 0;
  }
});

final notificationFeedProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationFeedController,
      NotificationFeed
    >(NotificationFeedController.new, retry: (_, _) => null);

class NotificationFeedController extends AsyncNotifier<NotificationFeed> {
  Future<void>? _refreshing;

  @override
  Future<NotificationFeed> build() async {
    final repo = ref.watch(notificationRepositoryProvider);
    // One async dependency avoids issuing a second request as initial Auth
    // resolves. Identity-preserving token refreshes do not reload the inbox.
    final auth = await ref
        .watch(
          authStateProvider.selectAsync(
            (status) => (status.userId, status.failure),
          ),
        )
        .timeout(notificationRequestTimeout);
    if (!ref.mounted) throw const BackendUnavailable('Request superseded');
    if (auth.$2 != null) {
      throw const BackendUnavailable('Authentication unavailable');
    }
    if (auth.$1 == null) throw const SignedOutException();
    if (repo == null) {
      throw const BackendUnavailable('Notifications unavailable');
    }
    // A deadline is an error, never evidence of an empty inbox. Riverpod discards
    // late results from invalidated/disposed builds (including account switches).
    return repo.list(limit: 50).timeout(notificationRequestTimeout);
  }

  String? get _owner {
    final auth = ref.read(authStateProvider);
    return auth.isLoading || auth.hasError ? null : auth.value?.userId;
  }

  /// Marks one notification read on the server (the shared read state), then
  /// reflects it locally for immediate feedback. The server value still wins on
  /// the next reload. No-op (keeps unread) when the server rejects ownership.
  Future<void> markRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    if (repo == null) return;
    final owner = _owner;
    if (owner == null) return;
    bool ok;
    try {
      ok = await repo.markRead(id).timeout(notificationRequestTimeout);
    } catch (_) {
      return;
    }
    if (!ref.mounted || _owner != owner || !ok) return;
    final current = state.asData?.value;
    if (current != null) {
      final items = [
        for (final n in current.items)
          n.id == id ? n.copyWith(isRead: true) : n,
      ];
      state = AsyncData(
        NotificationFeed(
          items: items,
          unread: items.where((n) => !n.isRead).length,
          limit: current.limit,
          offset: current.offset,
        ),
      );
    }
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    if (repo == null) return;
    final owner = _owner;
    if (owner == null) return;
    try {
      await repo.markAllRead().timeout(notificationRequestTimeout);
    } catch (_) {
      return;
    }
    if (!ref.mounted || _owner != owner) return;
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        NotificationFeed(
          items: [for (final n in current.items) n.copyWith(isRead: true)],
          unread: 0,
          limit: current.limit,
          offset: current.offset,
        ),
      );
    }
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> refresh() {
    if (_refreshing != null) return _refreshing!;
    if (state.isLoading) {
      return future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    }
    return _refreshing = _reload();
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The provider owns the error UI; a button callback must not rethrow it.
    } finally {
      _refreshing = null;
      if (ref.mounted) ref.invalidate(unreadNotificationCountProvider);
    }
  }
}
