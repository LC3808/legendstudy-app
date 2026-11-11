import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/notification_models.dart';

const notificationRequestTimeout = Duration(seconds: 8);

/// Consumer contract (`notification-v1`). The app calls only these four RPCs
/// with its own session token; it never touches `user_notifications` directly
/// and never calls the producer `notification_private.emit`.
abstract class NotificationApi {
  Future<NotificationFeed> list({int limit, int offset, bool unreadOnly});
  Future<int> unreadCount();

  /// Returns false when the row is not the caller's (server owner check);
  /// idempotent, safe to call twice.
  Future<bool> markRead(String id);
  Future<void> markAllRead();
}

class SupabaseNotificationRepository implements NotificationApi {
  const SupabaseNotificationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<NotificationFeed> list({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final res = await _client
        .rpc<Object?>(
          'user_notifications_list',
          params: {
            'p_limit': limit,
            'p_offset': offset,
            'p_unread_only': unreadOnly,
          },
        )
        .retry(enabled: false);
    // A missing/malformed payload is not an empty inbox. Keep DTO fallback
    // compatibility elsewhere, but enforce the API boundary for this screen.
    if (res is! Map<String, dynamic> ||
        res['dto_version'] != 'notification-v1' ||
        res['items'] is! List ||
        (res['items'] as List).any(
          (item) =>
              item is! Map<String, dynamic> ||
              item['id'] is! String ||
              (item['id'] as String).isEmpty,
        )) {
      throw const FormatException('Invalid notification response');
    }
    return NotificationFeed.fromJson(res);
  }

  @override
  Future<int> unreadCount() async {
    final res = await _client.rpc<int?>('user_notifications_unread_count');
    return res ?? 0;
  }

  @override
  Future<bool> markRead(String id) async {
    final res = await _client.rpc<bool?>(
      'user_notification_mark_read',
      params: {'p_id': id},
    );
    return res == true;
  }

  @override
  Future<void> markAllRead() async {
    await _client.rpc<void>('user_notifications_mark_all_read');
  }
}

/// Null when the backend is not configured (same convention as other repos).
final notificationRepositoryProvider = Provider<NotificationApi?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseNotificationRepository(client);
});
