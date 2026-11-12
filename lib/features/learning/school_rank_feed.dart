import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../school/school_providers.dart';
import 'learning_repository.dart';

class UnrankedSchool {
  const UnrankedSchool(this.office, this.school, this.active);
  final String office, school;
  final int? active;
  String get identity => '$office/$school';
  factory UnrankedSchool.parse(Object? raw) {
    final r = object(raw);
    if (r['rank'] != null || r['ms'] != null || r['avg_ms'] != null) {
      throw const LearningFailure();
    }
    return UnrankedSchool(
      string(r['office_code']),
      string(r['school_code']),
      nullableInteger(r['active_users']),
    );
  }
}

class SchoolRankPage {
  const SchoolRankPage({
    required this.rows,
    required this.outside,
    required this.mine,
    required this.asOf,
    required this.nextOffset,
    required this.outsideNextOffset,
    this.legacy = false,
    this.around = const [],
    this.minRecorders,
    this.minRankRecorders,
    this.revision,
  });
  final List<SchoolRank> rows, around;
  final List<UnrankedSchool> outside;
  final SchoolRank? mine;
  final String asOf;
  final String? revision;
  final int? nextOffset, outsideNextOffset, minRecorders, minRankRecorders;
  final bool legacy;

  factory SchoolRankPage.parse(
    Object? raw,
    RankQuery q,
    String scope,
    int offset,
  ) {
    final r = object(raw);
    if (r['version'] != 'student-school-ranking-page-v1' ||
        r['metric'] != q.metric.value ||
        r['period'] != q.period.value ||
        r['scope'] != scope ||
        r['offset'] != offset ||
        r['limit'] != 10 ||
        r['rows'] is! List ||
        r['unranked'] is! List) {
      throw const LearningFailure();
    }
    final rows = scope == 'ranked'
        ? (r['rows'] as List).map(SchoolRank.parse).toList()
        : <SchoolRank>[];
    final outside =
        (scope == 'unranked' ? r['rows'] as List : r['unranked'] as List)
            .map(UnrankedSchool.parse)
            .toList();
    if (rows.length > 10 || outside.length > 10) throw const LearningFailure();
    final next = nullableInteger(r['next_offset']);
    if (next != null && next != offset + 10) throw const LearningFailure();
    final outsideNext = scope == 'unranked'
        ? next
        : nullableInteger(r['unranked_next_offset']);
    if (scope == 'ranked' && outsideNext != null && outsideNext != 10) {
      throw const LearningFailure();
    }
    final asOf = string(r['as_of']);
    if (DateTime.tryParse(asOf) == null) throw const LearningFailure();
    return SchoolRankPage(
      rows: rows,
      outside: outside,
      mine: r['my_school'] == null ? null : SchoolRank.parse(r['my_school']),
      asOf: asOf,
      nextOffset: scope == 'ranked' ? next : null,
      outsideNextOffset: outsideNext,
      minRecorders: integer(r['min_recorders']),
      minRankRecorders: integer(r['min_rank_recorders']),
      revision: string(r['revision']),
    );
  }
}

class SchoolRankPageRepository {
  const SchoolRankPageRepository(this.rpc);
  final LearningRpc rpc;
  Future<SchoolRankPage> load(
    RankQuery query, {
    String scope = 'ranked',
    int offset = 0,
    String? asOf,
    String? revision,
  }) async {
    try {
      return SchoolRankPage.parse(
        await rpc('student_school_ranking_page', {
          'p_period': query.period.value,
          'p_metric': query.metric.value,
          'p_scope': scope,
          'p_offset': offset,
          'p_limit': 10,
          'p_as_of': asOf,
          'p_revision': revision,
        }),
        query,
        scope,
        offset,
      );
    } on PostgrestException catch (e) {
      // A new read-only RPC requires separate deployment approval. Preserve the
      // existing TOP10 service until it exists; never fabricate missing pages.
      if (e.code != 'PGRST202' || offset != 0 || scope != 'ranked') rethrow;
      final old = await LearningRepository(rpc).ranks(query);
      return SchoolRankPage(
        rows: old.top,
        outside: const [],
        mine: old.mine,
        asOf: old.asOf,
        nextOffset: null,
        outsideNextOffset: null,
        legacy: true,
        around: old.around,
      );
    }
  }
}

final schoolRankPageRepositoryProvider = Provider(
  (ref) => SchoolRankPageRepository(ref.watch(learningRpcProvider)),
);

class SchoolRankFeed {
  const SchoolRankFeed(
    this.page, {
    this.loadingMore = false,
    this.loadingOutside = false,
    this.refreshing = false,
    this.moreFailed = false,
    this.outsideFailed = false,
    this.refreshFailed = false,
    this.changed = false,
  });
  final SchoolRankPage page;
  final bool loadingMore, loadingOutside, refreshing;
  final bool moreFailed, outsideFailed, refreshFailed, changed;
}

final schoolRankFeedProvider = AsyncNotifierProvider.autoDispose
    .family<SchoolRankFeedController, SchoolRankFeed, RankQuery>(
      SchoolRankFeedController.new,
      retry: (_, _) => null,
    );

class SchoolRankFeedController extends AsyncNotifier<SchoolRankFeed> {
  SchoolRankFeedController(this.query);
  final RankQuery query;
  int _epoch = 0;
  @override
  Future<SchoolRankFeed> build() async {
    _epoch++;
    final school = await ref.watch(schoolSelectionProvider.future);
    if (school == null || !ref.mounted) throw const LearningFailure();
    return SchoolRankFeed(
      await ref.watch(schoolRankPageRepositoryProvider).load(query),
    );
  }

  Future<void> refresh() async {
    final old = state.asData?.value;
    if (old == null ||
        old.refreshing ||
        old.loadingMore ||
        old.loadingOutside) {
      return;
    }
    final epoch = ++_epoch;
    state = AsyncData(SchoolRankFeed(old.page, refreshing: true));
    try {
      final page = await ref.read(schoolRankPageRepositoryProvider).load(query);
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(SchoolRankFeed(page));
      }
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(
          SchoolRankFeed(old.page, refreshFailed: true, changed: old.changed),
        );
      }
    }
  }

  Future<void> more({bool outside = false}) async {
    final old = state.asData?.value;
    if (old == null ||
        old.refreshing ||
        old.loadingMore ||
        old.loadingOutside) {
      return;
    }
    final offset = outside ? old.page.outsideNextOffset : old.page.nextOffset;
    if (offset == null) return;
    final epoch = _epoch;
    state = AsyncData(
      SchoolRankFeed(old.page, loadingMore: !outside, loadingOutside: outside),
    );
    try {
      final p = await ref
          .read(schoolRankPageRepositoryProvider)
          .load(
            query,
            scope: outside ? 'unranked' : 'ranked',
            offset: offset,
            asOf: old.page.asOf,
            revision: old.page.revision,
          );
      if (!ref.mounted || epoch != _epoch) return;
      if (DateTime.parse(p.asOf) != DateTime.parse(old.page.asOf) ||
          p.legacy ||
          p.revision != old.page.revision) {
        throw const LearningFailure();
      }
      final ids = old.page.rows.map((e) => e.identity).toSet();
      final outsideIds = old.page.outside.map((e) => e.identity).toSet();
      state = AsyncData(
        SchoolRankFeed(
          SchoolRankPage(
            rows: [
              ...old.page.rows,
              ...p.rows.where((e) => ids.add(e.identity)),
            ],
            outside: [
              ...old.page.outside,
              ...p.outside.where((e) => outsideIds.add(e.identity)),
            ],
            mine: old.page.mine,
            asOf: old.page.asOf,
            nextOffset: outside ? old.page.nextOffset : p.nextOffset,
            outsideNextOffset: outside
                ? p.outsideNextOffset
                : old.page.outsideNextOffset,
            minRecorders: old.page.minRecorders,
            minRankRecorders: old.page.minRankRecorders,
            revision: old.page.revision,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(
          SchoolRankFeed(
            old.page,
            moreFailed: !outside,
            outsideFailed: outside,
            changed: error is PostgrestException && error.code == 'PT409',
          ),
        );
      }
    }
  }
}
