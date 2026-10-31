import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/notices/notices.dart';
import 'package:legendstudy_app/features/notifications/presentation/notification_bell.dart';
import 'package:legendstudy_app/features/notifications/application/notification_providers.dart';
import 'package:go_router/go_router.dart';

Notice notice() => Notice.fromJson({
  'notice_id': 'n1',
  'title': '공지 제목',
  'content': '공지 전문\n두 번째 문단',
  'category': 'general',
  'is_pinned': true,
  'is_read': false,
  'updated_at': '2026-10-31T00:00:00Z',
  'published_at': '2026-10-31T00:00:00Z',
});

class FakeNotices implements NoticeApi {
  int reads = 0;
  int lists = 0;
  bool hidden = false;
  bool failReceipt = false;
  @override
  Future<NoticeFeed> list(int offset) async {
    lists++;
    return NoticeFeed.fromJson({
      'items': <Map<String, dynamic>>[],
      'total': 0,
      'unread': 3,
    });
  }

  @override
  Future<Notice?> detail(String id) async => hidden ? null : notice();
  @override
  Future<bool> markRead(Notice n) async {
    reads++;
    if (failReceipt) throw Exception('offline');
    return true;
  }
}

void main() {
  for (final signed in [true, false]) {
    testWidgets('detail content and receipt signed=$signed', (tester) async {
      final api = FakeNotices();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noticeApiProvider.overrideWithValue(api),
            authStateProvider.overrideWith(
              (ref) => Stream.value(AuthStatus(signed ? 'u1' : null)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NoticeDetailPage(id: 'n1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('공지 전문\n두 번째 문단'), findsOneWidget);
      expect(api.reads, signed ? 1 : 0);
    });
  }
  testWidgets('failed receipt preserves readable detail', (tester) async {
    final api = FakeNotices()..failReceipt = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noticeApiProvider.overrideWithValue(api),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('u1')),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NoticeDetailPage(id: 'n1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('공지 제목'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('hidden detail never marked read', (tester) async {
    final api = FakeNotices()..hidden = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noticeApiProvider.overrideWithValue(api),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('u1')),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NoticeDetailPage(id: 'n1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('게시가 종료'), findsOneWidget);
    expect(api.reads, 0);
  });
  testWidgets(
    'home bell includes notice unread and guest opens public notices',
    (tester) async {
      final api = FakeNotices();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: NotificationBell()),
          ),
          GoRoute(
            path: '/notices',
            builder: (_, _) => const Scaffold(body: Text('공개 공지 화면')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noticeApiProvider.overrideWithValue(api),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.text('공개 공지 화면'), findsOneWidget);
      expect(api.reads, 0);
    },
  );
  testWidgets('bell aggregates notices and personal inbox counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('u1')),
          ),
          noticeUnreadProvider.overrideWith((ref) async => 3),
          unreadNotificationCountProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationBell())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
  });
  testWidgets('empty list readable on narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noticeApiProvider.overrideWithValue(FakeNotices()),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const Scaffold(body: NoticesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('게시된 공지사항이 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
