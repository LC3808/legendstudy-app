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
    final userId = backend.auth.currentUser?.id;
    await backend.from('feedback_submissions').insert({
      if (userId != null) 'user_id': userId,
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
}
