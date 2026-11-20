import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/home/data/supabase_day_event_repository.dart';
import 'package:legendstudy_app/features/home/day_event_providers.dart';
import 'package:legendstudy_app/features/home/day_target_providers.dart'
    show dayTargetClockProvider;
import 'package:legendstudy_app/features/home/domain/admission_day_event.dart';
import 'package:legendstudy_app/features/home/domain/day_event.dart';
import 'package:legendstudy_app/features/home/domain/day_event_repository.dart';
import 'package:legendstudy_app/features/home/presentation/day_target_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> officialRow({
  String status = 'ACTIVE',
  int revision = 1,
  String date = '2026-12-05',
}) => {
  'official_event_id': '00000000-0000-4000-8000-000000000001',
  'day_target_id': status == 'ACTIVE' ? 'auto-1' : null,
  'title': '아주대 논술고사',
  'university_name': '아주대학교',
  'event_type': 'ESSAY',
  'event_date': date,
  'event_time': null,
  'status': status,
  'source_url': 'https://www.iajou.ac.kr/example.pdf',
  'source_note': '공식 모집요강 확인',
  'revision': revision,
  'can_restore': status == 'DISMISSED',
  'unavailable_reason': null,
};

Map<String, dynamic> targetRow(String id, {String owner = 'owner-a'}) => {
  'id': id,
  'owner_id': owner,
  'title': id == 'auto-1' ? '아주대 논술고사' : '수동 일정',
  'event_date': '2026-12-05',
  'is_primary': id == 'manual-1',
};

Future<void> signIn(SupabaseClient client, [String owner = 'owner-a']) =>
    client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'unit-test-token',
        'refresh_token': 'unit-test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': owner,
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-11-20T00:00:00Z',
        },
      }),
    );

class AdmissionFixture
    implements DayEventRepository, AdmissionDayEventRepository {
  List<DayEvent> manual = [
    DayEvent(
      id: 'manual-1',
      date: DateTime.utc(2026, 12, 4),
      label: '수동 일정',
      isPrimary: true,
    ),
  ];
  Map<String, dynamic> official = officialRow();
  int fetches = 0;
  int actions = 0;
  bool available = true;
  bool failAction = false;
  Completer<AdmissionDayEventSnapshot>? pendingFetch;

  AdmissionDayEventSnapshot get snapshot {
    final event = AdmissionDayEvent.fromJson(official);
    return AdmissionDayEventSnapshot(
      events: [
        ...manual,
        if (event.isActive)
          DayEvent(
            id: event.dayTargetId,
            date: event.date!,
            label: event.title,
            admission: event,
          ),
      ],
      admissions: [event],
      syncAvailable: available,
    );
  }

  @override
  Future<AdmissionDayEventSnapshot> fetchAdmissionSnapshot() async {
    fetches++;
    return pendingFetch?.future ?? snapshot;
  }

  @override
  Future<List<DayEvent>> fetchEvents() async =>
      (await fetchAdmissionSnapshot()).events;
  @override
  Future<void> changeAdmissionVisibility(
    AdmissionDayEvent event, {
    required bool restore,
  }) async {
    if (failAction) throw StateError('offline');
    actions++;
    official = {
      ...official,
      'status': restore ? 'ACTIVE' : 'DISMISSED',
      'day_target_id': restore ? 'auto-1' : null,
      'can_restore': !restore,
      'revision': (official['revision'] as int) + 1,
    };
  }

  @override
  Future<void> deleteEvent(String id) async {
    if (id == 'auto-1') {
      return changeAdmissionVisibility(
        AdmissionDayEvent.fromJson(official),
        restore: false,
      );
    }
    manual.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> setPrimary(String id) async {
    manual = [for (final e in manual) e.copyWith(isPrimary: e.id == id)];
  }

  @override
  Future<DayEvent> addEvent(
    DateTime date,
    String label, {
    bool primary = false,
  }) async {
    final event = DayEvent(
      id: 'new-manual',
      date: date,
      label: label,
      isPrimary: primary,
    );
    manual.add(event);
    return event;
  }

  @override
  Future<DayEvent> updateEvent(String id, DateTime date, String label) async {
    final index = manual.indexWhere((e) => e.id == id);
    return manual[index] = manual[index].copyWith(date: date, label: label);
  }
}

void main() {
  group('official metadata', () {
    test('all admission types have user-facing labels', () {
      for (final type in [
        'ESSAY',
        'INTERVIEW',
        'PRACTICAL',
        'STAGE_RESULT',
        'INITIAL_RESULT',
        'REGISTRATION_DEADLINE',
        'OTHER',
      ]) {
        final event = AdmissionDayEvent.fromJson({
          ...officialRow(),
          'event_type': type,
        });
        expect(event.typeLabel, isNot(contains('_')));
        expect(event.displayTitle, startsWith('아주대학교 '));
      }
    });
    test('invalid dates and unknown lifecycle states fail closed', () {
      for (final patch in [
        {'event_date': '2026-02-30'},
        {'event_date': '2026-12-05T00:00:00Z'},
        {'status': 'PENDING'},
        {'revision': 0},
      ]) {
        expect(
          () => AdmissionDayEvent.fromJson({...officialRow(), ...patch}),
          throwsFormatException,
        );
      }
    });
    test('cancelled unknown date does not invent a date', () {
      final event = AdmissionDayEvent.fromJson({
        ...officialRow(status: 'CANCELLED'),
        'event_date': null,
      });
      expect(event.date, isNull);
      expect(event.canRestore, isFalse);
    });
    test('automatic D-Day still uses the KST calendar boundary', () {
      final source = AdmissionDayEvent.fromJson(officialRow());
      final event = DayEvent(
        date: source.date!,
        label: source.title,
        admission: source,
      );
      expect(event.dLabel(DateTime.utc(2026, 12, 4, 14, 59)), 'D-1');
      expect(event.dLabel(DateTime.utc(2026, 12, 4, 15)), 'D-DAY');
    });
  });

  group('Supabase contract', () {
    late SupabaseClient client;
    late SupabaseDayEventRepository repository;
    late List<http.Request> requests;
    late Map<String, dynamic> official;
    late List<Map<String, dynamic>> targets;
    String? syncError;
    bool failAction = false;
    setUp(() {
      requests = [];
      official = officialRow();
      targets = [targetRow('manual-1'), targetRow('auto-1')];
      syncError = null;
      failAction = false;
      client = SupabaseClient(
        'https://example.invalid',
        'test-public-client',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          Object? response;
          final path = request.url.path;
          if (path.endsWith('/rpc/my_admission_day_events')) {
            if (syncError != null) {
              return http.Response(
                jsonEncode({'message': 'unavailable', 'code': syncError}),
                400,
                request: request,
              );
            }
            response = {
              'events': [official],
            };
          } else if (path.endsWith('/rpc/my_admission_day_event_action')) {
            if (failAction) {
              return http.Response(
                '{"message":"offline","code":"500"}',
                500,
                request: request,
              );
            }
            final body = jsonDecode(request.body) as Map;
            final restored = body['p_action'] == 'restore';
            official = {
              ...official,
              'status': restored ? 'ACTIVE' : 'DISMISSED',
              'day_target_id': restored ? 'auto-1' : null,
              'can_restore': !restored,
              'revision': (official['revision'] as int) + 1,
            };
            targets.removeWhere((e) => e['id'] == 'auto-1');
            if (restored) {
              targets.add({
                ...targetRow('auto-1'),
                'event_date': official['event_date'],
              });
            }
            response = official;
          } else if (path.endsWith('/rpc/my_set_primary_day_target')) {
            response = null;
          } else if (path.endsWith('/day_targets')) {
            if (request.method == 'DELETE') {
              targets.removeWhere(
                (e) => 'eq.${e['id']}' == request.url.queryParameters['id'],
              );
            }
            response = targets;
          } else {
            throw StateError('Unexpected request: ${request.method} $path');
          }
          return http.Response(
            jsonEncode(response),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      repository = SupabaseDayEventRepository(client);
    });
    tearDown(() => client.dispose());

    test(
      'sync precedes projection read; manual metadata stays manual',
      () async {
        await signIn(client);
        final result = await repository.fetchAdmissionSnapshot();
        expect(requests.map((r) => r.url.path).toList(), [
          '/rest/v1/rpc/my_admission_day_events',
          '/rest/v1/day_targets',
        ]);
        expect(
          result.events.firstWhere((e) => e.id == 'manual-1').admission,
          isNull,
        );
        expect(
          result.events
              .firstWhere((e) => e.id == 'auto-1')
              .admission
              ?.eventType,
          'ESSAY',
        );
        expect(requests.last.url.queryParameters['owner_id'], 'eq.owner-a');
      },
    );
    test('delete auto calls dismiss RPC, retains manual, then restores latest date', () async {
      await signIn(client);
      await repository.fetchEvents();
      await repository.deleteEvent('auto-1');
      expect(
        requests.last.url.path,
        endsWith('/my_admission_day_event_action'),
      );
      final payload = jsonDecode(requests.last.body) as Map;
      expect(payload['p_action'], 'dismiss');
      expect(payload['p_expected_revision'], 1);
      expect(payload.containsKey('user_id'), isFalse);
      expect(requests.any((r) => r.method == 'DELETE'), isFalse);
      var result = await repository.fetchAdmissionSnapshot();
      expect(result.events.map((e) => e.id), ['manual-1']);
      official['event_date'] = '2026-12-07';
      result = await repository.fetchAdmissionSnapshot();
      expect(result.events.map((e) => e.id), ['manual-1']);
      await repository.changeAdmissionVisibility(
        result.admissions.single,
        restore: true,
      );
      result = await repository.fetchAdmissionSnapshot();
      expect(
        result.events.firstWhere((e) => e.id == 'auto-1').date,
        DateTime.utc(2026, 12, 7),
      );
      expect(
        result.events.firstWhere((e) => e.id == 'manual-1').isPrimary,
        isTrue,
      );
    });
    test(
      'ambiguous action failure retries with the same request key',
      () async {
        await signIn(client);
        final event =
            (await repository.fetchAdmissionSnapshot()).admissions.single;
        failAction = true;
        await expectLater(
          repository.changeAdmissionVisibility(event, restore: false),
          throwsA(isA<PostgrestException>()),
        );
        final key = (jsonDecode(requests.last.body) as Map)['p_request_key'];
        failAction = false;
        await repository.changeAdmissionVisibility(event, restore: false);
        expect((jsonDecode(requests.last.body) as Map)['p_request_key'], key);
      },
    );
    test('automatic date editing is blocked before any request', () async {
      await signIn(client);
      await repository.fetchEvents();
      final count = requests.length;
      await expectLater(
        repository.updateEvent('auto-1', DateTime(2026, 12, 8), '다른 날짜'),
        throwsFormatException,
      );
      expect(requests.length, count);
    });
    test('manual deletion still uses owner-scoped table DELETE', () async {
      await signIn(client);
      await repository.fetchEvents();
      await repository.deleteEvent('manual-1');
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.queryParameters['owner_id'], 'eq.owner-a');
      expect(targets.single['id'], 'auto-1');
    });
    test(
      'representative selection uses atomic RPC without table PATCH',
      () async {
        await signIn(client);
        await repository.setPrimary('manual-1');
        expect(
          requests.single.url.path,
          endsWith('/my_set_primary_day_target'),
        );
        expect(jsonDecode(requests.single.body), {'p_id': 'manual-1'});
      },
    );
    test(
      'missing migration is explicit; forbidden response never falls back',
      () async {
        await signIn(client);
        targets = [targetRow('manual-1')];
        syncError = 'PGRST202';
        final result = await repository.fetchAdmissionSnapshot();
        expect(result.syncAvailable, isFalse);
        expect(result.events.single.id, 'manual-1');
        syncError = '42501';
        requests.clear();
        await expectLater(
          repository.fetchAdmissionSnapshot(),
          throwsA(isA<PostgrestException>()),
        );
        expect(requests.length, 1);
      },
    );
    test('unexpected other owner row is rejected', () async {
      await signIn(client);
      targets = [targetRow('manual-1', owner: 'owner-b')];
      await expectLater(repository.fetchEvents(), throwsFormatException);
    });
    test('no authenticated user means no sync RPC or table request', () async {
      expect((await repository.fetchAdmissionSnapshot()).events, isEmpty);
      expect(requests, isEmpty);
    });
  });

  Future<ProviderContainer> containerFor(AdmissionFixture repo) async {
    final c = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus('owner-a')),
        ),
        dayEventRepositoryProvider.overrideWithValue(repo),
      ],
    );
    c.listen(authStateProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await c.read(dayEventsProvider.future);
    return c;
  }

  test('provider keeps deleted state on refresh and restores only by explicit action', () async {
    final repo = AdmissionFixture();
    final c = await containerFor(repo);
    addTearDown(c.dispose);
    final ctrl = c.read(dayEventsProvider.notifier);
    await ctrl.deleteEvent('auto-1');
    await ctrl.refresh();
    expect(c.read(dayEventsProvider).value!.map((e) => e.id), ['manual-1']);
    expect(ctrl.admissionEvents.single.isDismissed, isTrue);
    await ctrl.restoreAdmissionEvent(ctrl.admissionEvents.single);
    expect(c.read(dayEventsProvider).value!.length, 2);
    expect(repo.actions, 2);
  });

  test(
    'provider never accepts stale post-write fetch after account switch',
    () async {
      final auth = StreamController<AuthStatus>();
      final repo = AdmissionFixture();
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => auth.stream),
          dayEventRepositoryProvider.overrideWithValue(repo),
        ],
      );
      c.listen(dayEventsProvider, (_, _) {});
      auth.add(const AuthStatus('owner-a'));
      await Future<void>.delayed(Duration.zero);
      await c.read(dayEventsProvider.future);
      repo.pendingFetch = Completer<AdmissionDayEventSnapshot>();
      final pending = repo.pendingFetch!;
      final refreshing = c.read(dayEventsProvider.notifier).refresh();
      await Future<void>.delayed(Duration.zero);
      repo.pendingFetch = null;
      auth.add(const AuthStatus(null));
      await Future<void>.delayed(Duration.zero);
      await c.read(dayEventsProvider.future);
      pending.complete(repo.snapshot);
      expect(await refreshing, isFalse);
      expect(c.read(dayEventsProvider).value, isEmpty);
      expect(c.read(dayEventsProvider.notifier).admissionEvents, isEmpty);
      c.dispose();
      await auth.close();
    },
  );

  for (final reason in {
    'SOURCE_PENDING': '공식 일정 확인 중이에요.',
    'APPLICATION_NOT_MATCHED': '지원 정보와 연결되지 않은 일정이에요.',
    'SOURCE_CANCELLED': '공개가 중단된 일정이에요.',
    'NOT_PUBLISHED': '공개가 중단된 일정이에요.',
    'PAST_EVENT': '이미 지난 일정이에요.',
    'UNKNOWN_INTERNAL_REASON': '일정 정보를 확인할 수 없어요. 새로고침 후 다시 확인해 주세요.',
  }.entries) {
    testWidgets(
      'hidden admission explains ${reason.key} without internal data',
      (tester) async {
        const reviewNote = '관리자 검토: 전형 별칭 내부 매핑 확인';
        final repo = AdmissionFixture()
          ..official = {
            ...officialRow(status: 'CANCELLED'),
            'unavailable_reason': reason.key,
            'source_note': reviewNote,
          };
        final c = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('owner-a')),
            ),
            dayEventRepositoryProvider.overrideWithValue(repo),
            dayTargetClockProvider.overrideWith(
              (ref) => Stream.value(DateTime.utc(2026, 11, 20, 3)),
            ),
          ],
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: DayTargetCard()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('삭제·중단된 입시 일정'));
        await tester.pumpAndSettle();
        expect(find.text(reason.value), findsOneWidget);
        expect(find.text(reason.key), findsNothing);
        expect(find.text(reviewNote), findsNothing);
        expect(find.text('공식 출처'), findsOneWidget);
        expect(repo.snapshot.admissions.single.sourceNote, reviewNote);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'mobile admission badge, delete, hidden list and restore at ${scale}x',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = AdmissionFixture();
        final c = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('owner-a')),
            ),
            dayEventRepositoryProvider.overrideWithValue(repo),
            dayTargetClockProvider.overrideWith(
              (ref) => Stream.value(DateTime.utc(2026, 11, 20, 3)),
            ),
          ],
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: DayTargetCard(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('입시 일정'), findsOneWidget);
        final fetches = repo.fetches;
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
        expect(repo.fetches, greaterThan(fetches));
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget); // manual only
        expect(find.text('아주대학교 논술고사'), findsOneWidget);
        expect(find.text('공식 모집요강 확인'), findsNothing);
        expect(find.text('공식 출처'), findsOneWidget);
        final automatic = find
            .ancestor(of: find.text('아주대학교 논술고사'), matching: find.byType(Row))
            .last;
        await tester.ensureVisible(
          find.descendant(
            of: automatic,
            matching: find.byIcon(Icons.delete_outline),
          ),
        );
        await tester.tap(
          find.descendant(
            of: automatic,
            matching: find.byIcon(Icons.delete_outline),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('자동으로 다시 추가되지 않아요.'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, '삭제'));
        await tester.pumpAndSettle();
        expect(c.read(dayEventsProvider).value!.length, 1);
        await tester.tap(find.text('삭제·중단된 입시 일정'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(TextButton, '복원'));
        await tester.tap(find.widgetWithText(TextButton, '복원'));
        await tester.pumpAndSettle();
        expect(c.read(dayEventsProvider).value!.length, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
