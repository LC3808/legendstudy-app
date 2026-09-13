import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/home/domain/day_target.dart';
import 'package:legendstudy_app/features/home/domain/day_target_repository.dart';
import 'package:legendstudy_app/features/home/data/supabase_day_target_repository.dart';
import 'package:legendstudy_app/features/home/day_target_providers.dart';
import 'package:legendstudy_app/features/home/presentation/day_target_card.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';

final first = DayTarget(date: DateTime(2026, 10, 6), label: '중간고사');
final second = DayTarget(date: DateTime(2026, 11, 6), label: '기말고사');

class Targets implements DayTargetRepository {
  DayTarget? value = first;
  bool fail = false;
  int writes = 0;
  Completer<DayTarget?>? fetch;
  Completer<DayTarget>? save;
  @override
  Future<DayTarget?> fetchCurrentTarget() async =>
      fetch == null ? value : fetch!.future;
  @override
  Future<DayTarget> saveCurrentTarget(DateTime date, String label) async {
    writes++;
    if (fail) throw StateError('offline');
    if (save != null) return save!.future;
    return value = DayTarget(date: date, label: label);
  }

  @override
  Future<void> clearCurrentTarget() async {
    writes++;
    if (fail) throw StateError('offline');
    value = null;
  }
}

void main() {
  group('repository payload contract', () {
    late SupabaseClient client;
    late SupabaseDayTargetRepository repository;
    late List<http.Request> requests;
    late Map<String, dynamic>? row;
    bool fail = false;
    setUp(() {
      requests = [];
      fail = false;
      row = null;
      client = SupabaseClient(
        'https://example.invalid',
        'test-public-client',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (fail) {
            return http.Response(
              '{"message":"offline","code":"500"}',
              500,
              request: request,
            );
          }
          if (request.method == 'POST') {
            row = {
              ...?row,
              ...jsonDecode(request.body) as Map<String, dynamic>,
            };
          } else if (request.method == 'PATCH' && row != null) {
            row = {
              ...row!,
              ...jsonDecode(request.body) as Map<String, dynamic>,
            };
          }
          final object =
              request.headers['accept']?.contains('vnd.pgrst.object') == true;
          return http.Response(
            jsonEncode(object ? row : [if (row != null) row]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      repository = SupabaseDayTargetRepository(client);
    });
    tearDown(() => client.dispose());
    Future<void> login() => client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'unit-test-token',
        'refresh_token': 'unit-test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'owner-a',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-09-13T00:00:00Z',
        },
      }),
    );
    test(
      'signed-out fetch is empty and writes require login without requests',
      () async {
        expect(await repository.fetchCurrentTarget(), isNull);
        await expectLater(
          repository.saveCurrentTarget(first.date, first.label),
          throwsA(isA<SignedOutException>()),
        );
        await expectLater(
          repository.clearCurrentTarget(),
          throwsA(isA<SignedOutException>()),
        );
        expect(requests, isEmpty);
      },
    );
    test(
      'save only target columns; profile and school preserve target; clear PATCH only',
      () async {
        await login();
        row = {
          'id': 'owner-a',
          'display_name': '기존 이름',
          'grade_level': 2,
          'neis_office_code': 'J10',
          'neis_school_code': '7530932',
          'target_date': null,
          'target_label': null,
        };
        final original = Map.of(row!);
        expect(
          (await repository.saveCurrentTarget(first.date, first.label)).label,
          first.label,
        );
        expect(jsonDecode(requests.last.body), {
          'id': 'owner-a',
          'target_date': '2026-10-06',
          'target_label': first.label,
        });
        expect(requests.last.url.queryParameters['on_conflict'], 'id');
        for (final key in [
          'display_name',
          'grade_level',
          'neis_office_code',
          'neis_school_code',
        ]) {
          expect(row![key], original[key]);
        }
        final profiles = SupabaseProfileRepository(client);
        await profiles.upsertCurrentProfile(
          displayName: '수정 이름',
          gradeLevel: 3,
        );
        expect(
          (jsonDecode(requests.last.body) as Map).keys,
          unorderedEquals(['id', 'display_name', 'grade_level']),
        );
        expect(row!['target_label'], first.label);
        await profiles.updateSchoolSelection(
          officeCode: 'B10',
          schoolCode: '7010001',
        );
        expect(
          (jsonDecode(requests.last.body) as Map).keys,
          unorderedEquals(['id', 'neis_office_code', 'neis_school_code']),
        );
        expect(row!['target_label'], first.label);
        expect((await repository.fetchCurrentTarget())?.date, first.date);
        expect(
          requests.last.url.queryParameters['select'],
          'id,target_date,target_label',
        );
        await repository.clearCurrentTarget();
        expect(requests.last.method, 'PATCH');
        expect(jsonDecode(requests.last.body), {
          'target_date': null,
          'target_label': null,
        });
        expect(requests.last.url.queryParameters['id'], 'eq.owner-a');
        expect(row!['display_name'], '수정 이름');
        expect(row!['grade_level'], 3);
        expect(row!['neis_school_code'], '7010001');
        expect(requests.any((r) => r.method == 'DELETE'), isFalse);
        expect(await repository.fetchCurrentTarget(), isNull);
      },
    );
    test('calendar date roundtrip and malformed pair rejection', () async {
      await login();
      expect(
        (await repository.saveCurrentTarget(
          DateTime(2000, 1, 1, 23),
          ' 과거 ',
        )).formattedDate,
        '2000.01.01',
      );
      row!['target_date'] = '2026-02-30';
      await expectLater(repository.fetchCurrentTarget(), throwsFormatException);
      row!['target_date'] = null;
      await expectLater(repository.fetchCurrentTarget(), throwsFormatException);
    });
    test('missing profile fetch/clear and transport failure', () async {
      await login();
      expect(await repository.fetchCurrentTarget(), isNull);
      await repository.clearCurrentTarget();
      expect(row, isNull);
      fail = true;
      await expectLater(
        repository.saveCurrentTarget(first.date, first.label),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        repository.clearCurrentTarget(),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('provider isolation', () {
    late Targets repository;
    late ProviderContainer container;
    late StreamController<AuthStatus> auth;
    setUp(() {
      repository = Targets();
      auth = StreamController<AuthStatus>();
      container = ProviderContainer(
        overrides: [
          dayTargetRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith((ref) => auth.stream),
        ],
      );
      container.listen(dayTargetProvider, (_, _) {});
    });
    tearDown(() async {
      container.dispose();
      await auth.close();
    });
    Future<void> identity(String? id) async {
      auth.add(AuthStatus(id));
      await Future<void>.delayed(Duration.zero);
    }

    test('guest session does not write or upload on login', () async {
      await identity(null);
      await container.read(dayTargetProvider.future);
      await container.read(dayTargetProvider.notifier).setTarget(second);
      expect(container.read(dayTargetProvider).value?.label, second.label);
      expect(repository.writes, 0);
      await identity('A');
      expect(
        (await container.read(dayTargetProvider.future))?.label,
        first.label,
      );
      expect(repository.writes, 0);
    });
    test('authenticated fetch save edit clear and restored state', () async {
      await identity('A');
      expect(
        (await container.read(dayTargetProvider.future))?.label,
        first.label,
      );
      await container.read(dayTargetProvider.notifier).setTarget(second);
      expect(container.read(dayTargetProvider).value?.label, second.label);
      container.invalidate(dayTargetProvider);
      expect(
        (await container.read(dayTargetProvider.future))?.label,
        second.label,
      );
      await container.read(dayTargetProvider.notifier).setTarget(first);
      expect(repository.value?.label, first.label);
      await container.read(dayTargetProvider.notifier).setTarget(null);
      expect(container.read(dayTargetProvider).value, isNull);
      expect(repository.value, isNull);
    });
    test('save and clear failures retain confirmed state', () async {
      await identity('A');
      await container.read(dayTargetProvider.future);
      repository.fail = true;
      for (final value in [second, null]) {
        await expectLater(
          container.read(dayTargetProvider.notifier).setTarget(value),
          throwsStateError,
        );
        expect(container.read(dayTargetProvider).value?.label, first.label);
      }
    });
    test('logout clears and stale fetch cannot restore A into B', () async {
      repository.fetch = Completer<DayTarget?>();
      await identity('A');
      final pending = repository.fetch!;
      repository.fetch = null;
      repository.value = second;
      await identity('B');
      expect(
        (await container.read(dayTargetProvider.future))?.label,
        second.label,
      );
      pending.complete(first);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(dayTargetProvider).value?.label, second.label);
      await identity(null);
      expect(await container.read(dayTargetProvider.future), isNull);
    });
    test(
      'late save after switch or disposal cannot change current state',
      () async {
        await identity('A');
        await container.read(dayTargetProvider.future);
        repository.save = Completer<DayTarget>();
        final saving = container
            .read(dayTargetProvider.notifier)
            .setTarget(second);
        repository.value = null;
        await identity('B');
        await container.read(dayTargetProvider.future);
        repository.save!.complete(second);
        expect(await saving, isFalse);
        expect(container.read(dayTargetProvider).value, isNull);
      },
    );
    test('concurrent save rejected while first request pending', () async {
      await identity('A');
      await container.read(dayTargetProvider.future);
      repository.save = Completer<DayTarget>();
      final saving = container
          .read(dayTargetProvider.notifier)
          .setTarget(second);
      await expectLater(
        container.read(dayTargetProvider.notifier).setTarget(null),
        throwsA(isA<BackendUnavailable>()),
      );
      repository.save!.complete(second);
      expect(await saving, isTrue);
    });
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'authenticated editor failures preserve visible target at ${scale}x',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repository = Targets()..fail = true;
        final container = ProviderContainer(
          overrides: [
            dayTargetRepositoryProvider.overrideWithValue(repository),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('A')),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(20),
                  child: DayTargetCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, '설정'));
        await tester.pumpAndSettle();
        expect(find.text('내 계정에 저장돼요.'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), '새 시험');
        await tester.tap(find.text('적용'));
        await tester.pumpAndSettle();
        expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
        expect(container.read(dayTargetProvider).value?.label, first.label);
        await tester.tap(find.text('해제'));
        await tester.pumpAndSettle();
        expect(container.read(dayTargetProvider).value?.label, first.label);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
