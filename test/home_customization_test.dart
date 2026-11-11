import 'package:legendstudy_app/features/content/content_providers.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';
import 'package:legendstudy_app/features/home/customization/home_editor.dart';
import 'package:legendstudy_app/features/home/customization/home_registry.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/home/university_news/university_news.dart';

import 'support/home_test_support.dart';

void main() {
  test(
    'registry preserves APP75 defaults and IDs; optional new cards stay off',
    () {
      expect(homeCards.map((c) => c.id).toSet().length, homeCards.length);
      expect(homeCards.map((c) => c.id), defaultHomeVisibility.keys);
      expect(
        HomeConfiguration.defaults().cards
            .where((c) => c.visible)
            .map((c) => c.id),
        [
          'dday',
          'study_summary',
          'school_meals',
          'materials_search',
          'recent_documents',
          'recent_updates',
        ],
      );
      expect(
        homeCards.singleWhere((c) => c.id == 'university_news').defaultVisible,
        false,
      );
    },
  );
  test('damaged ordering recovers stably, duplicate removed, unknown retained, new hidden', () {
    final config = HomeConfiguration.fromJson({
      'config_version': 1,
      'cards': [
        {'card_id': 'future_card', 'visible': true, 'display_order': 4},
        {'card_id': 'school_meals', 'visible': false, 'display_order': 0},
        {'card_id': 'dday', 'visible': true, 'display_order': 0},
        {'card_id': 'dday', 'visible': false, 'display_order': 8},
      ],
    });
    expect(config.cards.take(3).map((c) => c.id), [
      'school_meals',
      'dday',
      'future_card',
    ]);
    expect(
      config.cards.singleWhere((c) => c.id == 'study_summary').visible,
      false,
    );
    expect(
      HomeConfiguration.fromJson(config.toJson()).toJson(),
      config.toJson(),
    );
  });
  test('reorder and hide preserve all ids; profile grade/school not configuration inputs', () {
    final config = HomeConfiguration.defaults()
        .toggle('school_meals', false)
        .reorder(0, 3);
    expect(config.cards[2].id, 'dday');
    expect(config.cards.length, defaultHomeVisibility.length);
    expect(config.toggle('school_meals', true).cards[1].visible, true);
  });
  test(
    'cache renders first; server wins; unset differs from explicit default',
    () async {
      final cache = MemoryHomeCache();
      cache.values['a'] = jsonEncode({
        ...HomeConfiguration.defaults().toggle('dday', false).toJson(),
        'revision': 1,
      });
      final repo = HomeConfigurationRepository(
        owner: 'a',
        currentOwner: () => 'a',
        cache: cache,
        rpc: (n, p) async => null,
      );
      final states = await repo.load().toList();
      expect(states.first.configuration.cards.first.visible, false);
      expect(states.first.confirmed, false);
      expect(states.last.exists, false);
      expect(states.last.configuration.cards.first.visible, true);
      final explicit = repo.decode({
        ...HomeConfiguration.defaults().toJson(),
        'revision': 2,
      }, confirmed: true);
      expect(explicit.exists, true);
    },
  );
  test('failed read returns defaults without cache overwrite; failed save never confirms', () async {
    final cache = MemoryHomeCache();
    final old = jsonEncode({
      ...HomeConfiguration.defaults().toggle('dday', false).toJson(),
      'revision': 2,
    });
    cache.values['a'] = old;
    final repo = HomeConfigurationRepository(
      owner: 'a',
      currentOwner: () => 'a',
      cache: cache,
      rpc: (n, p) async => throw StateError('offline'),
    );
    final states = await repo.load().toList();
    expect(states.last.failed, true);
    expect(states.last.confirmed, false);
    expect(states.last.configuration.cards.first.visible, true);
    expect(cache.values['a'], old);
    await expectLater(
      repo.save(HomeConfiguration.defaults(), 2),
      throwsStateError,
    );
    expect(cache.values['a'], old);
  });
  test(
    'successful server save survives cache failure and sends CAS revision',
    () async {
      final cache = MemoryHomeCache()..fail = true;
      final repo = HomeConfigurationRepository(
        owner: 'a',
        currentOwner: () => 'a',
        cache: cache,
        rpc: (n, p) async {
          expect(n, 'save_my_home_configuration');
          expect(p['p_revision'], 7);
          return {...p['p_config'] as Map<String, dynamic>, 'revision': 8};
        },
      );
      expect((await repo.save(HomeConfiguration.defaults(), 7)).revision, 8);
    },
  );
  test(
    'guest restart and two accounts never share caches or silently migrate',
    () async {
      final cache = MemoryHomeCache();
      final guest = HomeConfigurationRepository(
        owner: null,
        currentOwner: () => null,
        cache: cache,
      );
      await guest.save(HomeConfiguration.defaults().toggle('dday', false), 0);
      expect(
        (await guest.load().last).configuration.cards.first.visible,
        false,
      );
      final a = HomeConfigurationRepository(
        owner: 'a',
        currentOwner: () => 'a',
        cache: cache,
        rpc: (n, p) async => null,
      );
      expect((await a.load().last).configuration.cards.first.visible, true);
      expect(cache.values.keys.toSet(), {'guest', 'a'});
    },
  );
  test('account change during request rejects result and leaves new account cache intact', () async {
    String? owner = 'a';
    final gate = Completer<Object?>();
    final cache = MemoryHomeCache();
    final repo = HomeConfigurationRepository(
      owner: owner,
      currentOwner: () => owner,
      cache: cache,
      rpc: (n, p) => gate.future,
    );
    final pending = repo.save(HomeConfiguration.defaults(), 0);
    owner = 'b';
    gate.complete({...HomeConfiguration.defaults().toJson(), 'revision': 1});
    await expectLater(pending, throwsStateError);
    expect(cache.values, isEmpty);
  });
  testWidgets(
    'empty home keeps header/edit; hidden university card never fetches',
    (t) async {
      var calls = 0;
      final hidden = HomeConfiguration(
        defaultHomeVisibility.keys.map((id) => HomeCardChoice(id, false)),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            homeConfigurationProvider.overrideWith(
              (ref) => Stream.value(
                HomeConfigurationState(hidden, confirmed: true, exists: true),
              ),
            ),
            universityNewsProvider.overrideWith((ref) async {
              calls++;
              return const UniversityNewsFeed([], [], []);
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: HomePage())),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('홈에 표시할 카드를 선택해 주세요.'), findsOneWidget);
      expect(find.byTooltip('홈 편집'), findsOneWidget);
      expect(calls, 0);
    },
  );
  testWidgets(
    'pending configuration never starts requests for a saved hidden card',
    (t) async {
      var requests = 0;
      final settings = StreamController<HomeConfigurationState>();
      final hidden = HomeConfiguration(
        defaultHomeVisibility.keys.map((id) => HomeCardChoice(id, false)),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            homeConfigurationProvider.overrideWith((ref) => settings.stream),
            homeRecentContentProvider.overrideWith((ref) async {
              requests++;
              return [];
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: HomePage())),
        ),
      );
      await t.pump();
      expect(requests, 0);
      expect(find.byTooltip('홈 편집'), findsOneWidget);
      settings.add(
        HomeConfigurationState(hidden, confirmed: true, exists: true),
      );
      await t.pumpAndSettle();
      expect(requests, 0);
      expect(find.text('홈에 표시할 카드를 선택해 주세요.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      unawaited(settings.close());
    },
  );

  Future<void> editor(WidgetTester t, MemoryHomeCache cache) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
          homeCacheProvider.overrideWithValue(cache),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => openHomeEditor(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'editor draft toggle/cancel does not persist, save does, reopen restores',
    (t) async {
      final cache = MemoryHomeCache();
      await editor(t, cache);
      await t.tap(find.byType(Checkbox).first);
      await t.pump();
      await t.pageBack();
      await t.pumpAndSettle();
      expect(cache.values, isEmpty);
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, true);
      await t.tap(find.byType(Checkbox).first);
      await t.tap(find.text('저장'));
      await t.pumpAndSettle();
      expect(cache.values['guest'], isNotNull);
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, false);
      await t.tap(find.text('기본 구성으로 초기화'));
      await t.pump();
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, true);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(
        HomeConfiguration.fromJson(jsonDecode(cache.values['guest']!))
            .cards
            .first
            .visible,
        false,
      );
    },
  );
  testWidgets('drag reorder persists stable IDs without duplication', (
    t,
  ) async {
    final cache = MemoryHomeCache();
    await editor(t, cache);
    final handle = find.byType(ReorderableDragStartListener).first;
    final gesture = await t.startGesture(t.getCenter(handle));
    await t.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 170));
    await t.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await t.pumpAndSettle();
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    final config = HomeConfiguration.fromJson(
      jsonDecode(cache.values['guest']!),
    );
    expect(config.cards.first.id, isNot('dday'));
    expect(config.cards.map((c) => c.id).toSet().length, homeCards.length);
  });

  testWidgets('save failure retains editor draft for retry', (t) async {
    final cache = MemoryHomeCache();
    await editor(t, cache);
    await t.tap(find.byType(Checkbox).first);
    cache.fail = true;
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
    expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, false);
    cache.fail = false;
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
  testWidgets(
    'onboarding selector defaults and toggles without persistence or reorder',
    (t) async {
      var config = HomeConfiguration.defaults();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => HomeCardSelector(
                  value: config,
                  onChanged: (v) => setState(() => config = v),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ReorderableListView), findsNothing);
      await t.ensureVisible(find.text('나의 대학 소식'));
      await t.tap(find.text('나의 대학 소식'));
      await t.pump();
      expect(
        config.cards.singleWhere((c) => c.id == 'university_news').visible,
        true,
      );
    },
  );
}
