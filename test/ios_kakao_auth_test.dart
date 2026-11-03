import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/ios_web_auth_session.dart';
import 'package:legendstudy_app/features/auth/native_auth.dart';

import 'auth_lifecycle_sdk_test.dart' show MemoryPkce, fixtureSession;
import 'native_auth_test.dart' show FakeIdentity;

class TestSession extends IosWebAuthSession {
  TestSession(this.run);
  final Future<Uri> Function(String) run;
  @override
  Future<Uri> authenticate(String url) => run(url);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late List<http.Request> requests;
  late List<AuthChangeEvent> events;
  bool failExchange = false;

  setUp(() {
    requests = [];
    events = [];
    failExchange = false;
    client = SupabaseClient(
      'https://example.test',
      'test-only',
      authOptions: AuthClientOptions(
        pkceAsyncStorage: MemoryPkce(),
        autoRefreshToken: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (failExchange) {
          return http.Response('{"error":"invalid_grant"}', 400);
        }
        return http.Response(jsonEncode(fixtureSession()), 200);
      }),
    );
    final sub = client.auth.onAuthStateChange.listen(
      (s) => events.add(s.event),
    );
    addTearDown(() async {
      await sub.cancel();
      await client.dispose();
    });
  });

  SupabaseOAuthService service(IosWebAuthSession session) =>
      SupabaseOAuthService(
        client,
        native: FakeIdentity(),
        platform: TargetPlatform.iOS,
        webAuthSession: session,
      );

  test('system session gets SDK PKCE URL; exactly one exchange creates signedIn session', () async {
    final auth = service(
      TestSession((url) async {
        final uri = Uri.parse(url);
        expect(uri.host, 'example.test');
        expect(uri.path, '/auth/v1/authorize');
        expect(uri.queryParameters['provider'], 'kakao');
        expect(uri.queryParameters['redirect_to'], oauthCallbackUrl);
        expect(uri.queryParameters['scope'], 'account_email');
        expect(uri.queryParameters.containsKey('scopes'), isFalse);
        expect(uri.queryParameters['code_challenge_method'], 's256');
        expect(uri.queryParameters['code_challenge'], isNotEmpty);
        return Uri.parse('$oauthCallbackUrl?code=fixture-code');
      }),
    );
    expect(await auth.startSignIn(OAuthProvider.kakao), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters['grant_type'], 'pkce');
    final body = jsonDecode(requests.single.body) as Map;
    expect(body['auth_code'], 'fixture-code');
    expect(body['code_verifier'], isNotEmpty);
    expect(client.auth.currentSession, isNotNull);
    expect(events.where((e) => e == AuthChangeEvent.signedIn), hasLength(1));
  });

  test(
    'pending flow blocks same and rebuilt services before overwriting PKCE',
    () async {
      final pending = Completer<Uri>();
      var launches = 0;
      final session = TestSession((_) {
        launches++;
        return pending.future;
      });
      final auth = service(session);
      final first = auth.startSignIn(OAuthProvider.kakao);
      await Future<void>.delayed(Duration.zero);
      expect(await auth.startSignIn(OAuthProvider.kakao), isFalse);
      expect(await service(session).startSignIn(OAuthProvider.kakao), isFalse);
      expect(launches, 1);
      pending.complete(Uri.parse('$oauthCallbackUrl?code=fixture-code'));
      expect(await first, isTrue);
      expect(requests, hasLength(1));
    },
  );

  for (final callback in [
    'other://login-callback?code=x',
    'com.legendstudy.app://auth-recovery?code=x',
    '$oauthCallbackUrl?error=access_denied',
    '$oauthCallbackUrl?code=',
    '$oauthCallbackUrl?code=a&code=b',
    '$oauthCallbackUrl/path?code=a',
    '$oauthCallbackUrl#access_token=untrusted',
  ]) {
    test('reject malformed or unrelated callback $callback', () async {
      await expectLater(
        service(TestSession((_) async => Uri.parse(callback)))
            .startSignIn(OAuthProvider.kakao),
        throwsA(isA<AuthException>()),
      );
      expect(requests, isEmpty);
      expect(client.auth.currentSession, isNull);
    });
  }

  test('cancel and presentation failure release guard, no exchange or external fallback', () async {
    var attempts = 0;
    final auth = service(
      TestSession((_) async {
        attempts++;
        if (attempts == 1) throw const NativeAuthCancelled();
        throw PlatformException(code: 'AUTH_UNAVAILABLE');
      }),
    );
    await expectLater(
      auth.startSignIn(OAuthProvider.kakao),
      throwsA(isA<NativeAuthCancelled>()),
    );
    await expectLater(
      auth.startSignIn(OAuthProvider.kakao),
      throwsA(isA<PlatformException>()),
    );
    expect(attempts, 2);
    expect(requests, isEmpty);
  });

  test(
    'exchange failure does not claim success and permits a fresh login',
    () async {
      failExchange = true;
      final auth = service(
        TestSession((_) async => Uri.parse('$oauthCallbackUrl?code=fixture')),
      );
      await expectLater(
        auth.startSignIn(OAuthProvider.kakao),
        throwsA(isA<AuthException>()),
      );
      expect(client.auth.currentSession, isNull);
      failExchange = false;
      expect(await auth.startSignIn(OAuthProvider.kakao), isTrue);
      expect(requests, hasLength(2));
    },
  );

  test(
    'account changes while sheet is open suppress stale code exchange',
    () async {
      final pending = Completer<Uri>();
      final flow = service(TestSession((_) => pending.future))
          .startSignIn(OAuthProvider.kakao);
      await Future<void>.delayed(Duration.zero);
      await client.auth.recoverSession(jsonEncode(fixtureSession()));
      pending.complete(Uri.parse('$oauthCallbackUrl?code=stale'));
      await expectLater(flow, throwsA(isA<NativeAuthCancelled>()));
      expect(requests, isEmpty);
    },
  );

  test(
    'native channel maps system cancellation without leaking provider details',
    () async {
      const channel = MethodChannel('com.legendstudy.app/web-auth');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            throw PlatformException(
              code: 'AUTH_CANCELLED',
              message: 'not displayed',
            );
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await expectLater(
        const IosWebAuthSession().authenticate('https://example.test'),
        throwsA(isA<NativeAuthCancelled>()),
      );
    },
  );
}
