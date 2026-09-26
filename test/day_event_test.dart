import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/home/day_event_providers.dart';
import 'package:legendstudy_app/features/home/day_target_providers.dart'
    show dayTargetClockProvider;
import 'package:legendstudy_app/features/home/domain/day_event.dart';
import 'package:legendstudy_app/features/home/domain/day_event_repository.dart';
import 'package:legendstudy_app/features/home/presentation/day_target_card.dart';

/// In-memory owner-scoped repository, mirroring the real per-owner isolation.
class FakeDayEventRepository implements DayEventRepository {
  FakeDayEventRepository(this.ownerOf);
  final String? Function() ownerOf;
  final Map<String, List<DayEvent>> _byOwner = {};
  int _seq = 0;

  List<DayEvent> _list() => _byOwner.putIfAbsent(ownerOf()!, () => []);

  @override
  Future<List<DayEvent>> fetchEvents() async =>
      [..._list()]..sort(compareEvents);

  @override
  Future<DayEvent> addEvent(DateTime date, String label,
      {bool primary = false}) async {
    final list = _list();
    if (primary) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isPrimary: false);
      }
    }
    final event = DayEvent(
        id: 'e${_seq++}', date: date, label: label, isPrimary: primary);
    list.add(event);
    return event;
  }

  @override
  Future<DayEvent> updateEvent(String id, DateTime date, String label) async {
    final list = _list();
    final i = list.indexWhere((e) => e.id == id);
    list[i] = list[i].copyWith(date: date, label: label);
    return list[i];
  }

  @override
  Future<void> deleteEvent(String id) async =>
      _list().removeWhere((e) => e.id == id);

  @override
  Future<void> setPrimary(String id) async {
    final list = _list();
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isPrimary: list[i].id == id);
    }
  }
}

/// Repository whose writes always fail, to prove failures are not shown as
/// success and never mutate state.
class ThrowingDayEventRepository implements DayEventRepository {
  @override
  Future<List<DayEvent>> fetchEvents() async => const [];
  @override
  Future<DayEvent> addEvent(DateTime date, String label, {bool primary = false}) =>
      throw Exception('backend down');
  @override
  Future<DayEvent> updateEvent(String id, DateTime date, String label) =>
      throw Exception('backend down');
  @override
  Future<void> deleteEvent(String id) => throw Exception('backend down');
  @override
  Future<void> setPrimary(String id) => throw Exception('backend down');
}

Future<ProviderContainer> _authed(String owner, DayEventRepository repo) async {
  final c = ProviderContainer(overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(AuthStatus(owner))),
    dayEventRepositoryProvider.overrideWith((ref) => repo),
  ]);
  // Let the auth stream settle, then build the events provider once against the
  // settled identity (so its first build reads the repository, not a loading []).
  c.listen(authStateProvider, (_, _) {});
  for (var i = 0; i < 20 && c.read(authStateProvider).isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await c.read(dayEventsProvider.future);
  return c;
}

void main() {
  final now = DateTime.utc(2026, 9, 26, 3); // KST 2026-09-26 noon

  group('domain', () {
    test('date format includes derived Korean weekday', () {
      expect(formatEventDate(DateTime(2026, 10, 6)), '2026.10.06.(화)');
      expect(formatEventDate(DateTime(2027, 11, 18)), '2027.11.18.(목)');
    });

    test('D-N uses KST calendar day', () {
      final e = DayEvent(date: DateTime(2026, 9, 27), label: '수행');
      expect(e.dLabel(DateTime.utc(2026, 9, 26, 5)), 'D-1');
      expect(e.dLabel(DateTime.utc(2026, 9, 27, 5)), 'D-DAY');
      expect(e.dLabel(DateTime.utc(2026, 9, 28, 5)), '지난 일정');
    });

    test('representative honors chosen primary over the nearest event', () {
      final near = DayEvent(id: 'a', date: DateTime(2026, 10, 1), label: '수행');
      final farPrimary = DayEvent(
          id: 'b', date: DateTime(2027, 11, 18), label: '수능', isPrimary: true);
      expect(representativeEvent([near, farPrimary], now)?.id, 'b');
    });

    test('representative falls back to nearest upcoming when no primary', () {
      final a = DayEvent(id: 'a', date: DateTime(2026, 10, 6), label: '중간');
      final b = DayEvent(id: 'b', date: DateTime(2026, 10, 1), label: '수행');
      expect(representativeEvent([a, b], now)?.id, 'b');
      expect(representativeEvent(const [], now), isNull);
    });

    test('compact excludes representative and past, sorts ascending, keeps today',
        () {
      final today = DayEvent(id: 't', date: DateTime(2026, 9, 26), label: '오늘');
      final soon = DayEvent(id: 's', date: DateTime(2026, 10, 1), label: '곧');
      final later = DayEvent(id: 'l', date: DateTime(2026, 10, 3), label: '나중');
      final past = DayEvent(id: 'p', date: DateTime(2026, 9, 1), label: '지남');
      final rep = later;
      final compact = compactUpcoming([today, soon, later, past], now, rep);
      expect(compact.map((e) => e.id).toList(), ['t', 's']); // no rep, no past
    });

    test('title limit is 15 code points', () {
      expect(dayEventMaxTitle, 15);
      final ok = DayEvent(date: DateTime(2026, 10, 1), label: '가' * 15);
      expect(ok.label.runes.length, 15);
      expect(() => DayEvent(date: DateTime(2026, 10, 1), label: '가' * 16),
          throwsFormatException);
    });
  });

  group('controller', () {
    test('add, primary persistence, delete-primary fallback', () async {
      final repo = FakeDayEventRepository(() => 'A');
      final c = await _authed('A', repo);
      addTearDown(c.dispose);
      await c.read(dayEventsProvider.future);
      final ctrl = c.read(dayEventsProvider.notifier);

      await ctrl.addEvent(DateTime(2026, 10, 1), '수행', primary: false);
      await ctrl.addEvent(DateTime(2027, 11, 18), '수능', primary: false);
      var events = c.read(dayEventsProvider).value!;
      expect(events.length, 2);

      // Choose the far 수능 as representative; it must win over the nearer 수행.
      final suneung = events.firstWhere((e) => e.label == '수능');
      expect(await ctrl.setPrimary(suneung.id!), isTrue);
      events = c.read(dayEventsProvider).value!;
      expect(representativeEvent(events, now)?.label, '수능');

      // Deleting the primary falls back to the nearest upcoming (no auto-write).
      final primary = events.firstWhere((e) => e.isPrimary);
      await ctrl.deleteEvent(primary.id!);
      events = c.read(dayEventsProvider).value!;
      expect(events.any((e) => e.isPrimary), isFalse);
      expect(representativeEvent(events, now)?.label, '수행');
    });

    test('edit updates the event', () async {
      final repo = FakeDayEventRepository(() => 'A');
      final c = await _authed('A', repo);
      addTearDown(c.dispose);
      await c.read(dayEventsProvider.future);
      final ctrl = c.read(dayEventsProvider.notifier);
      await ctrl.addEvent(DateTime(2026, 10, 1), '수행');
      final id = c.read(dayEventsProvider).value!.single.id!;
      await ctrl.editEvent(id, DateTime(2026, 10, 2), '국어 수행');
      final e = c.read(dayEventsProvider).value!.single;
      expect(e.label, '국어 수행');
      expect(e.displayDate, '2026.10.02.(금)');
    });

    test('account isolation: switching owner does not leak events', () async {
      final repo = FakeDayEventRepository(() => 'A');
      // Owner A stores an event.
      final a = await _authed('A', repo);
      await a.read(dayEventsProvider.future);
      await a.read(dayEventsProvider.notifier).addEvent(DateTime(2026, 10, 1), 'A일정');
      expect(a.read(dayEventsProvider).value!.length, 1);
      a.dispose();
      // A different owner sees none of A's events.
      final repoB = FakeDayEventRepository(() => 'B');
      final b = await _authed('B', repoB);
      addTearDown(b.dispose);
      expect(await b.read(dayEventsProvider.future), isEmpty);
    });

    test('save failure is not shown as success and does not mutate state', () async {
      final c = await _authed('A', ThrowingDayEventRepository());
      addTearDown(c.dispose);
      final ctrl = c.read(dayEventsProvider.notifier);
      await expectLater(
          ctrl.addEvent(DateTime(2026, 10, 1), '수능'), throwsA(isA<Exception>()));
      expect(c.read(dayEventsProvider).value, isEmpty);
    });

    test('guest events stay in session and never reach the repository', () async {
      var repoTouched = false;
      final repo = FakeDayEventRepository(() {
        repoTouched = true;
        return 'never';
      });
      final auth = StreamController<AuthStatus>();
      final c = ProviderContainer(overrides: [
        authStateProvider.overrideWith((ref) => auth.stream),
        dayEventRepositoryProvider.overrideWith((ref) => repo),
      ]);
      final sub = c.listen(dayEventsProvider, (_, _) {});
      auth.add(const AuthStatus(null));
      await Future<void>.delayed(Duration.zero);
      await c.read(dayEventsProvider.future);
      await c.read(dayEventsProvider.notifier).addEvent(DateTime(2026, 10, 1), '게스트');
      expect(c.read(dayEventsProvider).value!.single.label, '게스트');
      expect(repoTouched, isFalse);
      // Signing in must not inherit guest session events.
      auth.add(const AuthStatus('A'));
      await Future<void>.delayed(Duration.zero);
      await c.read(dayEventsProvider.future);
      expect(c.read(dayEventsProvider).value, isEmpty);
      sub.close();
      c.dispose();
      await auth.close();
    });
  });

  group('home card', () {
    Future<ProviderContainer> pumpCard(
      WidgetTester tester,
      List<DayEvent> seeded, {
      double scale = 1.0,
      Size size = const Size(360, 640),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = FakeDayEventRepository(() => 'A');
      final c = ProviderContainer(overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(const AuthStatus('A'))),
        dayEventRepositoryProvider.overrideWith((ref) => repo),
        dayTargetClockProvider.overrideWith((ref) => Stream.value(now)),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Padding(padding: EdgeInsets.all(20), child: DayTargetCard()),
          ),
        ),
      ));
      await tester.pumpAndSettle(); // auth + events settle through the widget
      final ctrl = c.read(dayEventsProvider.notifier);
      for (final e in seeded) {
        await ctrl.addEvent(e.date, e.label, primary: e.isPrimary);
      }
      await tester.pumpAndSettle();
      return c;
    }

    for (final scale in [1.0, 2.0]) {
      for (final width in [360.0, 428.0]) {
        testWidgets('compact list, more/less, no overflow ${width}px ${scale}x',
            (tester) async {
          final seeded = [
            DayEvent(date: DateTime(2027, 11, 18), label: '수능 대표 일정 테스트', isPrimary: true),
            DayEvent(date: DateTime(2026, 10, 1), label: '국어 수행평가 매우 긴 제목'),
            DayEvent(date: DateTime(2026, 10, 3), label: '영어 수행평가'),
            DayEvent(date: DateTime(2026, 10, 6), label: '중간고사'),
            DayEvent(date: DateTime(2026, 10, 8), label: '수학 수행'),
          ];
          final c = await pumpCard(tester, seeded, scale: scale,
              size: Size(width, 900));
          addTearDown(c.dispose);

          // Representative (primary) hierarchy: date shown in the heading.
          expect(find.textContaining('수능 대표 일정 테스트 · 2027.11.18.(목)'),
              findsOneWidget);
          // Collapsed: 4 upcoming non-primary -> show 2, hide 2.
          expect(find.text('일정 2개 더보기 ˅'), findsOneWidget);
          expect(find.textContaining('국어 수행평가 매우 긴 제목 · 2026.10.01.(목)'),
              findsOneWidget);

          await tester.tap(find.text('일정 2개 더보기 ˅'));
          await tester.pumpAndSettle();
          expect(find.text('접기 ˄'), findsOneWidget);
          expect(find.textContaining('수학 수행 · 2026.10.08.(목)'), findsOneWidget);

          await tester.tap(find.text('접기 ˄'));
          await tester.pumpAndSettle();
          expect(find.text('일정 2개 더보기 ˅'), findsOneWidget);

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('manage sheet opens with add + radio, no overflow 360px 2x',
        (tester) async {
      final c = await pumpCard(
        tester,
        [
          DayEvent(date: DateTime(2027, 11, 18), label: '수능', isPrimary: true),
          DayEvent(date: DateTime(2026, 10, 1), label: '국어 수행평가 긴 이름'),
        ],
        scale: 2.0,
        size: const Size(360, 900),
      );
      addTearDown(c.dispose);
      await tester.tap(find.widgetWithText(TextButton, '설정'));
      await tester.pumpAndSettle();
      expect(find.text('D-Day 관리'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '일정 추가'), findsOneWidget);
      expect(find.byType(Radio<String>), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('representative shows one strong row: title·date + D-N + 설정',
        (tester) async {
      final rep = DayEvent(date: DateTime(2026, 11, 13), label: '수능', isPrimary: true);
      final c = await pumpCard(tester, [rep]);
      addTearDown(c.dispose);
      expect(find.textContaining('수능 · ${rep.displayDate}'), findsOneWidget);
      expect(find.text(rep.dLabel(now)), findsOneWidget); // e.g. D-48
      expect(find.widgetWithText(TextButton, '설정'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('delete confirm: 취소 keeps the event, 삭제 removes it',
        (tester) async {
      final c = await pumpCard(tester, [
        DayEvent(date: DateTime(2027, 11, 18), label: '수능', isPrimary: true),
        DayEvent(date: DateTime(2026, 10, 1), label: '국어 수행'),
      ]);
      addTearDown(c.dispose);
      await tester.tap(find.widgetWithText(TextButton, '설정'));
      await tester.pumpAndSettle();
      expect(find.byType(Radio<String>), findsNWidgets(2));

      // Cancel path: dialog closes, both events remain.
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('일정 삭제'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('일정 삭제'), findsNothing);
      expect(find.byType(Radio<String>), findsNWidgets(2));

      // Confirm path: dialog closes, the non-primary event is removed.
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('일정 삭제'), findsNothing);
      expect(find.byType(Radio<String>), findsOneWidget);
      expect(c.read(dayEventsProvider).value!.length, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
