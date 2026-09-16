import 'personal_models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile();
  Future<void> updateSchoolSelection({String? officeCode, String? schoolCode});
  Future<void> upsertCurrentProfile({String? displayName, int? gradeLevel});
}

abstract interface class BookmarkRepository {
  Future<List<PersonalContentEntry>> fetchOwnBookmarks();
  Future<void> addBookmark(String contentItemId);
  Future<void> deleteBookmark(String contentItemId);
  Future<bool> isBookmarked(String contentItemId);
}

abstract interface class RecentViewRepository {
  Future<List<PersonalContentEntry>> fetchOwnRecentViews({int limit = 100});
  Future<void> touchRecentView(String contentItemId);
}
