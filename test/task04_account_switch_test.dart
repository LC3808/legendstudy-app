import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/applications/application_repository.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';
import 'package:legendstudy_app/features/home/university_news/university_news.dart';
import 'package:legendstudy_app/features/universities/data/university_repository.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';

import 'support/home_test_support.dart';
import 'support/onboarding_override.dart';
import 'university_news_test.dart' as fixtures;

class _Interests implements UniversityRepository {
  @override
  Future<List<InterestedUniversity>> listInterested() async => [
    fixtures.interest,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'selected university card survives hidden Home account switch without stale owner results',
    (t) async {
      final events = StreamController<AuthStatus>.broadcast();
      String? owner = 'a';
      final config = HomeConfiguration(
        defaultHomeVisibility.keys.map(
          (id) => HomeCardChoice(id, id == 'university_news'),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => events.stream),
          onboardedProfileOverride,
          homeConfigurationRepositoryProvider.overrideWith((ref) {
            final id = ref.watch(authStateProvider).asData?.value.userId;
            return HomeConfigurationRepository(
              owner: id,
              currentOwner: () => owner,
              cache: MemoryHomeCache(),
              rpc: (n, p) async => {...config.toJson(), 'revision': 1},
            );
          }),
          universityRepositoryProvider.overrideWithValue(_Interests()),
          applicationRepositoryProvider.overrideWith((ref) {
            final id = ref.watch(authStateProvider).asData?.value.userId;
            return id == null
                ? null
                : ApplicationRepository(
                    (n, p) async => {
                      'version': 'applications-v1',
                      'offset': 0,
                      'has_more': false,
                      'items': <Map<String, dynamic>>[],
                    },
                    () => owner,
                    id,
                  );
          }),
          universityNewsRepositoryProvider.overrideWithValue(
            UniversityNewsRepository(
              (n, p) async => {
                'version': 'university-news-v1',
                'snapshot_at': '2026-11-11T00:00:00Z',
                'has_more': false,
                'items': [
                  {
                    ...fixtures.news(scope: 'university'),
                    'title': '$owner official news',
                    'kind': 'news',
                    'precision': 'unknown',
                    'starts_on': null,
                    'expires_at': '2200-01-01T00:00:00Z',
                  },
                ],
              },
            ),
          ),
        ],
      );
      final router = container.read(routerProvider)..go('/home');
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LegendStudyApp(),
        ),
      );
      events.add(AuthStatus(owner));
      await t.pumpAndSettle();
      expect(find.text('a official news'), findsOneWidget);
      router.go('/my');
      await t.pumpAndSettle();
      owner = null;
      events.add(AuthStatus(owner));
      await t.pumpAndSettle();
      router.push('/auth');
      await t.pumpAndSettle();
      owner = 'b';
      events.add(AuthStatus(owner));
      await t.pumpAndSettle();
      router.go('/home');
      await t.pumpAndSettle();
      expect(find.text('b official news'), findsOneWidget);
      expect(find.text('a official news'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      container.dispose();
      await events.close();
      await t.pump();
    },
  );
}
