import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_exam_repository.dart';
import 'domain/exam_repository.dart';
import 'domain/exam_metadata.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw BackendUnavailable(
      ref.watch(backendIssueProvider) ?? '서버에 연결하지 못했어요.',
    );
  }
  return SupabaseExamRepository(client);
}, retry: (_, _) => null);
// A comma-separated page of UUIDs is a stable family key (no list identity churn).
// Batch one exam request per parent page, rather than one request per card.
final examMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, ExamMetadata>, String>(
      (ref, ids) => ids.isEmpty
          ? Future.value({})
          : ref
                .watch(examRepositoryProvider)
                .fetchForContentIds(ids.split(',')),
      retry: (_, _) => null,
    );
