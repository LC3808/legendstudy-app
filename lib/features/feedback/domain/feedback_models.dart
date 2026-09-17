enum FeedbackCategory { inquiry, bug, suggestion, other }

extension FeedbackCategoryLabel on FeedbackCategory {
  String get label => switch (this) {
    FeedbackCategory.inquiry => '문의',
    FeedbackCategory.bug => '오류 신고',
    FeedbackCategory.suggestion => '기능 제안',
    FeedbackCategory.other => '기타',
  };
  String get value => name;

  static FeedbackCategory fromValue(String value) => switch (value) {
    'inquiry' => FeedbackCategory.inquiry,
    'bug' => FeedbackCategory.bug,
    'suggestion' => FeedbackCategory.suggestion,
    'other' => FeedbackCategory.other,
    _ => throw FormatException('Unknown feedback category'),
  };
}

enum FeedbackStatus { newStatus, reviewing, resolved }

extension FeedbackStatusContract on FeedbackStatus {
  String get value => switch (this) {
    FeedbackStatus.newStatus => 'new',
    FeedbackStatus.reviewing => 'reviewing',
    FeedbackStatus.resolved => 'resolved',
  };
  String get label => switch (this) {
    FeedbackStatus.newStatus => '신규',
    FeedbackStatus.reviewing => '확인중',
    FeedbackStatus.resolved => '처리완료',
  };

  static FeedbackStatus fromValue(String value) => switch (value) {
    'new' => FeedbackStatus.newStatus,
    'reviewing' => FeedbackStatus.reviewing,
    'resolved' => FeedbackStatus.resolved,
    _ => throw FormatException('Unknown feedback status'),
  };
}

class FeedbackDraft {
  const FeedbackDraft({
    required this.category,
    required this.title,
    required this.body,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    this.locale,
  });
  final FeedbackCategory category;
  final String title, body, appVersion, buildNumber, platform, osVersion;
  final String? locale;
}

class FeedbackSubmission {
  const FeedbackSubmission({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.locale,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmission(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      category: FeedbackCategoryLabel.fromValue(json['category'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      appVersion: json['app_version'] as String,
      buildNumber: json['build_number'] as String,
      platform: json['platform'] as String,
      osVersion: json['os_version'] as String,
      locale: json['locale'] as String?,
      status: FeedbackStatusContract.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String? userId;
  final FeedbackCategory category;
  final String title, body, appVersion, buildNumber, platform, osVersion;
  final String? locale;
  final FeedbackStatus status;
  final DateTime createdAt, updatedAt;
}

abstract interface class FeedbackRepository {
  Future<void> submit(FeedbackDraft draft);
  Future<bool> isAdmin();
  Future<List<FeedbackSubmission>> fetchAdminFeedback({
    FeedbackStatus? status,
    int limit = 50,
  });
  Future<FeedbackSubmission> fetchAdminFeedbackById(String id);
  Future<FeedbackSubmission> updateFeedbackStatus(
    String id,
    FeedbackStatus status,
  );
}
