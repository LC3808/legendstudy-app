import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/notifications/application/notification_providers.dart';
import 'package:legendstudy_app/features/notifications/data/notification_repository.dart';
import 'package:legendstudy_app/features/notifications/domain/notification_models.dart';
import 'package:legendstudy_app/features/notifications/presentation/notification_bell.dart';
import 'package:legendstudy_app/features/notifications/presentation/notifications_page.dart';

/// In-memory consumer contract used in place of the Supabase-backed RPCs.
class _FakeApi implements NotificationApi {
  _FakeApi(this._feed, {this.markReadOwner = true, this.throwOnCount = false});
  NotificationFeed _feed;
  final bool markReadOwner;
  final bool throwOnCount;
  int markReadCalls = 0;
  int markAllCalls = 0;

  @override
  Future<NotificationFeed> list({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async => _feed;

  @override
  Future<int> unreadCount() async {
    if (throwOnCount) throw Exception('backend down');
    return _feed.items.where((n) => !n.isRead).length;
  }

  @override
  Future<bool> markRead(String id) async {
    markReadCalls++;
    return markReadOwner;
  }

  @override
  Future<void> markAllRead() async {
    markAllCalls++;
  }
}

UserNotification _n(
  String id, {
  String type = 'essay_evaluation_complete',
  String target = 'essay_evaluation',
  bool read = false,
}) => UserNotification(
  id: id,
  type: type,
  title: 't-$id',
  body: 'b-$id',
  target: NotificationTarget.fromServer(target),
  targetId: null,
  createdAt: DateTime.now(),
  isRead: read,
);

NotificationFeed _feed(List<UserNotification> items) => NotificationFeed(
  items: items,
  unread: items.where((n) => !n.isRead).length,
  limit: 50,
  offset: 0,
);

ProviderContainer _container({
  required bool signedIn,
  NotificationApi? api,
}) {
  final c = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(AuthStatus(signedIn ? 'u1' : null)),
      ),
      if (api != null) notificationRepositoryProvider.overrideWithValue(api),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('NotificationTarget mapping', () {
    test('server values map to the allowlist', () {
      expect(NotificationTarget.fromServer('inquiry'), NotificationTarget.inquiry);
      expect(
        NotificationTarget.fromServer('essay_evaluation'),
        NotificationTarget.essayEvaluation,
      );
      expect(
        NotificationTarget.fromServer('math_evaluation'),
        NotificationTarget.mathEvaluation,
      );
      expect(
        NotificationTarget.fromServer('payment_order'),
        NotificationTarget.paymentOrder,
      );
      expect(
        NotificationTarget.fromServer('credit_history'),
        NotificationTarget.creditHistory,
      );
      expect(
        NotificationTarget.fromServer('essay_lab'),
        NotificationTarget.essayLab,
      );
    });

    test('unknown / null are not navigable (fail safe, no URL)', () {
      expect(NotificationTarget.fromServer('something_new'), NotificationTarget.unknown);
      expect(NotificationTarget.fromServer(null), NotificationTarget.unknown);
      expect(NotificationTarget.unknown.route, isNull);
      expect(NotificationTarget.unknown.canNavigate, isFalse);
    });

    test('known targets route to existing in-app screens', () {
      expect(NotificationTarget.inquiry.route, '/my/feedback');
      expect(NotificationTarget.essayEvaluation.route, '/lab');
      expect(NotificationTarget.mathEvaluation.route, '/lab');
      expect(NotificationTarget.creditHistory.route, '/lab');
      expect(NotificationTarget.paymentOrder.route, '/lab');
      expect(NotificationTarget.essayLab.route, '/lab');
    });
  });

  group('DTO parsing (notification-v1)', () {
    test('item read state derives from is_read or read_at', () {
      final unread = UserNotification.fromJson({
        'id': 'a',
        'type': 'x',
        'title': 'T',
        'body': 'B',
        'target_type': 'inquiry',
        'target_id': null,
        'created_at': '2026-10-05T01:00:00+00:00',
        'read_at': null,
        'is_read': false,
      });
      expect(unread.isRead, isFalse);
      expect(unread.target, NotificationTarget.inquiry);
      expect(unread.createdAt, isNotNull);

      final readByFlag = UserNotification.fromJson({
        'id': 'b',
        'target_type': 'essay_lab',
        'read_at': null,
        'is_read': true,
      });
      expect(readByFlag.isRead, isTrue);

      final readByTimestamp = UserNotification.fromJson({
        'id': 'c',
        'target_type': 'inquiry',
        'read_at': '2026-10-05T02:00:00+00:00',
        'is_read': false,
      });
      expect(readByTimestamp.isRead, isTrue);
    });

    test('feed parses items + unread and survives malformed payloads', () {
      final feed = NotificationFeed.fromJson({
        'dto_version': 'notification-v1',
        'limit': 20,
        'offset': 0,
        'unread': 2,
        'items': [
          {'id': '1', 'target_type': 'inquiry', 'is_read': false},
          {'id': '2', 'target_type': 'credit_history', 'is_read': true},
          'garbage',
        ],
      });
      expect(feed.items.length, 2);
      expect(feed.unread, 2);

      final missing = NotificationFeed.fromJson({'dto_version': 'notification-v1'});
      expect(missing.items, isEmpty);
      expect(missing.unread, 0);
    });
  });

  group('unread count provider (server-authoritative)', () {
    test('signed out returns 0 without calling the backend', () async {
      final c = _container(signedIn: false, api: _FakeApi(_feed([_n('1')])));
      await c.read(authStateProvider.future);
      expect(await c.read(unreadNotificationCountProvider.future), 0);
    });

    test('signed in returns the backend count', () async {
      final c = _container(
        signedIn: true,
        api: _FakeApi(_feed([_n('1'), _n('2'), _n('3', read: true)])),
      );
      await c.read(authStateProvider.future);
      expect(await c.read(unreadNotificationCountProvider.future), 2);
    });

    test('backend failure degrades to 0 (never blocks the bell)', () async {
      final c = _container(
        signedIn: true,
        api: _FakeApi(_feed([_n('1')]), throwOnCount: true),
      );
      await c.read(authStateProvider.future);
      expect(await c.read(unreadNotificationCountProvider.future), 0);
    });
  });

  group('feed controller', () {
    test('signed out yields an empty feed', () async {
      final c = _container(signedIn: false, api: _FakeApi(_feed([_n('1')])));
      await c.read(authStateProvider.future);
      final feed = await c.read(notificationFeedProvider.future);
      expect(feed.items, isEmpty);
    });

    test('mark read on an owned row reduces unread', () async {
      final api = _FakeApi(_feed([_n('1'), _n('2')]));
      final c = _container(signedIn: true, api: api);
      await c.read(authStateProvider.future);
      await c.read(notificationFeedProvider.future);
      await c.read(notificationFeedProvider.notifier).markRead('1');
      final feed = c.read(notificationFeedProvider).value!;
      expect(feed.items.firstWhere((n) => n.id == '1').isRead, isTrue);
      expect(feed.unread, 1);
      expect(api.markReadCalls, 1);
    });

    test('mark read on a non-owned row changes nothing', () async {
      final api = _FakeApi(_feed([_n('1')]), markReadOwner: false);
      final c = _container(signedIn: true, api: api);
      await c.read(authStateProvider.future);
      await c.read(notificationFeedProvider.future);
      await c.read(notificationFeedProvider.notifier).markRead('1');
      final feed = c.read(notificationFeedProvider).value!;
      expect(feed.items.single.isRead, isFalse);
      expect(feed.unread, 1);
    });

    test('mark all read clears unread', () async {
      final api = _FakeApi(_feed([_n('1'), _n('2'), _n('3')]));
      final c = _container(signedIn: true, api: api);
      await c.read(authStateProvider.future);
      await c.read(notificationFeedProvider.future);
      await c.read(notificationFeedProvider.notifier).markAllRead();
      final feed = c.read(notificationFeedProvider).value!;
      expect(feed.items.every((n) => n.isRead), isTrue);
      expect(feed.unread, 0);
      expect(api.markAllCalls, 1);
    });
  });

  group('UI', () {
    Widget host(Widget child, ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: child)),
    );

    testWidgets('bell shows the server unread badge', (t) async {
      final c = _container(
        signedIn: true,
        api: _FakeApi(_feed([_n('1'), _n('2')])),
      );
      await c.read(authStateProvider.future);
      await t.pumpWidget(host(const NotificationBell(), c));
      await t.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('badge caps at 99+', (t) async {
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('u1')),
          ),
          unreadNotificationCountProvider.overrideWith((ref) async => 150),
        ],
      );
      addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      await t.pumpWidget(host(const NotificationBell(), c));
      await t.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('signed-out bell shows no badge', (t) async {
      final c = _container(signedIn: false, api: _FakeApi(_feed([_n('1')])));
      await c.read(authStateProvider.future);
      await t.pumpWidget(host(const NotificationBell(), c));
      await t.pumpAndSettle();
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('empty inbox renders an empty state at 360px', (t) async {
      t.view.physicalSize = const Size(360, 720);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final c = _container(signedIn: true, api: _FakeApi(_feed([])));
      await c.read(authStateProvider.future);
      await t.pumpWidget(host(const NotificationsPage(), c));
      await t.pumpAndSettle();
      expect(find.text('받은 알림이 없어요.'), findsOneWidget);
    });

    testWidgets('inbox lists items with a 모두 읽음 action under text scaling', (
      t,
    ) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final c = _container(
        signedIn: true,
        api: _FakeApi(_feed([_n('1'), _n('2', read: true)])),
      );
      await c.read(authStateProvider.future);
      await t.pumpWidget(host(const NotificationsPage(), c));
      await t.pumpAndSettle();
      expect(find.text('t-1'), findsOneWidget);
      expect(find.text('모두 읽음'), findsOneWidget);
    });
  });
}
