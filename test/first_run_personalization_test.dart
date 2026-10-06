import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/universities/application/university_providers.dart';
import 'package:legendstudy_app/features/universities/data/university_repository.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';
import 'package:legendstudy_app/features/universities/presentation/interested_universities_field.dart';
import 'package:legendstudy_app/features/profile/data/intended_major_repository.dart';
import 'package:legendstudy_app/features/profile/presentation/intended_major_field.dart';

class _FakeUniversityRepo implements UniversityRepository {
  _FakeUniversityRepo({List<University>? catalog, List<InterestedUniversity>? interested})
      : _catalog = catalog ?? const [],
        _interested = [...(interested ?? const [])];
  final List<University> _catalog;
  final List<InterestedUniversity> _interested;
  int addCalls = 0;
  int removeCalls = 0;

  @override
  Future<List<University>> searchCatalog(String query, {int limit = 20}) async =>
      _catalog
          .where((u) => u.name.contains(query.trim()))
          .take(limit)
          .toList();

  @override
  Future<List<InterestedUniversity>> listInterested() async =>
      List.unmodifiable(_interested);

  @override
  Future<void> addInterested(String universityId,
      {required String source, int? priority}) async {
    addCalls++;
    final uni = _catalog.firstWhere(
      (u) => u.id == universityId,
      orElse: () => University(id: universityId, name: 'U-$universityId'),
    );
    _interested.add(InterestedUniversity(
      id: 'row-${_interested.length + 1}',
      universityId: universityId,
      name: uni.name,
      priority: priority,
    ));
  }

  @override
  Future<void> removeInterested(String rowId) async {
    removeCalls++;
    _interested.removeWhere((u) => u.id == rowId);
  }
}

class _FakeMajorRepo implements IntendedMajorRepository {
  _FakeMajorRepo([this._value]);
  String? _value;
  @override
  Future<String?> fetch() async => _value;
  @override
  Future<void> set(String? value) async => _value = value;
}

ProviderContainer _container({
  required bool signedIn,
  UniversityRepository? uni,
  IntendedMajorRepository? major,
}) {
  final c = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(AuthStatus(signedIn ? 'u1' : null)),
      ),
      if (uni != null) universityRepositoryProvider.overrideWithValue(uni),
      if (major != null)
        intendedMajorRepositoryProvider.overrideWithValue(major),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('university models', () {
    test('University + InterestedUniversity parse embedded catalog', () {
      final u = University.fromJson({'id': 'a', 'name': '레전드대학교', 'slug': 'legend'});
      expect(u.name, '레전드대학교');
      final i = InterestedUniversity.fromJson({
        'id': 'row1',
        'university_id': 'a',
        'priority': 2,
        'universities': {'name': '레전드대학교', 'slug': 'legend'},
      });
      expect(i.universityId, 'a');
      expect(i.name, '레전드대학교');
      expect(i.priority, 2);
    });

    test('interest policy is 0..5, ~3 (optional, skippable)', () {
      expect(minInterested, 0);
      expect(maxInterested, 5);
      expect(recommendedInterested, 3);
    });
  });

  group('interest field taxonomy', () {
    test('broad fields are offered (no giant department catalog)', () {
      expect(interestFieldOptions, isNotEmpty);
      expect(interestFieldOptions.length, lessThan(12));
      expect(interestFieldOptions, contains('공학'));
    });
  });

  group('university providers', () {
    test('search returns empty for blank query / signed out', () async {
      final c = _container(signedIn: true, uni: _FakeUniversityRepo());
      await c.read(authStateProvider.future);
      expect(await c.read(universitySearchProvider('').future), isEmpty);
    });

    test('interested list is empty when signed out', () async {
      final c = _container(
        signedIn: false,
        uni: _FakeUniversityRepo(interested: [
          const InterestedUniversity(id: 'r1', universityId: 'a', name: 'A'),
        ]),
      );
      await c.read(authStateProvider.future);
      expect(await c.read(interestedUniversitiesProvider.future), isEmpty);
    });

    test('add respects the 5 cap and skips duplicates', () async {
      final catalog = [
        for (var i = 1; i <= 7; i++) University(id: 'u$i', name: '대학$i'),
      ];
      final repo = _FakeUniversityRepo(catalog: catalog);
      final c = _container(signedIn: true, uni: repo);
      await c.read(authStateProvider.future);
      await c.read(interestedUniversitiesProvider.future);
      final notifier = c.read(interestedUniversitiesProvider.notifier);
      for (var i = 1; i <= 7; i++) {
        await notifier.add('u$i', source: 'onboarding');
      }
      final list = c.read(interestedUniversitiesProvider).value!;
      expect(list.length, maxInterested); // capped at 5
      // duplicate is ignored
      await notifier.add('u1', source: 'onboarding');
      expect(c.read(interestedUniversitiesProvider).value!.length, maxInterested);
    });

    test('remove deletes the selection row', () async {
      final repo = _FakeUniversityRepo(catalog: [
        const University(id: 'u1', name: '대학1'),
      ]);
      final c = _container(signedIn: true, uni: repo);
      await c.read(authStateProvider.future);
      await c.read(interestedUniversitiesProvider.future);
      final notifier = c.read(interestedUniversitiesProvider.notifier);
      await notifier.add('u1', source: 'onboarding');
      final rowId = c.read(interestedUniversitiesProvider).value!.single.id;
      await notifier.remove(rowId);
      expect(c.read(interestedUniversitiesProvider).value, isEmpty);
      expect(repo.removeCalls, 1);
    });
  });

  group('intended major', () {
    test('null when signed out; reads value when signed in', () async {
      final out = _container(signedIn: false, major: _FakeMajorRepo('공학'));
      await out.read(authStateProvider.future);
      expect(await out.read(intendedMajorProvider.future), isNull);

      final inc = _container(signedIn: true, major: _FakeMajorRepo('공학'));
      await inc.read(authStateProvider.future);
      expect(await inc.read(intendedMajorProvider.future), '공학');
    });
  });

  group('UI', () {
    Widget host(Widget child, ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

    testWidgets('interested-universities field shows the cap hint at 360px',
        (t) async {
      t.view.physicalSize = const Size(360, 720);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final c = _container(signedIn: true, uni: _FakeUniversityRepo());
      await c.read(authStateProvider.future);
      await t.pumpWidget(
        host(const InterestedUniversitiesField(source: 'my'), c),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('최대 5개'), findsWidgets);
      expect(
        find.text('아직 선택한 관심 대학이 없어요. 나중에 설정해도 괜찮아요.'),
        findsOneWidget,
      );
    });

    testWidgets('major field marks undecided when unset', (t) async {
      final c = _container(signedIn: true, major: _FakeMajorRepo());
      await c.read(authStateProvider.future);
      await t.pumpWidget(host(const IntendedMajorField(), c));
      await t.pumpAndSettle();
      expect(find.text('아직 정하지 못했어요'), findsOneWidget);
      expect(find.text('공학'), findsOneWidget);
    });
  });
}
