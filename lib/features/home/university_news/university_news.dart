import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../applications/application_repository.dart';
import '../../universities/application/university_providers.dart';
import '../../universities/domain/university_models.dart';

DateTime koreanDay(DateTime time) {
  final kst = time.toUtc().add(const Duration(hours: 9));
  return DateTime.utc(kst.year, kst.month, kst.day);
}

DateTime _instant(Object? value) {
  if (value is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw const FormatException('Missing timezone');
  }
  return DateTime.parse(value).toUtc();
}

DateTime _date(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid date');
  }
  final date = DateTime.parse('${value}T00:00:00Z');
  if (date.toIso8601String().substring(0, 10) != value) {
    throw const FormatException('Invalid date');
  }
  return date;
}

class UniversityNewsItem {
  UniversityNewsItem(this.data) {
    for (final key in [
      'id',
      'series_key',
      'university_id',
      'university_name',
      'title',
      'source_title',
      'source_url',
      'event_type',
      'kind',
      'precision',
      'scope',
    ]) {
      if (data[key] is! String || (data[key] as String).isEmpty) {
        throw const FormatException('Incomplete official news');
      }
    }
    if (data['timezone'] != 'Asia/Seoul' ||
        data['revision'] is! int ||
        data['status'] != 'verified' ||
        !['schedule', 'news'].contains(data['kind']) ||
        !['university', 'track', 'division'].contains(data['scope']) ||
        !['unknown', 'date', 'exact', 'after'].contains(data['precision'])) {
      throw const FormatException('Unsupported official news');
    }
    if (isSchedule && year == null) {
      throw const FormatException('Schedule requires academic year');
    }
    final uri = Uri.tryParse(data['source_url'] as String);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid official source');
    }
    _instant(data['verified_at']);
    _instant(data['updated_at']);
    _instant(data['expires_at']);
    if (data['published_at'] != null) _instant(data['published_at']);
    if (scope != 'university' &&
        (year == null || round == null || track == null)) {
      throw const FormatException('Missing matching identity');
    }
    if (scope == 'division' && division == null) {
      throw const FormatException('Missing division');
    }
    if (scope == 'university' &&
        (track != null || round != null || division != null)) {
      throw const FormatException('Common item cannot imply track');
    }
    if (scope == 'track' && division != null) {
      throw const FormatException('Track item cannot imply division');
    }
    if (precision == 'date') {
      _date(data['starts_on']);
      if (data['ends_on'] != null) _date(data['ends_on']);
      if (data['starts_at'] != null || data['ends_at'] != null) {
        throw const FormatException('Date only has no invented time');
      }
    } else if (precision == 'exact' || precision == 'after') {
      _instant(data['starts_at']);
      if (data['ends_at'] != null) _instant(data['ends_at']);
    }
    if (end != null && start != null && end!.isBefore(start!)) {
      throw const FormatException('Reversed schedule');
    }
  }
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get universityId => data['university_id'] as String;
  String get scope => data['scope'] as String;
  int? get year => data['academic_year'] as int?;
  String? get round => data['admission_round'] as String?;
  String? get track => data['admission_type'] as String?;
  String? get division => data['department_name'] as String?;
  String get precision => data['precision'] as String;
  bool get isSchedule => data['kind'] == 'schedule';
  DateTime? get start => precision == 'unknown'
      ? null
      : precision == 'date'
      ? _date(data['starts_on'])
      : _instant(data['starts_at']);
  DateTime? get end => precision == 'unknown'
      ? null
      : precision == 'date'
      ? (data['ends_on'] == null ? start : _date(data['ends_on']))
      : (data['ends_at'] == null ? null : _instant(data['ends_at']));
  DateTime get verified => _instant(data['verified_at']);
  bool stale(DateTime now) =>
      now.toUtc().isBefore(verified) ||
      !now.toUtc().isBefore(_instant(data['expires_at']));
  bool expired(DateTime now) {
    if (start == null) return false;
    if (precision == 'date') return koreanDay(now).isAfter(end!);
    // 'After 18:00' is not an exact end. Keep on that KST day, not indefinitely.
    if (precision == 'after' && end == null) {
      return koreanDay(now).isAfter(koreanDay(start!));
    }
    return now.toUtc().isAfter(end ?? start!);
  }

  bool important(DateTime now) =>
      isSchedule &&
      [
        'registration_deadline',
        'additional_registration_deadline',
      ].contains(data['event_type']) &&
      !expired(now);
  String dateLabel(DateTime now) {
    if (start == null) return '일정 확인 중';
    if (stale(now)) return '재확인 필요 · 일정 확인 중';
    String format(DateTime date, bool time) {
      final d = time ? date.toUtc().add(const Duration(hours: 9)) : date;
      final day =
          '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
      return time
          ? '$day ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} KST'
          : day;
    }

    final date =
        '${format(start!, precision != 'date')}${precision == 'after' ? ' 이후' : ''}${end != null && end != start ? ' ~ ${format(end!, precision != 'date')}' : ''}';
    if (expired(now)) return '$date · 지난 일정';
    final days = (precision == 'date' ? start! : koreanDay(start!))
        .difference(koreanDay(now))
        .inDays;
    return '$date · ${days < 0
        ? '진행 중'
        : days == 0
        ? 'D-DAY'
        : 'D-$days'}';
  }

  String get identity => [
    data['series_key'],
    universityId,
    year,
    round,
    track,
    division,
  ].join('|');
  bool matchesApplication(ApplicationRecord a) =>
      universityId == a.data['university_id'] &&
      (year == a.year || (!isSchedule && year == null)) &&
      (scope == 'university' ||
          (round == a.type &&
              track == a.track &&
              (scope == 'track' || division == a.division)));
  bool matchesInterest(InterestedUniversity u) =>
      universityId == u.universityId &&
      scope == 'university' &&
      (year == null || year == u.admissionYear);
}

class MatchedUniversityNews {
  const MatchedUniversityNews(this.item, this.application, this.interest);
  final UniversityNewsItem item;
  final bool application, interest;
}

List<MatchedUniversityNews> matchUniversityNews(
  List<UniversityNewsItem> items,
  List<ApplicationRecord> applications,
  List<InterestedUniversity> interests,
  DateTime now, {
  bool home = false,
}) {
  final result = <String, MatchedUniversityNews>{};
  final latest = <String, UniversityNewsItem>{};
  for (final item in items) {
    final key = item.data['series_key'] as String;
    if (latest[key] == null ||
        (item.data['revision'] as int) >
            (latest[key]!.data['revision'] as int)) {
      latest[key] = item;
    }
  }
  for (final item in latest.values) {
    final application = applications.any(item.matchesApplication);
    final interest = interests.any(item.matchesInterest);
    if (!application && !interest) continue;
    if (home &&
        (item.stale(now) ||
            (item.isSchedule && (item.start == null || item.expired(now))))) {
      continue;
    }
    final previous = result[item.identity];
    if (previous == null ||
        (item.data['revision'] as int) >
            (previous.item.data['revision'] as int)) {
      result[item.identity] = MatchedUniversityNews(
        item,
        application,
        interest,
      );
    }
  }
  final values = result.values.toList();
  int priority(MatchedUniversityNews row) =>
      row.application &&
          row.item.important(now) &&
          (row.item.end ?? row.item.start ?? now).difference(now).inDays <= 7
      ? 0
      : row.application && row.item.isSchedule && !row.item.expired(now)
      ? 1
      : 2;
  values.sort((a, b) {
    final p = priority(a).compareTo(priority(b));
    if (p != 0) return p;
    final d = (a.item.start ?? a.item.verified).compareTo(
      b.item.start ?? b.item.verified,
    );
    if (a.item.isSchedule && b.item.isSchedule && d != 0) return d;
    final newest = b.item.verified.compareTo(a.item.verified);
    return newest != 0 ? newest : a.item.id.compareTo(b.item.id);
  });
  return home ? values.take(3).toList() : values;
}

class UniversityNewsFeed {
  const UniversityNewsFeed(this.items, this.applications, this.interests);
  final List<UniversityNewsItem> items;
  final List<ApplicationRecord> applications;
  final List<InterestedUniversity> interests;
  bool get emptyUniversities => applications.isEmpty && interests.isEmpty;
}

class UniversityNewsRepository {
  UniversityNewsRepository(this.rpc);
  final Future<Object?> Function(String, Map<String, dynamic>) rpc;
  Future<List<UniversityNewsItem>> load(Set<String> universities) async {
    if (universities.isEmpty) return [];
    final items = <UniversityNewsItem>[];
    String? snapshot;
    // Stable server order; pagination avoids silently missing a closing deadline.
    for (var offset = 0; offset < 10000; offset += 100) {
      final raw = await rpc('university_news_feed', {
        'p_universities': universities.toList()..sort(),
        'p_offset': offset,
        if (snapshot != null) 'p_as_of': snapshot,
      });
      if (raw is! Map ||
          raw['version'] != 'university-news-v1' ||
          raw['items'] is! List ||
          raw['has_more'] is! bool ||
          raw['snapshot_at'] is! String) {
        throw const FormatException('Unsupported news contract');
      }
      final received = raw['snapshot_at'] as String;
      _instant(received);
      if (snapshot != null &&
          DateTime.parse(snapshot) != DateTime.parse(received)) {
        throw const FormatException('Snapshot changed');
      }
      snapshot = received;
      final rows = raw['items'] as List;
      for (final row in rows) {
        final item = UniversityNewsItem(Map<String, dynamic>.from(row as Map));
        if (!universities.contains(item.universityId)) {
          throw const FormatException('Unexpected university');
        }
        items.add(item);
      }
      if (raw['has_more'] == false) return items;
      if (rows.length != 100) throw const FormatException('Incomplete page');
    }
    throw const FormatException('News limit exceeded');
  }
}

final universityNewsRepositoryProvider = Provider<UniversityNewsRepository?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? null
      : UniversityNewsRepository(
          (name, params) async => client.rpc(name, params: params),
        );
});
// Refetch every 5 minutes while visible. No persistent news cache. Home settings
// cache and admissions freshness are deliberately independent.
final universityNewsProvider = FutureProvider.autoDispose<UniversityNewsFeed>((
  ref,
) async {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading || auth.hasError) throw StateError('Account unavailable');
  final owner = auth.asData?.value.userId;
  if (owner == null) return const UniversityNewsFeed([], [], []);
  final interests = await ref.watch(interestedUniversitiesProvider.future);
  final apps = await ref.watch(applicationsProvider.future);
  final ids = {
    ...interests.map((u) => u.universityId),
    ...apps.map((a) => a.data['university_id'] as String),
  };
  if (ids.isEmpty) return UniversityNewsFeed([], apps, interests);
  final repository = ref.watch(universityNewsRepositoryProvider);
  if (repository == null) throw StateError('News unavailable');
  final items = await repository.load(ids);
  if (!ref.mounted ||
      ref.read(authStateProvider).asData?.value.userId != owner) {
    throw StateError('Account changed');
  }
  final timer = Timer(const Duration(minutes: 5), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return UniversityNewsFeed(items, apps, interests);
}, retry: (_, _) => null);
String universityNewsError(Object error) {
  if (error is PostgrestException) {
    if (['PGRST202', '42P01', '42883'].contains(error.code)) {
      return '공식 정보 연결을 준비 중이에요. 일정 확인 중';
    }
    return '서버에서 대학 소식을 불러오지 못했어요.';
  }
  if (error is FormatException) return '공식 정보 형식을 확인 중이에요. 일정 확인 중';
  return '네트워크 연결을 확인하고 다시 시도해 주세요.';
}
