import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';

import 'auth_lifecycle_sdk_test.dart' show MemoryPkce;
import 'native_auth_test.dart' show FakeIdentity;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test(
      'Kakao SDK browser URL uses email-only override on $platform',
      () async {
        final urls = <Uri>[];
        final safariViews = <bool>[];
        const channel = MethodChannel('plugins.flutter.io/url_launcher');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'launch') {
                urls.add(Uri.parse((call.arguments as Map)['url'] as String));
                safariViews.add((call.arguments as Map)['useSafariVC'] as bool);
              }
              return true;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        final client = SupabaseClient(
          'https://example.test',
          'test-only',
          authOptions: AuthClientOptions(
            pkceAsyncStorage: MemoryPkce(),
            autoRefreshToken: false,
          ),
        );
        addTearDown(client.dispose);
        final native = FakeIdentity();
        final service = SupabaseOAuthService(
          client,
          native: native,
          platform: platform,
        );
        expect(await service.startSignIn(OAuthProvider.kakao), isTrue);
        expect(safariViews.single, platform != TargetPlatform.iOS);
        final url = urls.single;
        expect(url.path, '/auth/v1/authorize');
        expect(url.queryParameters['provider'], 'kakao');
        expect(url.queryParameters['redirect_to'], oauthCallbackUrl);
        expect(url.queryParameters['code_challenge_method'], 's256');
        expect(url.queryParameters['code_challenge'], isNotEmpty);
        expect(url.queryParameters.containsKey('scopes'), isFalse);
        expect(url.queryParametersAll['scope'], ['account_email']);
        final scopes = url.queryParameters['scope']!.split(RegExp(r'[ ,]+'));
        expect(scopes, ['account_email']);
        expect(scopes, isNot(contains('profile_nickname')));
        expect(scopes, isNot(contains('profile_image')));
        expect(native.calls, isEmpty);
        // Browser Apple must not receive Kakao's override.
        if (platform == TargetPlatform.android) {
          expect(await service.startSignIn(OAuthProvider.apple), isTrue);
          expect(urls.last.queryParameters['provider'], 'apple');
          expect(safariViews.last, isTrue);
          expect(urls.last.queryParameters.containsKey('scope'), isFalse);
          expect(urls.last.queryParameters.containsKey('scopes'), isFalse);
        }
      },
    );
  }
}
