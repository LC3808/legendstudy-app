// Shared notification center — app consumer models (`notification-v1`).
//
// The app is a pure consumer: it never produces notifications, never counts
// unread locally, and never persists a second copy. The server row (shared
// with LAB web) is the single source of truth for read state.

/// Allowlisted target types the app can navigate to. Any value the server adds
/// later arrives as [unknown] and is never turned into navigation — the app
/// never assembles URLs.
enum NotificationTarget {
  inquiry,
  essayEvaluation,
  mathEvaluation,
  paymentOrder,
  creditHistory,
  essayLab,
  unknown;

  static NotificationTarget fromServer(String? raw) {
    switch (raw) {
      case 'inquiry':
        return NotificationTarget.inquiry;
      case 'essay_evaluation':
        return NotificationTarget.essayEvaluation;
      case 'math_evaluation':
        return NotificationTarget.mathEvaluation;
      case 'payment_order':
        return NotificationTarget.paymentOrder;
      case 'credit_history':
        return NotificationTarget.creditHistory;
      case 'essay_lab':
        return NotificationTarget.essayLab;
      default:
        return NotificationTarget.unknown;
    }
  }

  /// Fixed in-app route for this target, or null when the app has no screen for
  /// it (unknown → fail safe, no navigation). In this app the paid/evaluation
  /// surfaces (essay/math results, credit balance, purchases) all live on `/lab`
  /// and 1:1 inquiries on `/my/feedback`; the app never builds a URL from a
  /// server-provided target id.
  String? get route {
    switch (this) {
      case NotificationTarget.inquiry:
        return '/my/feedback';
      case NotificationTarget.essayEvaluation:
      case NotificationTarget.mathEvaluation:
      case NotificationTarget.creditHistory:
      case NotificationTarget.paymentOrder:
      case NotificationTarget.essayLab:
        return '/lab';
      case NotificationTarget.unknown:
        return null;
    }
  }

  bool get canNavigate => route != null;
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.target,
    required this.targetId,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final NotificationTarget target;
  final String? targetId;
  final DateTime? createdAt;
  final bool isRead;

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    final readAt = json['read_at'];
    return UserNotification(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      target: NotificationTarget.fromServer(json['target_type'] as String?),
      targetId: json['target_id'] as String?,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      // Trust the server read state; is_read OR a present read_at means read.
      isRead: json['is_read'] == true || readAt != null,
    );
  }

  UserNotification copyWith({bool? isRead}) => UserNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    target: target,
    targetId: targetId,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

class NotificationFeed {
  const NotificationFeed({
    required this.items,
    required this.unread,
    required this.limit,
    required this.offset,
  });

  final List<UserNotification> items;
  final int unread;
  final int limit;
  final int offset;

  static const NotificationFeed empty = NotificationFeed(
    items: <UserNotification>[],
    unread: 0,
    limit: 0,
    offset: 0,
  );

  factory NotificationFeed.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(UserNotification.fromJson)
              .toList()
        : <UserNotification>[];
    return NotificationFeed(
      items: items,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}
