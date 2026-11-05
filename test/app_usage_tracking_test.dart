import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/analytics/analytics_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/presentation/content_detail_page.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/analytics/usage_tracking.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_events.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';

class Recording implements AnalyticsService {
  final events = <({String name, Map<String, Object?> params})>[];
  final screens = <String>[];
  @override
  void logEvent(String name, [Map<String, Object?>? params]) =>
      events.add((name: name, params: sanitizeAnalyticsParams(params)));
  @override
  void setScreen(String name) => screens.add(name);
  @override
  void setUserId(String? id) {}
}

void main() {
  testWidgets(
    'detail success logs Registry once, refresh does not log, failure does not log',
    (tester) async {
      const id = '12345678-1234-1234-1234-123456789abc';
      final service = Recording();
      final scope = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(service),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
          contentResourcesProvider(id).overrideWith((ref) async => []),
          contentDetailProvider('fixture').overrideWith(
            (ref) async => const ContentItem(
              id: id,
              slug: 'fixture',
              contentType: 'education_column',
              title: 'TEST 자료',
              sourceUrl: '',
              isActive: true,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: ContentDetailPage(slug: 'fixture')),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.events.where((e) => e.name == 'material_open').length, 1);
      scope.invalidate(contentDetailProvider('fixture'));
      await tester.pumpAndSettle();
      expect(service.events.where((e) => e.name == 'material_open').length, 1);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      final failed = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(service),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
          contentDetailProvider('fixture')
              .overrideWith((ref) async => throw StateError('fixture failure')),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: failed,
          child: const MaterialApp(home: ContentDetailPage(slug: 'fixture')),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.events.where((e) => e.name == 'material_open').length, 1);
      await tester.pumpWidget(const SizedBox());
      failed.dispose();
    },
  );

  testWidgets(
    'actual GoRouter records initial, push, pop and suppresses refresh',
    (tester) async {
      final service = Recording();
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/materials',
            builder: (_, _) => const Scaffold(body: Text('materials')),
          ),
        ],
      );
      final unbind = bindUsageTracking(router, UsageTracker(service));
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(service.screens, ['home']);
      router.push('/materials');
      await tester.pumpAndSettle();
      router.refresh();
      await tester.pumpAndSettle();
      expect(service.screens, ['home', 'materials']);
      router.pop();
      await tester.pumpAndSettle();
      expect(service.screens, ['home', 'materials', 'home']);
      await tester.pumpWidget(const SizedBox());
      unbind();
      router.dispose();
    },
  );

  test(
    'navigation counts real return visits but not rebuild/query changes',
    () {
      final service = Recording(), tracker = UsageTracker(Recording());
      final t = UsageTracker(service);
      for (final route in [
        '/home',
        '/home',
        '/materials?q=private',
        '/materials?q=other',
        '/home',
      ]) {
        t.routeChanged(Uri.parse(route));
      }
      expect(service.screens, ['home', 'materials', 'home']);
      expect(service.events.length, 3);
      expect(service.events.every((e) => e.name == 'menu_view'), isTrue);
      expect(service.events.toString(), isNot(contains('private')));
      tracker.routeChanged(Uri.parse('/auth?access_token=secret'));
    },
  );
  test('unrecognized routes and query content never leave device', () {
    final s = Recording();
    final t = UsageTracker(s);
    for (final route in [
      '/auth?email=a@b.com',
      '/my/admin/analytics',
      '/lab/private/user-id',
    ]) {
      t.routeChanged(Uri.parse(route));
    }
    expect(s.events, isEmpty);
    expect(s.screens, isEmpty);
  });
  test(
    'material event once per instance; repeat visit counts; source preserved',
    () {
      const id = '12345678-1234-1234-1234-123456789abc';
      final s = Recording();
      final t = UsageTracker(s);
      t.routeChanged(Uri.parse('/materials'));
      t.routeChanged(Uri.parse('/materials/test-slug'));
      expect(t.materialSource, 'materials');
      final view = MaterialViewTracker(s, t.materialSource);
      view.loaded(id);
      view.loaded(id);
      view.loaded('not-a-registry-id');
      expect(s.events.where((e) => e.name == 'material_open').length, 1);
      MaterialViewTracker(s, 'recent').loaded(id);
      expect(s.events.where((e) => e.name == 'material_open').length, 2);
      expect(s.events.last.params['content_item_id'], id);
      expect(s.events.last.params['entry_source'], 'recent');
    },
  );
  test('initial deep link is direct and stale menu is not reused', () {
    final t = UsageTracker(Recording());
    t.routeChanged(Uri.parse('/materials/first'));
    expect(t.materialSource, 'direct');
    t.routeChanged(Uri.parse('/materials'));
    t.routeChanged(Uri.parse('/auth'));
    t.routeChanged(Uri.parse('/materials/next'));
    expect(t.materialSource, 'other');
  });
  test('new context is allowlisted but PII remains excluded', () {
    expect(
      sanitizeAnalyticsParams({
        'content_item_id': 'id',
        'menu_id': 'home',
        'entry_source': 'materials',
        'schema_version': 1,
        'email': 'a@b.com',
        'access_token': 'secret',
      }).keys,
      unorderedEquals([
        'content_item_id',
        'menu_id',
        'entry_source',
        'schema_version',
      ]),
    );
  });
}
