import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../application/notification_providers.dart';
import '../domain/notification_models.dart';

/// In-app notification inbox. Read state is shared with LAB web through the
/// server; the app only renders and marks read.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationFeedProvider);
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _Centered(
        children: [
          const Text('알림을 불러오지 못했어요.', style: AppTokens.body),
          const SizedBox(height: AppTokens.space12),
          OutlinedButton(
            onPressed: () => ref.read(notificationFeedProvider.notifier).refresh(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const _Centered(
            children: [
              Icon(
                Icons.notifications_none,
                size: 40,
                color: AppTokens.textTertiary,
              ),
              SizedBox(height: AppTokens.space12),
              Text('받은 알림이 없어요.', style: AppTokens.secondary),
            ],
          );
        }
        final hasUnread = data.items.any((n) => !n.isRead);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationFeedProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
            children: [
              if (hasUnread)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space16,
                    AppTokens.space4,
                    AppTokens.space8,
                    AppTokens.space4,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => ref
                          .read(notificationFeedProvider.notifier)
                          .markAllRead(),
                      child: const Text('모두 읽음'),
                    ),
                  ),
                ),
              for (final item in data.items)
                _NotificationTile(
                  item: item,
                  onTap: () => _openNotification(context, ref, item),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    UserNotification item,
  ) async {
    // Read is recorded on tap (not on render), per the shared-center contract.
    await ref.read(notificationFeedProvider.notifier).markRead(item.id);
    final route = item.target.route;
    if (route == null) return; // unknown/unsupported target → fail safe, no nav
    if (!context.mounted) return;
    context.go(route);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final UserNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? AppTokens.primarySoft.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: AppTokens.space12),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: unread ? AppTokens.danger : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isEmpty ? '알림' : item.title,
                    style: AppTokens.body.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.body, style: AppTokens.secondary),
                  ],
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    _relativeTime(item.createdAt),
                    style: AppTokens.caption.copyWith(
                      color: AppTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.target.canNavigate)
              const Padding(
                padding: EdgeInsets.only(left: AppTokens.space8),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTokens.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    ),
  );
}

String _relativeTime(DateTime? at) {
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.year}.${two(at.month)}.${two(at.day)}';
}
