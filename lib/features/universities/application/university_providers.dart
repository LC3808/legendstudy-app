import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/university_repository.dart';
import '../domain/university_models.dart';

/// Catalog search (public `universities`). Empty query / signed-out / no backend
/// all yield an empty list.
final universitySearchProvider = FutureProvider.autoDispose
    .family<List<University>, String>((ref, query) async {
      final repo = ref.watch(universityRepositoryProvider);
      if (repo == null || query.trim().isEmpty) return const [];
      return repo.searchCatalog(query);
    });

/// The signed-in user's interested universities (server-authoritative list).
final interestedUniversitiesProvider =
    AsyncNotifierProvider.autoDispose<
      InterestedUniversitiesController,
      List<InterestedUniversity>
    >(InterestedUniversitiesController.new);

class InterestedUniversitiesController
    extends AsyncNotifier<List<InterestedUniversity>> {
  @override
  Future<List<InterestedUniversity>> build() async {
    final auth = ref.watch(authStateProvider).asData?.value;
    final repo = ref.watch(universityRepositoryProvider);
    if (repo == null || auth == null || !auth.isAuthenticated) return const [];
    return repo.listInterested();
  }

  List<InterestedUniversity> get _current => state.asData?.value ?? const [];

  bool get canAdd => _current.length < maxInterested;
  bool contains(String universityId) =>
      _current.any((u) => u.universityId == universityId);

  /// Adds one interested university (no-op if already present or at the cap).
  /// [source] is `'onboarding'` or `'my'`. Re-reads to obtain the new row id and
  /// embedded name; the server list stays the source of truth.
  Future<void> add(String universityId, {required String source}) async {
    final repo = ref.read(universityRepositoryProvider);
    if (repo == null) return;
    if (!canAdd || contains(universityId)) return;
    final nextPriority = _current.fold<int>(
          0,
          (max, u) => (u.priority ?? 0) > max ? (u.priority ?? 0) : max,
        ) +
        1;
    await repo.addInterested(
      universityId,
      source: source,
      priority: nextPriority,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String rowId) async {
    final repo = ref.read(universityRepositoryProvider);
    if (repo == null) return;
    await repo.removeInterested(rowId);
    ref.invalidateSelf();
    await future;
  }
}
