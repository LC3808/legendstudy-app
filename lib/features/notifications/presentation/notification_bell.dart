import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../application/notification_providers.dart';

/// Home bell. The unread badge is the server-authoritative count (never counted
/// locally); signed-out shows a plain bell that routes to sign-in.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).asData?.value;
    final signedIn = auth?.isAuthenticated == true;
    final count = signedIn
        ? (ref.watch(unreadNotificationCountProvider).asData?.value ?? 0)
        : 0;
    final label = count > 0 ? '알림, 안 읽음 $count개' : '알림';

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: '알림',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          onTap: () {
            if (signedIn) {
              context.push('/notifications');
            } else {
              context.go('/auth');
            }
          },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTokens.textSecondary,
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: AppTokens.danger,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(color: AppTokens.surface, width: 1.5),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
