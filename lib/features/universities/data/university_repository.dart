import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/university_models.dart';

/// Reads the public `universities` catalog and manages the signed-in user's
/// **interested** universities in `student_target_universities`. No new table,
/// no RPC — the existing owner-scoped RLS (select/insert/update/delete own)
/// covers every call. `status` is always `'interested'`; `source` records where
/// the selection was made (`'onboarding'` / `'my'`).
abstract class UniversityRepository {
  Future<List<University>> searchCatalog(String query, {int limit});
  Future<List<InterestedUniversity>> listInterested();
  Future<void> addInterested(
    String universityId, {
    required String source,
    int? priority,
  });
  Future<void> removeInterested(String rowId);
}

class SupabaseUniversityRepository implements UniversityRepository {
  const SupabaseUniversityRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<University>> searchCatalog(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await _client
        .from('universities')
        .select('id,name,slug')
        .eq('is_active', true)
        .ilike('name', '%$q%')
        .order('name')
        .limit(limit);
    return rows.map(University.fromJson).toList();
  }

  @override
  Future<List<InterestedUniversity>> listInterested() async {
    final rows = await _client
        .from('student_target_universities')
        .select('id,university_id,priority,universities(name,slug)')
        .eq('status', 'interested')
        .order('priority', ascending: true, nullsFirst: false)
        .order('created_at');
    return rows.map(InterestedUniversity.fromJson).toList();
  }

  @override
  Future<void> addInterested(
    String universityId, {
    required String source,
    int? priority,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const SignedOutException();
    await _client.from('student_target_universities').insert({
      'user_id': uid,
      'university_id': universityId,
      'status': 'interested',
      'source': source,
      if (priority != null) 'priority': priority,
    });
  }

  @override
  Future<void> removeInterested(String rowId) async {
    await _client.from('student_target_universities').delete().eq('id', rowId);
  }
}

final universityRepositoryProvider = Provider<UniversityRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseUniversityRepository(client);
});
