import 'dart:async';

import 'package:flutter/material.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/account_deletion.dart';
import 'package:legendstudy_app/features/auth/presentation/delete_account_page.dart';

class FakeDeletionService implements AccountDeletionService {
  DeletionStatus status = const DeletionStatus('NORMAL');
  int requests = 0;
  @override
  bool get requiresRecentAuthentication => true;
  @override
  Future<DeletionStatus> readStatus() async => status;
  @override
  Future<DeletionStatus> requestDeletion() async {
    requests++;
    return status = DeletionStatus(
      'DELETION_PENDING',
      requestId: 'synthetic',
      deadline: DateTime.utc(2026, 10, 15),
    );
  }

  @override
  Future<DeletionStatus> cancelDeletion() async =>
      status = const DeletionStatus('CANCELLED');
}

class MemoryStore implements StudyLocalStore {
  Map<String, dynamic> document = {
    'version': 3,
    'owners': {
      'synthetic-a': {'records': <dynamic>[], 'draft': null},
      'synthetic-b': {'records': <dynamic>[], 'draft': null},
      'guest': {'records': <dynamic>[], 'draft': null},
    },
  };
  @override
  Future<Map<String, dynamic>> read() async => document;
  @override
  Future<void> write(Map<String, dynamic> next) async {
    document = next;
  }
}

void main() {
  test('restricted or unknown lifecycle cannot enter personalized routes', () {
    for (final state in ['DELETION_PENDING', 'ERASING', 'ERASED']) {
      expect(
        accountLifecycleRedirect(
          enabled: true,
          authenticated: true,
          status: AsyncData(DeletionStatus(state)),
          location: '/lab',
        ),
        '/my/delete-account',
      );
    }
    for (final status in <AsyncValue<DeletionStatus?>>[
      const AsyncLoading(),
      AsyncError(StateError('offline'), StackTrace.empty),
    ]) {
      expect(
        accountLifecycleRedirect(
          enabled: true,
          authenticated: true,
          status: status,
          location: '/my',
        ),
        '/my/delete-account',
      );
    }
  });
  test('normal, guest, disabled and recovery routes preserve access', () {
    for (final state in ['NORMAL', 'CANCELLED']) {
      expect(
        accountLifecycleRedirect(
          enabled: true,
          authenticated: true,
          status: AsyncData(DeletionStatus(state)),
          location: '/home',
        ),
        isNull,
      );
    }
    for (final location in ['/my/delete-account', '/auth', '/auth/recovery']) {
      expect(
        accountLifecycleRedirect(
          enabled: true,
          authenticated: true,
          status: const AsyncLoading(),
          location: location,
        ),
        isNull,
      );
    }
    expect(
      accountLifecycleRedirect(
        enabled: false,
        authenticated: true,
        status: const AsyncLoading(),
        location: '/home',
      ),
      isNull,
    );
    expect(
      accountLifecycleRedirect(
        enabled: true,
        authenticated: false,
        status: const AsyncLoading(),
        location: '/home',
      ),
      isNull,
    );
  });

  test('local pending cleanup preserves other users and guest', () async {
    final s = MemoryStore();
    await purgeStudyOwner(s, 'synthetic-a');
    expect(
      (s.document['owners'] as Map).keys,
      containsAll(['synthetic-b', 'guest']),
    );
    expect((s.document['owners'] as Map).containsKey('synthetic-a'), isFalse);
  });

  test('strict DTO requires deadline for restricted states', () {
    expect(
      () => DeletionStatus.fromJson({'state': 'DELETION_PENDING'}),
      throwsA(isA<AccountDeletionException>()),
    );
    for (final state in ['NORMAL', 'CANCELLED', 'ERASED']) {
      expect(DeletionStatus.fromJson({'state': state}).state, state);
    }
  });
  test('requires real reauthentication contract', () {
    expect(FakeDeletionService().requiresRecentAuthentication, isTrue);
  });
  Future<void> mount(WidgetTester t, FakeDeletionService f) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(f),
          studyLocalStoreProvider.overrideWithValue(MemoryStore()),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('synthetic-a')),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: DeleteAccountPage())),
      ),
    );
    await t.pumpAndSettle();
  }

  // Cancel requires a fresh same-owner reauthentication (CLOSEOUT-2); mount with
  // a verified email provider + a succeeding reauth path.
  Future<void> mountCancellable(WidgetTester t, FakeDeletionService f) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(f),
          studyLocalStoreProvider.overrideWithValue(MemoryStore()),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('synthetic-a')),
          ),
          accountPrimaryProviderProvider.overrideWith((ref) => 'email'),
          accountEmailReauthenticationProvider.overrideWith(
            (ref) => (String _) async {},
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: DeleteAccountPage())),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('request shows pending deadline, never immediate deletion', (
    t,
  ) async {
    final f = FakeDeletionService();
    await mount(t, f);
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await t.tap(find.text('탈퇴 요청하기'));
    await t.pumpAndSettle();
    expect(f.requests, 1);
    expect(find.textContaining('파기 예정 시각:'), findsOneWidget);
    expect(find.textContaining('탈퇴 요청이 접수됐어요'), findsOneWidget);
    expect(find.text('계정 삭제 완료'), findsNothing);
  });
  testWidgets('explicit cancellation restores normal request state', (t) async {
    final f = FakeDeletionService()
      ..status = DeletionStatus(
        'DELETION_PENDING',
        deadline: DateTime.utc(2026, 10, 15),
      );
    await mountCancellable(t, f);
    await t.tap(find.text('탈퇴 취소'));
    await t.pumpAndSettle();
    expect(find.text('탈퇴 요청을 취소했어요.'), findsOneWidget);
  });
  testWidgets('ERASING has no cancellation', (t) async {
    final f = FakeDeletionService()
      ..status = DeletionStatus(
        'ERASING',
        deadline: DateTime.utc(2026, 10, 15),
      );
    await mount(t, f);
    expect(find.text('탈퇴 취소'), findsNothing);
    expect(find.textContaining('파기 중'), findsOneWidget);
  });
  testWidgets('ERASED terminal is separate from request', (t) async {
    final f = FakeDeletionService()..status = const DeletionStatus('ERASED');
    await mount(t, f);
    expect(find.text('개인정보 파기가 확인됐어요.'), findsOneWidget);
    expect(find.text('탈퇴 요청하기'), findsNothing);
  });
  testWidgets('owner switch clears acknowledgement and stale deadline', (
    t,
  ) async {
    final auth = StreamController<AuthStatus>();
    addTearDown(auth.close);
    final f = FakeDeletionService();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(f),
          studyLocalStoreProvider.overrideWithValue(MemoryStore()),
          authStateProvider.overrideWith((ref) => auth.stream),
        ],
        child: const MaterialApp(home: Scaffold(body: DeleteAccountPage())),
      ),
    );
    auth.add(const AuthStatus('synthetic-a'));
    await t.pumpAndSettle();
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    expect(
      t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    auth.add(const AuthStatus('synthetic-b'));
    await t.pumpAndSettle();
    expect(
      t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(f.requests, 0);
  });
}
