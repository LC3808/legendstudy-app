import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_personal_repositories.dart';
import 'domain/personal_repositories.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);
final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => SupabaseBookmarkRepository(ref.watch(supabaseClientProvider)),
);
final recentViewRepositoryProvider = Provider<RecentViewRepository>(
  (ref) => SupabaseRecentViewRepository(ref.watch(supabaseClientProvider)),
);
