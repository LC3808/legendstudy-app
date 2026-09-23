import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:legendstudy_app/features/auth/auth_errors.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';

import 'auth_oauth_test.dart' show FakeOAuthService;
import 'day9_c3_personal_lists_test.dart' as lists;

import 'package:legendstudy_app/features/personal/personal_list_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/presentation/personal_material_list.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';

import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/profile/presentation/settings_page.dart';

class EmailFake implements EmailAuthService {
  int logins = 0, signups = 0;
  Object? failure;
  Completer<void>? pending;
  bool authenticated = false;
  @override
  Future<void> login(String email, String password) async {
    logins++;
    await pending?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    signups++;
    await pending?.future;
    if (failure != null) throw failure!;
    return authenticated;
  }
}

void main() {
  for (final kind in PersonalListKind.values) {
    testWidgets('logout then account B does not retain account A $kind', (
      tester,
    ) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final entries = [lists.entry('a', 20)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => auth.stream),
            bookmarkRepositoryProvider.overrideWithValue(
              lists.ListBookmarkRepository(entries),
            ),
            recentViewRepositoryProvider.overrideWithValue(
              lists.ListRecentRepository(entries),
            ),
            contentRepositoryProvider.overrideWithValue(
              lists.BatchContentRepository([
                lists.content('a', 'A의 개인 자료'),
                lists.content('b', 'B의 개인 자료'),
              ]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: PersonalMaterialListPage(kind: kind)),
          ),
        ),
      );
      auth.add(const AuthStatus('a'));
      await tester.pumpAndSettle();
      expect(find.text('A의 개인 자료'), findsOneWidget);
      auth.add(const AuthStatus(null));
      await tester.pumpAndSettle();
      expect(find.text('A의 개인 자료'), findsNothing);
      entries
        ..clear()
        ..add(lists.entry('b', 20));
      auth.add(const AuthStatus('b'));
      await tester.pumpAndSettle();
      expect(find.text('B의 개인 자료'), findsOneWidget);
      expect(find.text('A의 개인 자료'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  Future<void> mount(WidgetTester tester, EmailFake? service) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emailAuthServiceProvider.overrideWithValue(service),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AuthPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, {bool signup = false}) async {
    final button = find.widgetWithText(FilledButton, signup ? '회원가입' : '로그인');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> signupMode(WidgetTester tester) async {
    final toggle = find.text('처음이신가요? 회원가입');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String password = 'test-only-password',
  }) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  testWidgets('login validates empty/email shape without service calls', (
    tester,
  ) async {
    final service = EmailFake();
    await mount(tester, service);
    await submit(tester);
    expect(service.logins, 0);
    expect(find.text('이메일 형식을 확인해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
  });
  testWidgets(
    'login permits existing short password and blocks duplicate callback',
    (tester) async {
      final service = EmailFake()..pending = Completer<void>();
      await mount(tester, service);
      await fill(tester, password: 'short');
      final callback = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      callback();
      callback();
      await tester.pump();
      expect(service.logins, 1);
      expect(find.text('처리 중…'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );
      service.pending!.complete();
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'signup needs matching policy-length confirmation and neutral response',
    (tester) async {
      final service = EmailFake();
      await mount(tester, service);
      await signupMode(tester);
      expect(find.byType(TextFormField), findsNWidgets(3));
      await fill(tester, password: 'short');
      await submit(tester, signup: true);
      expect(service.signups, 0);
      await fill(tester);
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await submit(tester, signup: true);
      expect(service.signups, 0);
      expect(find.text('두 비밀번호가 서로 달라요.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'test-only-password',
      );
      await submit(tester, signup: true);
      await tester.pumpAndSettle();
      expect(service.signups, 1);
      expect(find.textContaining('가입을 요청했어요.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
  );
  testWidgets('password visibility has accessible control and autofill', (
    tester,
  ) async {
    await mount(tester, EmailFake());
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('비밀번호 보기'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('비밀번호 숨기기'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).autofillHints,
      contains(AutofillHints.email),
    );
  });
  for (final failure in [
    const AuthException('private-response-hidden', code: 'invalid_credentials'),
    const SocketException('private-response-hidden'),
    StateError('private-response-hidden'),
  ]) {
    testWidgets('mapped auth error ${failure.runtimeType}', (tester) async {
      final service = EmailFake()..failure = failure;
      await mount(tester, service);
      await fill(tester);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.text(authErrorMessage(failure)), findsOneWidget);
      expect(find.textContaining('private-response-hidden'), findsNothing);
    });
  }
  testWidgets('unconfigured email and disabled social are fail closed', (
    tester,
  ) async {
    await mount(tester, null);
    await fill(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('현재 로그인할 수 없어요'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsNothing);
    expect(find.text('Apple로 계속하기'), findsNothing);
    expect(find.text('Kakao로 계속하기'), findsNothing);
  });
  testWidgets('logout failure can retry and success moves to guest', (
    tester,
  ) async {
    final events = StreamController<AuthStatus>();
    addTearDown(events.close);
    int calls = 0;
    bool fail = true;
    final pending = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) async* {
            yield const AuthStatus('account-a');
            yield* events.stream;
          }),
          localLogoutProvider.overrideWithValue(() async {
            calls++;
            if (fail) throw StateError('private');
            await pending.future;
            events.add(const AuthStatus(null));
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsPage())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.widgetWithText(TextButton, '로그아웃').last);
    await tester.pumpAndSettle();
    expect(find.text('로그아웃하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    fail = false;
    final callback = tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '로그아웃'))
        .onPressed!;
    callback();
    callback();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.tap(find.widgetWithText(TextButton, '로그아웃').last);
    await tester.pump();
    expect(calls, 2);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('로그인하지 않은 상태예요.'), findsOneWidget);
    expect(find.text('회원탈퇴'), findsNothing);
  });
  testWidgets('a provider disabled after render cannot start', (tester) async {
    var enabled = true;
    final service = FakeOAuthService();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus(null)),
        ),
        oauthServiceProvider.overrideWithValue(service),
        availableOAuthProvidersProvider.overrideWith(
          (ref) => enabled ? [OAuthProvider.google] : [],
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AuthPage())),
      ),
    );
    await tester.pumpAndSettle();
    final callback = tester
        .widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Google로 계속하기'),
        )
        .onPressed!;
    enabled = false;
    container.invalidate(availableOAuthProvidersProvider);
    callback();
    await tester.pumpAndSettle();
    expect(service.started, isEmpty);
    expect(find.text('현재 이 로그인 방식을 사용할 수 없습니다.'), findsOneWidget);
  });
  test('safe callback/session/provider mapping', () {
    for (final code in [
      'bad_oauth_callback',
      'bad_oauth_state',
      'provider_disabled',
      'session_not_found',
      'user_already_exists',
      'weak_password',
    ]) {
      expect(
        authErrorMessage(AuthException('private', code: code)),
        isNot(contains('private')),
      );
    }
    expect(
      authErrorMessage(const AuthException('private', code: 'access_denied')),
      '로그인이 취소되었어요.',
    );
  });
}
