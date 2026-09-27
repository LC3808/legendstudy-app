import 'personal_models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile();
  Future<void> updateSchoolSelection({String? officeCode, String? schoolCode});
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
    bool clearGrade = false,
    String? academicStatus,
    bool clearAcademicStatus = false,
  });

  /// Mark the first-login personalization flow finished (on finish OR skip),
  /// so it never re-prompts. Idempotent.
  Future<void> markOnboardingComplete();
}

abstract interface class BookmarkRepository {
  Future<List<PersonalContentEntry>> fetchOwnBookmarks();
  Future<void> addBookmark(String contentItemId);
  Future<void> deleteBookmark(String contentItemId);
  Future<bool> isBookmarked(String contentItemId);

  /// At most 100 distinct content IDs; result contains only saved IDs.
  Future<Set<String>> fetchBookmarkedIds(List<String> contentItemIds);
}

abstract interface class RecentViewRepository {
  Future<List<PersonalContentEntry>> fetchOwnRecentViews({int limit = 100});
  Future<void> touchRecentView(String contentItemId);
  Future<void> deleteRecentView(String contentItemId);
  Future<void> deleteAllRecentViews();
}
