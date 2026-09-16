import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_feedback_repository.dart';
import 'domain/feedback_models.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => SupabaseFeedbackRepository(ref.watch(supabaseClientProvider)),
);
