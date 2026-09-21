import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_personal_repositories.dart';
import 'domain/personal_repositories.dart';
import 'domain/personal_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);
final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => SupabaseBookmarkRepository(ref.watch(supabaseClientProvider)),
);
final recentViewRepositoryProvider = Provider<RecentViewRepository>(
  (ref) => SupabaseRecentViewRepository(ref.watch(supabaseClientProvider)),
);

// Refetch on owner transitions; never reuse another account's profile.
final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return null;
  if (auth.hasError) throw StateError('Account unavailable');
  final owner = auth.value?.userId;
  if (owner == null) return null;
  final profile = await ref
      .watch(profileRepositoryProvider)
      .fetchCurrentProfile();
  if (profile != null && profile.id != owner) {
    throw StateError('Profile owner mismatch');
  }
  return profile;
});
