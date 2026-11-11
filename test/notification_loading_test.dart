import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/notifications/application/notification_providers.dart';
import 'package:legendstudy_app/features/notifications/data/notification_repository.dart';
import 'package:legendstudy_app/features/notifications/domain/notification_models.dart';
import 'package:legendstudy_app/features/notifications/presentation/notifications_page.dart';

class _Api implements NotificationApi {
  Future<NotificationFeed> Function() response = () async =>
      NotificationFeed.empty;
  int reads = 0;
  @override
  Future<NotificationFeed> list({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) {
    reads++;
    return response();
  }

  @override
  Future<int> unreadCount() async => 0;
  @override
  Future<bool> markRead(String id) async => true;
  @override
  Future<void> markAllRead() async {}
}

void main() {
  Future<ProviderContainer> mount(
    WidgetTester t,
    _Api api, {
    Stream<AuthStatus>? auth,
  }) async {
    final c = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => auth ?? Stream.value(const AuthStatus('A')),
        ),
        notificationRepositoryProvider.overrideWithValue(api),
      ],
    );
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const Scaffold(body: NotificationsPage()),
        ),
        GoRoute(
          path: '/notices',
          builder: (_, __) => const Scaffold(body: Text('기존 공지사항 화면')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(c.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    return c;
  }

  testWidgets('missing RPC ends loading without automatic retry', (t) async {
    final api = _Api()
      ..response = () => Future.error(
        const PostgrestException(message: 'missing', code: 'PGRST202'),
      );
    await mount(t, api);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('알림을 불러오지 못했습니다.'), findsOneWidget);
    await t.pump(const Duration(seconds: 60));
    expect(api.reads, 1);
    expect(find.text('새로운 알림이 없습니다.'), findsNothing);
  });
  testWidgets('only a successful empty result shows empty copy', (t) async {
    await mount(t, _Api());
    expect(find.text('새로운 알림이 없습니다.'), findsOneWidget);
    expect(find.text('새로운 소식이 도착하면\n이곳에서 확인할 수 있어요.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('다시 시도'), findsNothing);
  });
  for (final failure in [
    const PostgrestException(message: 'unauthorized', code: '401'),
    const FormatException('bad payload'),
    StateError('network offline'),
  ]) {
    testWidgets(
      'read failure is error, never empty: ${failure.runtimeType} $failure',
      (t) async {
        await mount(t, _Api()..response = () => Future.error(failure));
        expect(find.text('알림을 불러오지 못했습니다.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('새로운 알림이 없습니다.'), findsNothing);
      },
    );
  }
  testWidgets('timeout shows error and retry shares one pending request', (
    t,
  ) async {
    final pending = Completer<NotificationFeed>();
    final api = _Api()..response = () => pending.future;
    final c = await mount(t, api);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.pump(const Duration(seconds: 9));
    await t.pump();
    expect(find.text('알림을 불러오지 못했습니다.'), findsOneWidget);
    final next = Completer<NotificationFeed>();
    api.response = () => next.future;
    final controller = c.read(notificationFeedProvider.notifier);
    final one = controller.refresh();
    final two = controller.refresh();
    await t.pump();
    expect(api.reads, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
    next.complete(NotificationFeed.empty);
    await t.pump();
    await t.pump();
    await Future.wait([one, two]);
    expect(find.text('새로운 알림이 없습니다.'), findsOneWidget);
    pending.complete(NotificationFeed.empty);
    await t.pump();
    expect(api.reads, 2);
  });
  testWidgets('unresolved authentication has a finite loading deadline', (
    t,
  ) async {
    final auth = StreamController<AuthStatus>();
    addTearDown(auth.close);
    final api = _Api();
    await mount(t, api, auth: auth.stream);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.pump(const Duration(seconds: 9));
    await t.pump();
    expect(find.text('알림을 불러오지 못했습니다.'), findsOneWidget);
    expect(api.reads, 0);
    auth.add(const AuthStatus('A'));
    await t.pumpAndSettle();
    await t.tap(find.text('다시 시도'));
    await t.pumpAndSettle();
    expect(find.text('새로운 알림이 없습니다.'), findsOneWidget);
  });
  testWidgets('auth error and signed out are not fabricated empty inboxes', (
    t,
  ) async {
    final auth = StreamController<AuthStatus>();
    addTearDown(auth.close);
    final api = _Api();
    await mount(t, api, auth: auth.stream);
    auth.addError(StateError('auth error'));
    await t.pump();
    await t.pump();
    expect(find.text('알림을 불러오지 못했습니다.'), findsOneWidget);
    auth.add(const AuthStatus(null));
    await t.pumpAndSettle();
    expect(find.text('알림을 불러오지 못했습니다.'), findsOneWidget);
    expect(api.reads, 0);
  });
  testWidgets('notices navigation works during loading and error', (t) async {
    final pending = Completer<NotificationFeed>();
    final api = _Api()..response = () => pending.future;
    await mount(t, api);
    await t.tap(find.text('공지사항'));
    await t.pumpAndSettle();
    expect(find.text('기존 공지사항 화면'), findsOneWidget);
    pending.completeError(StateError('late failure'));
    await t.pump(const Duration(seconds: 9));
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets('late account A result cannot replace account B inbox', (
    t,
  ) async {
    final auth = StreamController<AuthStatus>();
    addTearDown(auth.close);
    final pending = Completer<NotificationFeed>();
    final api = _Api()..response = () => pending.future;
    await mount(t, api, auth: auth.stream);
    auth.add(const AuthStatus('A'));
    await t.pump();
    await t.pump();
    api.response = () => Future.value(NotificationFeed.empty);
    auth.add(const AuthStatus(null));
    await t.pump();
    await t.pump();
    auth.add(const AuthStatus('B'));
    await t.pump();
    await t.pump();
    expect(find.text('새로운 알림이 없습니다.'), findsOneWidget);
    pending.complete(
      NotificationFeed(
        items: [
          UserNotification(
            id: 'A-private',
            type: 'x',
            title: 'A private',
            body: '',
            target: NotificationTarget.unknown,
            targetId: null,
            createdAt: null,
            isRead: false,
          ),
        ],
        unread: 1,
        limit: 50,
        offset: 0,
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 9));
    expect(find.text('A private'), findsNothing);
    expect(find.text('새로운 알림이 없습니다.'), findsOneWidget);
  });
  testWidgets('reentering the screen makes one fresh request; notices remain usable on error', (t) async {
    final api=_Api()..response=()=>Future.error(StateError('offline'));
    await mount(t,api);
    expect(api.reads,1);
    final router=GoRouter.of(t.element(find.byType(NotificationsPage)));
    await t.tap(find.text('공지사항'));
    await t.pumpAndSettle();
    expect(find.text('기존 공지사항 화면'),findsOneWidget);
    router.pop();await t.pumpAndSettle();
    expect(api.reads,1);
    expect(find.text('알림을 불러오지 못했습니다.'),findsOneWidget);
    router.go('/notices');await t.pumpAndSettle();
    router.go('/notifications');await t.pumpAndSettle();
    expect(api.reads,2);
    expect(find.text('알림을 불러오지 못했습니다.'),findsOneWidget);
  });
  testWidgets('disposed screen ignores a delayed response without async UI errors', (t) async {
    final delayed=Completer<NotificationFeed>();
    final api=_Api()..response=()=>delayed.future;
    final c=await mount(t,api);
    await t.pumpWidget(const SizedBox.shrink());
    c.dispose();
    delayed.complete(NotificationFeed.empty);
    await t.pump(const Duration(seconds:9));
    expect(t.takeException(),isNull);
  });

}
