import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_resource_repository.dart';
import 'domain/resource_repository.dart';
import 'domain/content_resource.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw BackendUnavailable(
      ref.watch(backendIssueProvider) ?? '서버에 연결하지 못했어요.',
    );
  }
  return SupabaseResourceRepository(client);
}, retry: (_, _) => null);
final contentResourcesProvider = FutureProvider.autoDispose
    .family<List<ContentResource>, String>(
      (ref, id) => ref.watch(resourceRepositoryProvider).fetchForContent(id),
      retry: (_, _) => null,
    );
