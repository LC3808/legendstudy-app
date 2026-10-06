import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Desired major / interest field = exploratory personalization, **not** an
/// application major. Stored in a single additive `profiles.intended_major`
/// text column (null = undecided / not set). Kept DECOUPLED from the core
/// profile projection so a deploy that lands before the migration can never
/// break the main profile fetch: reads degrade to null and writes surface a
/// retryable error until the column exists.
///
/// Minimal, future-expandable taxonomy: broad interest fields + an explicit
/// "undecided". No large department catalog is introduced for this release.
const List<String> interestFieldOptions = <String>[
  '인문·어학',
  '사회·상경',
  '자연·이학',
  '공학',
  '의약·보건',
  '교육',
  '예체능',
  '자유전공·융합',
];

abstract class IntendedMajorRepository {
  /// Returns the stored interest field, or null when undecided / unset / the
  /// column is not present yet (fail safe).
  Future<String?> fetch();

  /// null clears it (undecided / unset).
  Future<void> set(String? value);
}

class SupabaseIntendedMajorRepository implements IntendedMajorRepository {
  const SupabaseIntendedMajorRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<String?> fetch() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('profiles')
          .select('intended_major')
          .eq('id', uid)
          .maybeSingle();
      return row?['intended_major'] as String?;
    } catch (_) {
      // Column not present yet (pre-migration) or transient error → unset.
      return null;
    }
  }

  @override
  Future<void> set(String? value) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const SignedOutException();
    await _client.from('profiles').upsert({
      'id': uid,
      'intended_major': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

final intendedMajorRepositoryProvider = Provider<IntendedMajorRepository?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseIntendedMajorRepository(client);
});

/// Current desired-major value (null = undecided/unset). Fail-safe.
final intendedMajorProvider = FutureProvider.autoDispose<String?>((ref) async {
  final auth = ref.watch(authStateProvider).asData?.value;
  final repo = ref.watch(intendedMajorRepositoryProvider);
  if (repo == null || auth == null || !auth.isAuthenticated) return null;
  return repo.fetch();
});
