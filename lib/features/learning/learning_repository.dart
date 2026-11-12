import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../school/school_providers.dart';

class LearningFailure implements Exception {
  const LearningFailure();
}

typedef LearningRpc = Future<Object?> Function(
  String name,
  Map<String, dynamic> params,
);
Map<String, dynamic> object(Object? value) {
  if (value is! Map) throw const LearningFailure();
  return Map<String, dynamic>.from(value);
}

int integer(Object? value) {
  if (value is! num || !value.isFinite || value < 0 || value != value.round()) {
    throw const LearningFailure();
  }
  return value.toInt();
}

int? nullableInteger(Object? value) => value == null ? null : integer(value);
String string(Object? value) {
  if (value is! String || value.isEmpty) throw const LearningFailure();
  return value;
}

int durationMilliseconds(Object? value) {
  if (value is! num || !value.isFinite || value < 0) {
    throw const LearningFailure();
  }
  // PostgreSQL numeric averages can contain fractional milliseconds. This is
  // display-unit conversion, not rank or study aggregation.
  return value.floor();
}

class SchoolCard {
  SchoolCard(this.office, this.school, this.registered);
  final String office, school;
  final int registered;
  factory SchoolCard.parse(Object? value) {
    final row = object(value);
    if (row['version'] != 'student-school-card-v1' ||
        row['has_school'] != true) {
      throw const LearningFailure();
    }
    return SchoolCard(
      string(row['office_code']),
      string(row['school_code']),
      integer(row['registered_users']),
    );
  }
}

final ownSchoolCardProvider = FutureProvider.autoDispose<SchoolCard>((
  ref,
) async {
  final school = await ref.watch(schoolSelectionProvider.future);
  if (school == null || !ref.mounted) throw const LearningFailure();
  final card = SchoolCard.parse(
    await ref.watch(learningRpcProvider)('student_school_card', {}),
  );
  if (card.office != school.officeCode || card.school != school.schoolCode) {
    throw const LearningFailure();
  }
  return card;
}, retry: (_, _) => null);

String learningDuration(int ms) => '${ms ~/ 3600000}시간 ${ms ~/ 60000 % 60}분';

class LearningSummary {
  LearningSummary(this.today, this.week, [this.allTime]);
  final int today, week;
  final int? allTime;
  factory LearningSummary.parse(Object? value) {
    final row = object(value);
    if (row['version'] != 'study-summary-v1' ||
        row['timezone'] != 'Asia/Seoul' ||
        row['unit'] != 'milliseconds' ||
        row['source'] != 'completed_synced_sessions') {
      throw const LearningFailure();
    }
    return LearningSummary(
      integer(row['today_ms']),
      integer(row['week_ms']),
      row['all_time_source'] == 'completed_synced_sessions'
          ? nullableInteger(row['all_time_ms'])
          : null,
    );
  }
}

enum RankPeriod {
  all('all', '전체 기간'),
  week('week', '이번 주'),
  lastWeek('last_week', '지난주'),
  month('month', '최근 30일');

  const RankPeriod(this.value, this.label);
  final String value, label;
}

enum RankMetric {
  total('total', '총 공부 시간'),
  participation('participation', '참여 학생 수'),
  average('average', '1인당 평균 공부 시간');

  const RankMetric(this.value, this.label);
  final String value, label;
}

typedef RankQuery = ({RankPeriod period, RankMetric metric});
const defaultRankQuery = (period: RankPeriod.all, metric: RankMetric.total);

class SchoolRank {
  SchoolRank(
    this.office,
    this.school,
    this.rank,
    this.registered,
    this.active,
    this.ms,
    this.average,
  );
  final String office, school;
  final int rank;
  final int? registered, active, ms, average;
  String get identity => '$office/$school';
  factory SchoolRank.parse(Object? value) {
    final r = object(value);
    final rank = integer(r['rank']);
    if (rank < 1) throw const LearningFailure();
    return SchoolRank(
      string(r['office_code']),
      string(r['school_code']),
      rank,
      nullableInteger(r['registered_users']),
      nullableInteger(r['active_users']),
      nullableInteger(r['ms']),
      r['avg_ms'] == null ? null : durationMilliseconds(r['avg_ms']),
    );
  }
}

class SchoolRanks {
  SchoolRanks(this.query, this.top, this.around, this.mine, this.asOf);
  final RankQuery query;
  final List<SchoolRank> top, around;
  final SchoolRank? mine;
  final String asOf;
  factory SchoolRanks.parse(Object? value, RankQuery query) {
    final r = object(value);
    if (r['version'] != 'student-school-ranking-v1' ||
        r['metric'] != query.metric.value ||
        r['period'] != query.period.value ||
        r['top'] is! List ||
        r['around'] is! List) {
      throw const LearningFailure();
    }
    final top = (r['top'] as List).map(SchoolRank.parse).toList();
    if (top.length > 10 ||
        top.map((x) => x.identity).toSet().length != top.length) {
      throw const LearningFailure();
    }
    final identities = top.map((x) => x.identity).toSet();
    // Preserve server order and tie-aware ranks; only remove repeated identities.
    final around = (r['around'] as List)
        .map(SchoolRank.parse)
        .where((row) => identities.add(row.identity))
        .toList();
    return SchoolRanks(
      query,
      top,
      around,
      r['my_school'] == null ? null : SchoolRank.parse(r['my_school']),
      string(r['as_of']),
    );
  }
}

class LearningRepository {
  LearningRepository(this.rpc);
  final LearningRpc rpc;
  Future<LearningSummary> summary() async =>
      LearningSummary.parse(await rpc('my_study_summary', {}));
  Future<SchoolRanks> ranks(RankQuery query) async => SchoolRanks.parse(
    await rpc('student_school_ranking', {
      'p_period': query.period.value,
      'p_metric': query.metric.value,
    }),
    query,
  );
}

final learningRpcProvider = Provider<LearningRpc>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final auth = ref.watch(authStateProvider);
  final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
  return (name, params) async {
    if (client == null || client.auth.currentUser?.id != owner) {
      throw const LearningFailure();
    }
    if (owner == null &&
        name != 'invite_lookup' &&
        name != 'invite_record_visit') {
      throw const SignedOutException();
    }
    final data = await client
        .rpc<Object?>(name, params: params)
        .timeout(const Duration(seconds: 20));
    if (!ref.mounted || client.auth.currentUser?.id != owner) {
      throw const LearningFailure();
    }
    return data;
  };
});
final learningRepositoryProvider = Provider(
  (ref) => LearningRepository(ref.watch(learningRpcProvider)),
);
final learningSummaryProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(learningRepositoryProvider).summary(),
  retry: (_, _) => null,
);
final schoolRanksProvider = FutureProvider.autoDispose
    .family<SchoolRanks, RankQuery>((ref, query) async {
      // Clear cached ranks on profile/identity changes. Never request rankings for an unset school.
      final school = await ref.watch(schoolSelectionProvider.future);
      if (school == null) throw const LearningFailure();
      return ref.watch(learningRepositoryProvider).ranks(query);
    }, retry: (_, _) => null);
final rankSchoolNameProvider = FutureProvider.autoDispose
    .family<String, (String, String)>((ref, key) async {
      final school = await ref
          .watch(schoolRepositoryProvider)
          .find(key.$1, key.$2);
      if (school == null) throw const LearningFailure();
      return school.name;
    }, retry: (_, _) => null);
