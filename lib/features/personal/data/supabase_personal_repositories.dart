import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/personal_models.dart';
import '../domain/personal_repositories.dart';

// Resolve identity at each call. No caller-supplied user IDs or cached identities.
abstract class _PersonalRepository {
  _PersonalRepository(this.client);
  final SupabaseClient? client;
  String? get userId => client?.auth.currentUser?.id;
  String requireUser() => userId ?? (throw const SignedOutException());
}

class SupabaseProfileRepository extends _PersonalRepository
    implements ProfileRepository {
  SupabaseProfileRepository(super.client);
  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    final owner = userId;
    if (owner == null) return null;
    final row = await client!
        .from('profiles')
        .select('id,display_name,grade_level,neis_office_code,neis_school_code')
        .eq('id', owner)
        .maybeSingle();
    return row == null ? null : UserProfile.fromJson(row);
  }

  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {
    final owner = requireUser();
    if ((officeCode == null) != (schoolCode == null)) {
      throw const FormatException('Both school identifiers are required.');
    }
    for (final code in [officeCode, schoolCode]) {
      if (code != null &&
          (code.trim() != code || code.isEmpty || code.length > 32)) {
        throw const FormatException('Invalid school identifier.');
      }
    }
    // Omit name/grade so school-only upserts preserve existing profile fields.
    await client!.from('profiles').upsert({
      'id': owner,
      'neis_office_code': officeCode,
      'neis_school_code': schoolCode,
    }, onConflict: 'id');
  }

  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
  }) async {
    final owner = requireUser();
    if (gradeLevel != null && ![1, 2, 3].contains(gradeLevel)) {
      throw const FormatException('Unsupported grade.');
    }
    await client!.from('profiles').upsert({
      'id': owner,
      if (displayName != null) 'display_name': displayName,
      if (gradeLevel != null) 'grade_level': gradeLevel,
    }, onConflict: 'id');
  }
}

class SupabaseBookmarkRepository extends _PersonalRepository
    implements BookmarkRepository {
  SupabaseBookmarkRepository(super.client);
  @override
  Future<List<PersonalContentEntry>> fetchOwnBookmarks() async {
    final owner = userId;
    if (owner == null) return [];
    final rows = await client!
        .from('bookmarks')
        .select('id,content_item_id,created_at')
        .eq('user_id', owner)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(100);
    return rows
        .map((row) => PersonalContentEntry.fromJson(row, 'created_at'))
        .toList();
  }

  @override
  Future<void> addBookmark(String contentItemId) async {
    final owner = requireUser();
    await client!
        .from('bookmarks')
        .upsert(
          {'user_id': owner, 'content_item_id': contentItemId},
          onConflict: 'user_id,content_item_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> deleteBookmark(String contentItemId) async {
    final owner = requireUser();
    await client!
        .from('bookmarks')
        .delete()
        .eq('user_id', owner)
        .eq('content_item_id', contentItemId);
  }

  @override
  Future<Set<String>> fetchBookmarkedIds(List<String> contentItemIds) async {
    final ids = contentItemIds.toSet().toList();
    if (ids.length > 100) {
      throw ArgumentError('Bookmark batch exceeds 100 IDs.');
    }
    final owner = userId;
    if (owner == null || ids.isEmpty) return {};
    final rows = await client!
        .from('bookmarks')
        .select('content_item_id')
        .eq('user_id', owner)
        .inFilter('content_item_id', ids)
        .limit(100);
    return rows.map((row) => row['content_item_id'] as String).toSet();
  }

  @override
  Future<bool> isBookmarked(String contentItemId) async {
    final owner = userId;
    if (owner == null) return false;
    final row = await client!
        .from('bookmarks')
        .select('id')
        .eq('user_id', owner)
        .eq('content_item_id', contentItemId)
        .maybeSingle();
    return row != null;
  }
}

class SupabaseRecentViewRepository extends _PersonalRepository
    implements RecentViewRepository {
  SupabaseRecentViewRepository(super.client);
  @override
  Future<List<PersonalContentEntry>> fetchOwnRecentViews({
    int limit = 100,
  }) async {
    final owner = userId;
    if (owner == null) return [];
    final rows = await client!
        .from('recent_views')
        .select('id,content_item_id,viewed_at')
        .eq('user_id', owner)
        .order('viewed_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows
        .map((row) => PersonalContentEntry.fromJson(row, 'viewed_at'))
        .toList();
  }

  @override
  Future<void> touchRecentView(String contentItemId) async {
    final owner = requireUser();
    await client!.from('recent_views').upsert({
      'user_id': owner,
      'content_item_id': contentItemId,
    }, onConflict: 'user_id,content_item_id');
  }

  @override
  Future<void> deleteRecentView(String contentItemId) async {
    final owner = requireUser();
    await client!
        .from('recent_views')
        .delete()
        .eq('user_id', owner)
        .eq('content_item_id', contentItemId);
  }

  @override
  Future<void> deleteAllRecentViews() async {
    final owner = requireUser();
    await client!.from('recent_views').delete().eq('user_id', owner);
  }
}
