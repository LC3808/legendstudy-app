import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_feedback_repository.dart';
import 'domain/feedback_models.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => SupabaseFeedbackRepository(ref.watch(supabaseClientProvider)),
);

class AdminAccess {
  const AdminAccess({required this.userId, required this.isAdmin});
  final String? userId;
  final bool isAdmin;
}

final adminAccessProvider = FutureProvider.autoDispose<AdminAccess>((
  ref,
) async {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return const AdminAccess(userId: null, isAdmin: false);
  if (auth.hasError) throw const BackendUnavailable('계정 상태를 확인하지 못했어요.');
  final userId = auth.value?.userId;
  if (userId == null) return const AdminAccess(userId: null, isAdmin: false);
  if (ref.read(supabaseClientProvider) == null) {
    return AdminAccess(userId: userId, isAdmin: false);
  }
  final isAdmin = await ref.read(feedbackRepositoryProvider).isAdmin();
  return AdminAccess(userId: userId, isAdmin: isAdmin);
});

final adminFeedbackListProvider = FutureProvider.autoDispose
    .family<List<FeedbackSubmission>, FeedbackStatus?>((ref, status) async {
      final access = await ref.watch(adminAccessProvider.future);
      if (!access.isAdmin) throw const SignedOutException();
      return ref
          .read(feedbackRepositoryProvider)
          .fetchAdminFeedback(status: status);
    });

final adminFeedbackDetailProvider = FutureProvider.autoDispose
    .family<FeedbackSubmission, String>((ref, id) async {
      final access = await ref.watch(adminAccessProvider.future);
      if (!access.isAdmin) throw const SignedOutException();
      return ref.read(feedbackRepositoryProvider).fetchAdminFeedbackById(id);
    });
