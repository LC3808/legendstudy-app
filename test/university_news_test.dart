import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/applications/application_repository.dart';
import 'package:legendstudy_app/features/home/university_news/university_news.dart';
import 'package:legendstudy_app/features/home/university_news/university_news_widgets.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';

// Fictional test fixtures only. No fixture ingestion, startup seed, or production fallback.
Map<String, dynamic> news({
  String series = 's',
  String track = '일반전형',
  String division = '인문',
  String scope = 'division',
  int year = 2027,
  int revision = 1,
  String day = '2026-11-12',
}) => {
  'id': '$series-$revision',
  'series_key': series,
  'revision': revision,
  'university_id': 'u',
  'university_name': '테스트대학교',
  'academic_year': year,
  'admission_round': scope == 'university' ? null : '수시',
  'admission_type': scope == 'university' ? null : track,
  'department_name': scope == 'division' ? division : null,
  'scope': scope,
  'kind': 'schedule',
  'event_type': 'interview',
  'title': '공식 일정 테스트',
  'precision': 'date',
  'starts_on': day,
  'timezone': 'Asia/Seoul',
  'source_title': '공식 안내 테스트',
  'source_url': 'https://admission.example.edu/notice',
  'verified_at': '2026-11-10T00:00:00Z',
  'published_at': '2026-11-09T00:00:00Z',
  'updated_at': '2026-11-10T00:00:00Z',
  'expires_at': '2026-12-31T00:00:00Z',
  'status': 'verified',
};
ApplicationRecord application({
  String track = '일반전형',
  String division = '인문',
  int year = 2027,
  String university = 'u',
}) => ApplicationRecord({
  'id': 'a-$track-$division',
  'admission_year': year,
  'university_id': university,
  'university_name_snapshot': '테스트대학교',
  'intended_division': division,
  'admission_type': '수시',
  'admission_name': track,
  'revision': 1,
});
const interest = InterestedUniversity(
  id: 'i',
  universityId: 'u',
  name: '테스트대학교',
  admissionYear: 2027,
);
final now = DateTime.parse('2026-11-11T14:59:00Z');
void main() {
  test(
    'application exact year university round track and required division match',
    () {
      final item = UniversityNewsItem(news());
      expect(item.matchesApplication(application()), true);
      for (final a in [
        application(track: '일반'),
        application(division: '자연'),
        application(year: 2028),
        application(university: 'other'),
      ]) {
        expect(item.matchesApplication(a), false);
      }
      final wrongRound = ApplicationRecord({
        ...application().data,
        'admission_type': '정시',
      });
      expect(item.matchesApplication(wrongRound), false);
    },
  );
  test('interest without track gets common information only, unknown year not guessed', () {
    expect(UniversityNewsItem(news()).matchesInterest(interest), false);
    expect(
      UniversityNewsItem(news(scope: 'university')).matchesInterest(interest),
      true,
    );
    const noYear = InterestedUniversity(id: 'i', universityId: 'u', name: '대학');
    expect(
      UniversityNewsItem(news(scope: 'university')).matchesInterest(noYear),
      false,
    );
    final evergreen = UniversityNewsItem({
      ...news(scope: 'university'),
      'academic_year': null,
      'kind': 'news',
      'precision': 'unknown',
      'starts_on': null,
    });
    expect(evergreen.matchesInterest(noYear), true);
    expect(evergreen.matchesApplication(application()), true);
  });
  test('same information dedupes across interests/applications, different tracks and departments survive', () {
    final items = [
      UniversityNewsItem(news(scope: 'university')),
      UniversityNewsItem(news(scope: 'university')),
      UniversityNewsItem(news(series: 'track2', track: '논술')),
      UniversityNewsItem(news(series: 'division2', division: '자연')),
    ];
    final result = matchUniversityNews(
      items,
      [application(), application(track: '논술'), application(division: '자연')],
      [interest],
      now,
    );
    expect(result.length, 3);
    expect(
      result.singleWhere((r) => r.item.scope == 'university').application,
      true,
    );
    expect(
      result.singleWhere((r) => r.item.scope == 'university').interest,
      true,
    );
  });
  test(
    'latest revised identity/freshness suppresses old revision before matching',
    () {
      final old = UniversityNewsItem(news());
      final revised = UniversityNewsItem(news(revision: 2, division: '자연'));
      expect(
        matchUniversityNews([old, revised], [application()], [], now),
        isEmpty,
      );
      final stale = UniversityNewsItem({
        ...news(revision: 3),
        'expires_at': '2026-11-11T00:00:00Z',
      });
      expect(
        matchUniversityNews([old, stale], [application()], [], now, home: true),
        isEmpty,
      );
      expect(
        matchUniversityNews(
          [old, stale],
          [application()],
          [],
          now,
        ).single.item.data['revision'],
        3,
      );
    },
  );
  test('near registration deadlines outrank interviews; home max3 and expired excluded', () {
    final items = [
      for (var i = 0; i < 4; i++) UniversityNewsItem(news(series: '$i')),
      UniversityNewsItem({
        ...news(series: 'deadline', day: '2026-11-15'),
        'event_type': 'registration_deadline',
      }),
      UniversityNewsItem(news(series: 'past', day: '2026-11-10')),
    ];
    final result = matchUniversityNews(
      items,
      [application()],
      [],
      now,
      home: true,
    );
    expect(result.length, 3);
    expect(result.first.item.data['series_key'], 'deadline');
    expect(result.any((r) => r.item.data['series_key'] == 'past'), false);
    expect(matchUniversityNews(items, [application()], [], now).length, 6);
  });
  test(
    'date-only has no fabricated time and uses KST midnight for D-Day/expiry',
    () {
      final item = UniversityNewsItem(news());
      expect(item.dateLabel(now), contains('D-1'));
      expect(
        item.dateLabel(DateTime.parse('2026-11-11T15:00:00Z')),
        contains('D-DAY'),
      );
      expect(item.dateLabel(now), isNot(contains('00:00')));
      expect(item.expired(DateTime.parse('2026-11-12T14:59:59Z')), false);
      expect(item.expired(DateTime.parse('2026-11-12T15:00:00Z')), true);
    },
  );
  test(
    'exact time expires after stated end; after time is not an exact release',
    () {
      final data = {
        ...news(),
        'precision': 'exact',
        'starts_on': null,
        'starts_at': '2026-11-12T18:00:00+09:00',
      };
      final exact = UniversityNewsItem(data);
      expect(exact.dateLabel(now), contains('18:00 KST'));
      expect(exact.expired(DateTime.parse('2026-11-12T09:00:01Z')), true);
      final after = UniversityNewsItem({...data, 'precision': 'after'});
      expect(after.dateLabel(now), contains('이후'));
      expect(after.expired(DateTime.parse('2026-11-12T10:00:00Z')), false);
      expect(after.expired(DateTime.parse('2026-11-12T15:00:00Z')), true);
    },
  );
  test('unknown schedules never get D-Day; stale info never claims current verification', () {
    final unknown = UniversityNewsItem({
      ...news(),
      'precision': 'unknown',
      'starts_on': null,
    });
    expect(unknown.dateLabel(now), '일정 확인 중');
    expect(
      matchUniversityNews([unknown], [application()], [], now, home: true),
      isEmpty,
    );
    final stale = UniversityNewsItem({
      ...news(),
      'expires_at': '2026-11-11T00:00:00Z',
    });
    expect(stale.dateLabel(now), '재확인 필요 · 일정 확인 중');
  });
  test('invalid dates unsafe sources unverified rows and timezone-less timestamps fail closed', () {
    for (final invalid in [
      {...news(), 'starts_on': '2026-02-30'},
      {...news(), 'source_url': 'javascript:alert(1)'},
      {...news(), 'status': 'draft'},
      {...news(), 'verified_at': '2026-11-11T00:00:00'},
      {...news(), 'timezone': 'UTC'},
    ]) {
      expect(() => UniversityNewsItem(invalid), throwsFormatException);
    }
  });
  test(
    'feed no university does no fetch; pagination and version enforced',
    () async {
      var calls = 0;
      final repo = UniversityNewsRepository((name, params) async {
        expect(name, 'university_news_feed');
        expect(params['p_universities'], ['u']);
        calls++;
        return {
          'version': 'university-news-v1',
          'snapshot_at': '2026-11-11T00:00:00Z',
          'items': [
            for (var i = 0; i < (calls == 1 ? 100 : 1); i++)
              news(series: '$calls-$i'),
          ],
          'has_more': calls == 1,
        };
      });
      expect(await repo.load({}), isEmpty);
      expect(calls, 0);
      expect((await repo.load({'u'})).length, 101);
      expect(calls, 2);
      await expectLater(
        UniversityNewsRepository((n, p) async => {'version': 'bad'})
            .load({'u'}),
        throwsFormatException,
      );
    },
  );
  test('error states separate network, server, unavailable contract and invalid evidence', () {
    expect(universityNewsError(Exception()), contains('네트워크'));
    expect(
      universityNewsError(const PostgrestException(message: '', code: '500')),
      contains('서버'),
    );
    expect(
      universityNewsError(
        const PostgrestException(message: '', code: 'PGRST202'),
      ),
      contains('일정 확인 중'),
    );
    expect(universityNewsError(const FormatException()), contains('형식'));
  });
  testWidgets('card and details share feed; source opens exact verified URL', (
    t,
  ) async {
    Uri? opened;
    final data = UniversityNewsFeed(
      [
        UniversityNewsItem({
          ...news(scope: 'university'),
          'kind': 'news',
          'precision': 'unknown',
          'starts_on': null,
          'expires_at': '2200-01-01T00:00:00Z',
        }),
      ],
      [],
      [interest],
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          universityNewsProvider.overrideWith((ref) async => data),
          externalOpenerProvider.overrideWithValue((uri) async {
            opened = uri;
            return true;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: UniversityNewsCard()),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('공식 안내 테스트'));
    await t.pumpAndSettle();
    expect(opened.toString(), 'https://admission.example.edu/notice');
    await t.tap(find.text('전체 보기'));
    await t.pumpAndSettle();
    expect(find.text('주요 일정'), findsOneWidget);
    expect(find.text('대학별 소식'), findsOneWidget);
    await t.tap(find.text('실제 지원 대학'));
    await t.pump();
    expect(find.text('공식 일정 테스트'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
