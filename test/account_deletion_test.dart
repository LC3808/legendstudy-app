import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/account_deletion.dart';
import 'package:legendstudy_app/features/auth/presentation/delete_account_page.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';

/// In-memory double. No network and no Supabase client is reachable here.
class FakeDeletionService implements AccountDeletionService {
  FakeDeletionService({this.error, this.delay});
  final Object? error;
  final Duration? delay;
  int calls = 0;

  @override
  bool get requiresRecentAuthentication => false;

  @override
  Future<void> deleteAccount() async {
    calls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;
  }
}

class MemoryStudyStore implements StudyLocalStore {
  MemoryStudyStore(this.document);
  Map<String, dynamic> document;
  bool failWrite = false;

  @override
  Future<Map<String, dynamic>> read() async => document;

  @override
  Future<void> write(Map<String, dynamic> next) async {
    if (failWrite) throw StateError('local disk failure');
    document = next;
  }
}

Map<String, dynamic> studyDoc() => {
  'version': 3,
  'owners': <String, dynamic>{
    'user-a': {'records': <dynamic>[], 'draft': null},
    'user-b': {'records': <dynamic>[], 'draft': null},
    'guest': {'records': <dynamic>[], 'draft': null},
  },
};

void main() {
  late GoRouter router;
  late MemoryStudyStore store;

  Future<void> mountPage(
    WidgetTester tester, {
    AccountDeletionService? service,
    AuthStatus auth = const AuthStatus('user-a'),
    Future<void> Function()? logout,
  }) async {
    store = MemoryStudyStore(studyDoc());
    router = GoRouter(
      initialLocation: '/my/delete-account',
      routes: [
        GoRoute(
          path: '/my/delete-account',
          builder: (_, _) => const Scaffold(body: DeleteAccountPage()),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/my',
          builder: (_, _) => const Scaffold(body: Text('MY')),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, _) => const Scaffold(body: Text('AUTH')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(service),
          if (logout != null)
            postDeleteSignOutProvider.overrideWithValue(logout),
          studyLocalStoreProvider.overrideWithValue(store),
          authStateProvider.overrideWith((ref) => Stream.value(auth)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  String currentPath() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> agreeAndDelete(
    WidgetTester tester, {
    bool confirm = true,
  }) async {
    await tester.tap(find.text('위 내용을 이해했어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '회원탈퇴'));
    await tester.pumpAndSettle();
    if (find.text('탈퇴하기').evaluate().isNotEmpty) {
      await tester.tap(find.text(confirm ? '탈퇴하기' : '취소'));
      await tester.pumpAndSettle();
    }
  }

  group('entry conditions', () {
    testWidgets('a guest is asked to sign in, not offered deletion', (
      tester,
    ) async {
      await mountPage(
        tester,
        service: FakeDeletionService(),
        auth: const AuthStatus(null),
      );
      expect(find.text('로그인한 뒤에 탈퇴할 수 있어요.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '회원탈퇴'), findsNothing);
    });

    testWidgets('an unconfigured endpoint says so and cannot be run', (
      tester,
    ) async {
      await mountPage(tester, service: null);
      expect(find.textContaining('현재 앱에서 회원탈퇴를 처리할 수 없어요'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '회원탈퇴'), findsNothing);
      expect(find.text('문의·건의사항'), findsOneWidget);
    });

    testWidgets('what is deleted is spelled out before anything happens', (
      tester,
    ) async {
      await mountPage(tester, service: FakeDeletionService());
      for (final item in deletedItems) {
        expect(find.text('· $item'), findsOneWidget);
      }
      for (final item in anonymizedItems) {
        expect(find.text('· $item'), findsOneWidget);
      }
    });
  });

  group('confirmation', () {
    testWidgets('understanding alone does not delete anything', (tester) async {
      final service = FakeDeletionService();
      await mountPage(tester, service: service);
      await tester.tap(find.text('위 내용을 이해했어요'));
      await tester.pumpAndSettle();
      expect(service.calls, 0);
    });

    testWidgets('the deletion button is dead until the box is ticked', (
      tester,
    ) async {
      await mountPage(tester, service: FakeDeletionService());
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '회원탈퇴'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('cancelling the final dialog deletes nothing', (tester) async {
      final service = FakeDeletionService();
      await mountPage(tester, service: service);
      await agreeAndDelete(tester, confirm: false);
      expect(service.calls, 0);
      expect(currentPath(), '/my/delete-account');
    });

    testWidgets('a second tap does not send a second deletion', (tester) async {
      final service = FakeDeletionService(
        delay: const Duration(milliseconds: 50),
      );
      await mountPage(tester, service: service);
      await tester.tap(find.text('위 내용을 이해했어요'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '회원탈퇴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('탈퇴하기'));
      await tester.pump(); // in flight
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(currentPath(), '/my/delete-account');
      await tester.tap(
        find.widgetWithText(FilledButton, '처리 중'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(service.calls, 1);
    });
  });

  group('outcome', () {
    testWidgets('a completed deletion clears this device and leaves', (
      tester,
    ) async {
      await mountPage(tester, service: FakeDeletionService());
      await agreeAndDelete(tester);
      expect(currentPath(), '/home');
      final owners = store.document['owners'] as Map;
      expect(owners.containsKey('user-a'), isFalse);
      expect(owners.keys.toSet(), {
        'user-b',
        'guest',
      }, reason: 'another account on this device must not be touched');
    });

    testWidgets(
      'server success survives local failure; retry never deletes twice',
      (tester) async {
        final service = FakeDeletionService();
        var logouts = 0;
        await mountPage(
          tester,
          service: service,
          logout: () async {
            logouts++;
          },
        );
        store.failWrite = true;
        await agreeAndDelete(tester);
        expect(service.calls, 1);
        expect(
          logouts,
          1,
          reason: 'logout still attempted when disk cleanup failed',
        );
        expect(find.text('계정 삭제 완료'), findsOneWidget);
        expect(find.textContaining('계정 삭제는 완료됐어요.'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, '회원탈퇴'), findsNothing);
        store.failWrite = false;
        await tester.tap(find.text('기기 정보 정리 다시 시도'));
        await tester.pumpAndSettle();
        expect(currentPath(), '/home');
        expect(service.calls, 1);
        expect(logouts, 1);
        expect((store.document['owners'] as Map).containsKey('user-b'), isTrue);
      },
    );
    testWidgets(
      'logout failure retries logout without another server request',
      (tester) async {
        final service = FakeDeletionService();
        var attempts = 0;
        await mountPage(
          tester,
          service: service,
          logout: () async {
            if (++attempts == 1) throw StateError('logout failed');
          },
        );
        await agreeAndDelete(tester);
        expect(find.text('계정 삭제 완료'), findsOneWidget);
        await tester.tap(find.text('기기 정보 정리 다시 시도'));
        await tester.pumpAndSettle();
        expect(service.calls, 1);
        expect(attempts, 2);
        expect(currentPath(), '/home');
      },
    );
    testWidgets('a refused deletion never claims success', (tester) async {
      final service = FakeDeletionService(
        error: const AccountDeletionException('admin_blocked'),
      );
      await mountPage(tester, service: service);
      await agreeAndDelete(tester);
      expect(currentPath(), '/my/delete-account');
      expect(find.textContaining('관리자 계정은'), findsOneWidget);
      expect(
        (store.document['owners'] as Map).containsKey('user-a'),
        isTrue,
        reason: 'local data survives a deletion that did not happen',
      );
    });

    testWidgets('a failure is localized and never raw', (tester) async {
      await mountPage(
        tester,
        service: FakeDeletionService(
          error: StateError('PostgrestException: permission denied for users'),
        ),
      );
      await agreeAndDelete(tester);
      expect(find.text(accountDeletionGenericFailure), findsOneWidget);
      expect(find.textContaining('permission denied'), findsNothing);
      expect(currentPath(), '/my/delete-account');
    });
  });

  group('messages', () {
    test('every failure code has user-facing Korean, never server text', () {
      for (final code in const [
        'unauthorized',
        'admin_blocked',
        'unavailable',
        'deletion_failed',
        'something_new',
      ]) {
        final message = accountDeletionMessage(AccountDeletionException(code));
        expect(message, isNotEmpty);
        expect(message, isNot(contains(code)));
        expect(message, isNot(contains('http')));
      }
      expect(
        accountDeletionMessage(Exception('boom')),
        accountDeletionGenericFailure,
      );
    });
  });

  group('local study purge', () {
    test('only the named owner is removed', () async {
      final store = MemoryStudyStore(studyDoc());
      await purgeStudyOwner(store, 'user-a');
      expect((store.document['owners'] as Map).keys.toSet(), {
        'user-b',
        'guest',
      });
    });

    test('an owner with nothing stored is a no-op', () async {
      final store = MemoryStudyStore(studyDoc());
      await purgeStudyOwner(store, 'user-zzz');
      expect((store.document['owners'] as Map).length, 3);
    });
  });

  group('configuration', () {
    test('account deletion is off unless the build turns it on', () {
      expect(const AppConfig().accountDeletionEnabled, isFalse);
    });
  });
}
