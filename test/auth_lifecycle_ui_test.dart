import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/auth/auth_recovery.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/auth/presentation/new_password_page.dart';
import 'package:legendstudy_app/features/feedback/presentation/feedback_page.dart';

import 'auth_recovery_test.dart' show FakeRecoveryService;
import 'core_ux_test.dart' as preview;

Future<void> Function(String)? nativeCapture;

class PendingPassword extends FakeRecoveryService {
  final gate = Completer<void>();
  @override
  Future<void> updatePassword(String value) async {
    passwords.add(value);
    await gate.future;
  }
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('email help support return and keyboard 360x640 $scale', (
      tester,
    ) async {
      if (nativeCapture == null) {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
          appConfigProvider.overrideWithValue(const AppConfig()),
        ],
      );
      addTearDown(c.dispose);
      final router = c.read(routerProvider)..go('/auth');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(
            key: preview.frame,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              locale: const Locale('ko'),
              supportedLocales: const [Locale('ko')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: const bool.fromEnvironment('CORE_RENDER')
                  ? AppTheme.light.copyWith(
                      textTheme: AppTheme.light.textTheme.apply(
                        fontFamily: 'CorePreview',
                      ),
                    )
                  : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('개인정보처리방침'), findsNothing);
      expect(find.text('이용약관'), findsNothing);
      await tester.ensureVisible(find.text('가입한 이메일을 잊으셨나요?'));
      await tester.tap(find.text('가입한 이메일을 잊으셨나요?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Google·Apple·Kakao'), findsOneWidget);
      expect(find.textContaining('비밀번호나 인증 코드는 보내지 마세요'), findsOneWidget);
      await preview.capture(tester, 'auth-help-$scale');
      await nativeCapture?.call('auth-help-$scale');
      await tester.tap(find.text('문의하기'));
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(
        find.byType(TextFormField).first,
        'very.long.student.email@example.test',
      );
      if (nativeCapture == null) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
      }
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, '로그인'));
      await tester.pumpAndSettle();
      await preview.capture(tester, 'auth-help-keyboard-$scale');
      await nativeCapture?.call('auth-help-keyboard-$scale');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'new password duplicate guard and owner change clear fields without stale success',
    (tester) async {
      final events = StreamController<AuthStatus>.broadcast();
      final service = PendingPassword();
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => events.stream),
          authRecoveryServiceProvider.overrideWithValue(service),
        ],
      );
      final router = GoRouter(
        initialLocation: '/page',
        routes: [
          GoRoute(
            path: '/page',
            builder: (_, _) => const Scaffold(body: NewPasswordPage()),
          ),
          GoRoute(path: '/my', builder: (_, _) => const Text('MY')),
        ],
      );
      addTearDown(() async {
        c.dispose();
        router.dispose();
        await events.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      events.add(const AuthStatus('a'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'fixture-password');
      await tester.enterText(find.byType(TextField).at(1), 'fixture-password');
      await tester.tap(find.text('비밀번호 변경'));
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pump();
      expect(service.passwords, hasLength(1));
      events.add(const AuthStatus('b'));
      await tester.pumpAndSettle();
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.controller!.text, isEmpty);
      }
      service.gate.complete();
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/page');
      expect(find.text('비밀번호를 변경했어요.'), findsNothing);
      events.add(const AuthStatus(null));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('재설정 메일 다시 요청'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
