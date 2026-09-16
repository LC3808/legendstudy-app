enum FeedbackCategory { inquiry, bug, suggestion, other }

extension FeedbackCategoryLabel on FeedbackCategory {
  String get label => switch (this) {
    FeedbackCategory.inquiry => '문의',
    FeedbackCategory.bug => '오류 신고',
    FeedbackCategory.suggestion => '기능 제안',
    FeedbackCategory.other => '기타',
  };
  String get value => name;
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

abstract interface class FeedbackRepository {
  Future<void> submit(FeedbackDraft draft);
}
