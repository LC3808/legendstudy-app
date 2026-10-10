import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/auth/presentation/provider_button.dart';

import 'core_ux_test.dart' as preview;

/// Login screen render guard + capture (Owner 2026-10-09): centred hero, single-
/// line account links, guest entry, and Apple hidden on Android. Run with
/// `--dart-define=CORE_RENDER=true` to emit PNGs to /private/tmp/legendstudy-core-ui.
const _config = AppConfig(
  googleOAuthEnabled: true,
  googleServerClientId: 'test-server-client-id',
  kakaoOAuthEnabled: true,
  appleOAuthEnabled: true,
);

void main() {
  // flutter_test's default platform is Android, so the Android case needs no
  // override.
  testWidgets(
    'login UI on Android: hero/links/guest, Apple hidden, no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1280); // 360x640 @2x
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(_config),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
          ],
          child: preview.app(const AuthPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Hero (new copy), single-line account links, guest entry.
      expect(find.text('나의 가능성을\n더 선명하게 만드세요.'), findsOneWidget);
      expect(find.text('회원가입'), findsOneWidget);
      expect(find.text('비밀번호 찾기'), findsOneWidget);
      expect(find.text('이메일 찾기'), findsOneWidget);
      expect(find.text('비회원으로 이용하기'), findsOneWidget);

      // Social: Google + Kakao on Android; Apple hidden (capability preserved).
      final buttons = tester
          .widgetList<ProviderButton>(find.byType(ProviderButton))
          .map((b) => b.provider)
          .toList();
      expect(
        buttons,
        containsAll(<OAuthProvider>[OAuthProvider.google, OAuthProvider.kakao]),
      );
      expect(buttons, isNot(contains(OAuthProvider.apple)));

      expect(tester.takeException(), isNull);
      await preview.capture(tester, 'login-android');
    },
  );

  testWidgets('login UI on iOS shows Apple', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              _config.copyWithIosClientId('test-ios-client-id'),
            ),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
          ],
          child: preview.app(const AuthPage()),
        ),
      );
      await tester.pumpAndSettle();
      final buttons = tester
          .widgetList<ProviderButton>(find.byType(ProviderButton))
          .map((b) => b.provider)
          .toList();
      expect(buttons, contains(OAuthProvider.apple));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

extension on AppConfig {
  // iOS Google needs an iOS client id to be offered; build a copy for the iOS case.
  AppConfig copyWithIosClientId(String id) => AppConfig(
    googleOAuthEnabled: googleOAuthEnabled,
    googleServerClientId: googleServerClientId,
    googleIosClientId: id,
    kakaoOAuthEnabled: kakaoOAuthEnabled,
    appleOAuthEnabled: appleOAuthEnabled,
  );
}
