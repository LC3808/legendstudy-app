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
    return await repo.unreadCount();
  } catch (_) {
    return 0;
  }
});

final notificationFeedProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationFeedController,
      NotificationFeed
    >(NotificationFeedController.new);

class NotificationFeedController extends AsyncNotifier<NotificationFeed> {
  @override
  Future<NotificationFeed> build() async {
    final auth = ref.watch(authStateProvider).asData?.value;
    final repo = ref.watch(notificationRepositoryProvider);
    if (repo == null || auth == null || !auth.isAuthenticated) {
      return NotificationFeed.empty;
    }
    return repo.list(limit: 50);
  }

  /// Marks one notification read on the server (the shared read state), then
  /// reflects it locally for immediate feedback. The server value still wins on
  /// the next reload. No-op (keeps unread) when the server rejects ownership.
  Future<void> markRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    if (repo == null) return;
    final ok = await repo.markRead(id);
    if (!ok) return;
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
    await repo.markAllRead();
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

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(unreadNotificationCountProvider);
  }
}
