import 'dart:io';

import 'core_ux_test.dart' as preview;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/learning/learning_repository.dart';
import 'package:legendstudy_app/features/learning/learning_widgets.dart';
import 'package:legendstudy_app/features/learning/invite_controller.dart';
import 'package:legendstudy_app/features/learning/invite_page.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';

final token = 'a' * 64;
final otherToken = 'b' * 64;
Map<String, Object?> row(int id, int rank, {bool own = false, int? ms}) => {
  'office_code': 'B10',
  'school_code': '$id',
  'rank': rank,
  'registered_users': own ? 8 : null,
  'active_users': own ? 2 : null,
  'ms': ms,
  'avg_ms': ms,
};
Map<String, Object?> ranking(
  RankQuery q, {
  List<Object?>? top,
  List<Object?>? around,
  Object? mine,
}) => {
  'version': 'student-school-ranking-v1',
  'period': q.period.value,
  'metric': q.metric.value,
  'top': top ?? [],
  'around': around ?? [],
  'my_school': mine,
  'as_of': '2026-11-11T01:00:00Z',
};

class MemoryInviteStore implements InviteStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? v) async {
    value = v;
  }

  @override
  Future<String> visitor() async => 'isolated-visitor';
}

class SelectedSchool extends SchoolSelection {
  SelectedSchool(this.school);
  final School? school;
  @override
  Future<School?> build() async => school;
}

const school = School(
  officeCode: 'B10',
  schoolCode: '12',
  name: '아주 긴 이름을 가진 테스트 고등학교',
  schoolType: '고등학교',
  address: '',
);
void main() {
  test(
    'lifetime uses only explicit server lifetime and never last30 fallback',
    () {
      final data = <String, Object?>{
        'version': 'study-summary-v1',
        'timezone': 'Asia/Seoul',
        'unit': 'milliseconds',
        'source': 'completed_synced_sessions',
        'today_ms': 1,
        'week_ms': 2,
        'last30_ms': 999,
      };
      expect(LearningSummary.parse(data).allTime, isNull);
      data.addAll({
        'all_time_source': 'completed_synced_sessions',
        'all_time_ms': 5400000,
      });
      expect(learningDuration(LearningSummary.parse(data).allTime!), '1시간 30분');
      data['all_time_ms'] = -1;
      expect(
        () => LearningSummary.parse(data),
        throwsA(isA<LearningFailure>()),
      );
    },
  );

  testWidgets('new signup waits for profile bootstrap before attribution', (
    t,
  ) async {
    final profile = Completer<UserProfile?>();
    final calls = <String>[];
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (_) => Stream.value(const AuthStatus('A')),
        ),
        currentProfileProvider.overrideWith((_) => profile.future),
        inviteStoreProvider.overrideWithValue(MemoryInviteStore()),
        learningRpcProvider.overrideWithValue((name, args) async {
          calls.add(name);
          if (name == 'invite_lookup') return {'valid': true};
          if (name == 'invite_attribute_signup') {
            return {'attributed': true, 'reason': 'ok'};
          }
          return {'ok': true};
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(inviteControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    final c = container.read(inviteControllerProvider);
    await t.pump();
    await c.receive(Uri.parse(inviteUrl(token)));
    expect(calls, isNot(contains('invite_attribute_signup')));
    profile.complete(const UserProfile(id: 'A'));
    await t.pump();
    await c.retry();
    expect(calls.where((name) => name == 'invite_attribute_signup').length, 1);
  });
  test(
    'warm invite is not lost during initial-link lookup, auth callback ignored',
    () async {
      final source = StreamController<Uri>.broadcast();
      final initial = Completer<Uri?>();
      final received = <Uri>[];
      final subscription = inviteUris(
        source.stream,
        initial.future,
      ).listen(received.add);
      final uri = Uri.parse(inviteUrl(token));
      source.add(Uri.parse('com.legendstudy.app://login-callback?code=secret'));
      source.add(uri);
      await Future<void>.delayed(Duration.zero);
      initial.complete(uri);
      await Future<void>.delayed(Duration.zero);
      expect(received, [uri]);
      await subscription.cancel();
      await source.close();
    },
  );
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  test('numeric server average supports fractional milliseconds', () {
    final r = SchoolRank.parse({...row(1, 1), 'avg_ms': 1234567.89});
    expect(r.average, 1234567);
    expect(learningDuration(r.average!), '0시간 20분');
  });
  test(
    'school card validates version and keeps registered separate from active',
    () {
      final card = SchoolCard.parse({
        'version': 'student-school-card-v1',
        'has_school': true,
        'office_code': 'B10',
        'school_code': '12',
        'registered_users': 8,
      });
      expect(card.registered, 8);
      expect(
        () => SchoolCard.parse({'version': 'bad', 'has_school': true}),
        throwsA(isA<LearningFailure>()),
      );
    },
  );

  test('explicit default all/participation; every period and metric passed unchanged', () async {
    final requests = <Map<String, dynamic>>[];
    final repo = LearningRepository((name, params) async {
      expect(name, 'student_school_ranking');
      requests.add(params);
      return ranking((
        period: RankPeriod.values.firstWhere(
          (v) => v.value == params['p_period'],
        ),
        metric: RankMetric.values.firstWhere(
          (v) => v.value == params['p_metric'],
        ),
      ));
    });
    await repo.ranks(defaultRankQuery);
    expect(requests.first, {'p_period': 'all', 'p_metric': 'participation'});
    for (final p in RankPeriod.values) {
      for (final m in RankMetric.values) {
        await repo.ranks((period: p, metric: m));
      }
    }
    expect(requests.length, 13);
  });
  test('server ties order preserved, around deduped, no null to zero', () {
    final data = SchoolRanks.parse(
      ranking(
        defaultRankQuery,
        top: [row(1, 1), row(2, 1)],
        around: [row(2, 1), row(12, 11, own: true)],
        mine: row(12, 11, own: true),
      ),
      defaultRankQuery,
    );
    expect(data.top.map((r) => r.rank), [1, 1]);
    expect(data.top.first.active, isNull);
    expect(data.around.map((r) => r.school), ['12']);
    expect(data.mine!.active, 2);
    expect(data.mine!.ms, isNull);
  });
  test('reject overlong top and wrong response contract', () {
    expect(
      () => SchoolRanks.parse(
        ranking(defaultRankQuery, top: List.generate(11, (i) => row(i, i + 1))),
        defaultRankQuery,
      ),
      throwsA(isA<LearningFailure>()),
    );
    expect(
      () => SchoolRanks.parse({
        ...ranking(defaultRankQuery),
        'period': 'week',
      }, defaultRankQuery),
      throwsA(isA<LearningFailure>()),
    );
  });
  test('server errors are errors, never empty ranking', () async {
    await expectLater(
      LearningRepository((_, _) async => throw const LearningFailure())
          .ranks(defaultRankQuery),
      throwsA(isA<LearningFailure>()),
    );
  });
  test(
    'summary uses confirmed server values, duration formatting not aggregation',
    () {
      final s = LearningSummary.parse({
        'version': 'study-summary-v1',
        'timezone': 'Asia/Seoul',
        'unit': 'milliseconds',
        'source': 'completed_synced_sessions',
        'today_ms': 3600000,
        'week_ms': 5400000,
      });
      expect(learningDuration(s.today), '1시간 0분');
      expect(learningDuration(s.week), '1시간 30분');
    },
  );
  test(
    'accept only exact invite origins and token; ignore OAuth callbacks',
    () {
      expect(inviteTokenFromUri(Uri.parse(inviteUrl(token))), token);
      expect(
        inviteTokenFromUri(Uri.parse('com.legendstudy.app://invite?t=$token')),
        token,
      );
      for (final url in [
        'https://evil.test/invite?t=$token',
        'https://lab.legendstudy.com.evil.test/invite?t=$token',
        'com.legendstudy.app://login-callback?code=x',
        'https://lab.legendstudy.com/invite?t=$token&t=$otherToken',
        'https://lab.legendstudy.com/invite?t=bad',
        'http://lab.legendstudy.com/invite?t=$token',
      ]) {
        expect(inviteTokenFromUri(Uri.parse(url)), isNull);
      }
    },
  );
  test('guest persists invite, login attributes once, explicit school confirmation', () async {
    final calls = <String>[];
    final store = MemoryInviteStore();
    final c = InviteController(
      () => (name, args) async {
        calls.add(name);
        if (name == 'invite_lookup') return {'valid': true};
        if (name == 'invite_attribute_signup') {
          return {
            'attributed': true,
            'reason': 'ok',
            'office_code': 'B10',
            'school_code': '12',
          };
        }
        return {'ok': true};
      },
      store,
    );
    addTearDown(c.dispose);
    await c.receive(Uri.parse(inviteUrl(token)));
    expect(calls.contains('invite_attribute_signup'), false);
    expect(store.value, contains(token));
    c.identity('A');
    await c.retry();
    expect(c.needsSchoolConfirmation, true);
    expect(calls.where((n) => n == 'invite_attribute_signup').length, 1);
    await c.markSchoolConfirmed();
    expect(store.value, isNull);
    expect(c.needsSchoolConfirmation, false);
  });
  for (final reason in ['self_invite', 'not_new_signup', 'token_invalid']) {
    test('server rejection $reason never counted as conversion', () async {
      final c = InviteController(
        () =>
            (name, args) async => name == 'invite_lookup'
            ? {'valid': true}
            : name == 'invite_attribute_signup'
            ? {'attributed': false, 'reason': reason}
            : {},
        MemoryInviteStore(),
      );
      addTearDown(c.dispose);
      c.identity('A');
      await c.receive(Uri.parse(inviteUrl(token)));
      expect(c.token, isNull);
      expect(c.needsSchoolConfirmation, false);
      expect(c.message, isNot(contains('초대가 연결됐어요')));
    });
  }
  test('expired link does not record visit or attribute', () async {
    final calls = <String>[];
    final c = InviteController(
      () => (n, p) async {
        calls.add(n);
        return {'valid': false, 'reason': 'expired'};
      },
      MemoryInviteStore(),
    );
    addTearDown(c.dispose);
    c.identity('A');
    await c.receive(Uri.parse(inviteUrl(token)));
    expect(calls, ['invite_lookup']);
    expect(c.message, contains('만료'));
  });
  test('failed attribution retained and can retry', () async {
    var fail = true;
    final store = MemoryInviteStore();
    final c = InviteController(
      () => (n, p) async {
        if (n == 'invite_lookup') return {'valid': true};
        if (n == 'invite_attribute_signup') {
          if (fail) throw Exception();
          return {'attributed': true, 'reason': 'ok'};
        }
        return {};
      },
      store,
    );
    addTearDown(c.dispose);
    c.identity('A');
    await c.receive(Uri.parse(inviteUrl(token)));
    expect(store.value, contains(token));
    fail = false;
    await c.retry();
    expect(store.value, isNull);
  });
  test(
    'account switch drops delayed result and never reassigns pending invite',
    () async {
      final pending = Completer<Object?>();
      final owners = <String>[];
      late InviteController c;
      c = InviteController(
        () => (n, p) async {
          if (n == 'invite_lookup') return {'valid': true};
          if (n == 'invite_attribute_signup') {
            owners.add(c.owner!);
            return pending.future;
          }
          return {};
        },
        MemoryInviteStore(),
      );
      addTearDown(c.dispose);
      c.identity('A');
      final task = c.receive(Uri.parse(inviteUrl(token)));
      while (owners.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      c.identity('B');
      pending.complete({
        'attributed': true,
        'reason': 'ok',
        'office_code': 'B10',
        'school_code': '12',
      });
      await task;
      await c.retry();
      expect(owners, ['A']);
      expect(c.needsSchoolConfirmation, false);
    },
  );
  test('restart restores guest token before login', () async {
    final store = MemoryInviteStore();
    Future<Object?> call(String n, Map<String, dynamic> p) async =>
        n == 'invite_lookup'
        ? {'valid': true}
        : n == 'invite_attribute_signup'
        ? {'attributed': true, 'reason': 'ok'}
        : {};
    final c = InviteController(() => call, store);
    await c.receive(Uri.parse(inviteUrl(token)));
    c.dispose();
    final next = InviteController(() => call, store);
    addTearDown(next.dispose);
    await next.restore();
    expect(next.token, token);
    next.identity('A');
    await next.retry();
    expect(store.value, isNull);
  });
  for (final scale in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'ranking native 360px scale$scale dark$dark mask/ties/around',
        (t) async {
          t.view.physicalSize = const Size(360, 640);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith(
                  (_) => Stream.value(const AuthStatus('A')),
                ),
                schoolSelectionProvider.overrideWith(
                  () => SelectedSchool(school),
                ),
                schoolRanksProvider.overrideWith(
                  (ref, q) async => SchoolRanks.parse(
                    ranking(
                      q,
                      top: [row(1, 1), row(2, 1)],
                      around: [row(12, 11, own: true)],
                      mine: row(12, 11, own: true),
                    ),
                    q,
                  ),
                ),
                rankSchoolNameProvider.overrideWith(
                  (_, key) async => '길고 긴 학교 이름 테스트 고등학교',
                ),
              ],
              child: MaterialApp(
                theme: (dark ? ThemeData.dark() : AppTheme.light).copyWith(
                  chipTheme: (dark ? ThemeData.dark() : AppTheme.light)
                      .chipTheme
                      .copyWith(
                        labelStyle: const TextStyle(fontFamily: 'CorePreview'),
                      ),
                  textTheme: (dark ? ThemeData.dark() : AppTheme.light)
                      .textTheme
                      .apply(
                        fontFamily: const bool.fromEnvironment('CORE_RENDER')
                            ? 'CorePreview'
                            : null,
                      ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: RepaintBoundary(
                  key: preview.frame,
                  child: const SchoolRankingPage(),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.text('참여 **명'), findsNWidgets(2));
          expect(find.text('참여 2명'), findsOneWidget);
          expect(find.text('1위'), findsNWidgets(2));
          expect(find.text('11위 · 우리 학교'), findsOneWidget);
          await preview.capture(t, 'learning-rank-$scale-$dark');
          await t.ensureVisible(find.text('11위 · 우리 학교'));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await preview.capture(t, 'learning-rank-rows-$scale-$dark');
        },
      );
    }
  }
  testWidgets('unset school shows setup, never requests ranks', (t) async {
    var calls = 0;
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (_) => Stream.value(const AuthStatus('A')),
          ),
          schoolSelectionProvider.overrideWith(() => SelectedSchool(null)),
          schoolRanksProvider.overrideWith((_, q) async {
            calls++;
            throw Exception();
          }),
        ],
        child: const MaterialApp(home: SchoolRankingPage()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('학교 등록하기'), findsOneWidget);
    expect(calls, 0);
  });
  testWidgets('Study invite opens share sheet in one tap and retries failure', (
    t,
  ) async {
    var calls = 0, shared = 0;
    final pending = Completer<Object?>();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (_) => Stream.value(const AuthStatus('A')),
          ),
          learningRpcProvider.overrideWithValue((n, p) async {
            expect(n, 'invite_create');
            calls++;
            if (calls == 1) return pending.future;
            return {
              'token': token,
              'expires_at': '2099-01-01T00:00:00Z',
              'has_school': true,
            };
          }),
          inviteShareProvider.overrideWithValue((url) async {
            expect(url, inviteUrl(token));
            shared++;
            if (shared == 1) throw PlatformException(code: 'FAILED');
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: InviteShareButton())),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('받은 초대 확인'), findsNothing);
    expect(find.text('초대 링크 만들기'), findsNothing);
    await t.tap(find.text('초대하기'));
    await t.pump();
    await t.tap(find.text('공유 준비 중…'));
    await t.pump();
    expect(calls, 1);
    pending.complete({
      'token': token,
      'expires_at': '2099-01-01T00:00:00Z',
      'has_school': true,
    });
    await t.pumpAndSettle();
    expect(shared, 1);
    expect(find.textContaining('공유창을 열지 못했어요'), findsOneWidget);
    await t.tap(find.text('초대하기'));
    await t.pumpAndSettle();
    expect(shared, 2);
    expect(find.textContaining('공유창을 열지 못했어요'), findsNothing);
  });
}
