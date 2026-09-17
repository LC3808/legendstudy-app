import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/feedback_models.dart';

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository(this.client);
  final SupabaseClient? client;

  @override
  Future<void> submit(FeedbackDraft draft) async {
    final backend = client;
    if (backend == null) {
      throw const BackendUnavailable('문의 서버가 준비되지 않았어요.');
    }
    await backend.from('feedback_submissions').insert({
      'category': draft.category.value,
      'title': draft.title.trim(),
      'body': draft.body.trim(),
      'app_version': draft.appVersion,
      'build_number': draft.buildNumber,
      'platform': draft.platform,
      'os_version': draft.osVersion,
      if (draft.locale != null) 'locale': draft.locale,
    });
  }

  @override
  Future<bool> isAdmin() async {
    final backend = client;
    if (backend == null) throw const BackendUnavailable('관리자 상태를 확인할 수 없어요.');
    final result = await backend.rpc<bool>('is_feedback_admin');
    return result == true;
  }

  @override
  Future<List<FeedbackSubmission>> fetchAdminFeedback({
    FeedbackStatus? status,
    int limit = 50,
  }) async {
    final backend = client;
    if (backend == null) throw const BackendUnavailable('문의 목록을 불러올 수 없어요.');
    var query = backend.from('feedback_submissions').select();
    if (status != null) query = query.eq('status', status.value);
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return [
      for (final row in rows)
        FeedbackSubmission.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<FeedbackSubmission> fetchAdminFeedbackById(String id) async {
    final backend = client;
    if (backend == null) throw const BackendUnavailable('문의 내용을 불러올 수 없어요.');
    final row = await backend
        .from('feedback_submissions')
        .select()
        .eq('id', id)
        .single();
    return FeedbackSubmission.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<FeedbackSubmission> updateFeedbackStatus(
    String id,
    FeedbackStatus status,
  ) async {
    final backend = client;
    if (backend == null) throw const BackendUnavailable('문의 상태를 변경할 수 없어요.');
    final row = await backend
        .from('feedback_submissions')
        .update({'status': status.value})
        .eq('id', id)
        .select()
        .single();
    return FeedbackSubmission.fromJson(Map<String, dynamic>.from(row));
  }
}
