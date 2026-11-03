import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/config/app_config.dart';
import 'native_auth.dart';
import 'ios_web_auth_session.dart';
import 'apple_auth_diagnostics.dart';

/// Where a social provider returns after consent.
///
/// The same custom scheme as password recovery, on a different host, so the two
/// callbacks stay separable on Android: recovery uses `auth-recovery`, social
/// login uses `login-callback`. It is the value this repository has always
/// passed to `signInWithOAuth`; it is declared here so the manifests, the call
/// site and the regression tests cannot drift apart.
const oauthCallbackUrl = 'com.legendstudy.app://login-callback';

/// Starting an OAuth flow, behind a seam.
///
/// Android browser paths return launch success; iOS Kakao and native providers
/// wait for the SDK session exchange.
/// UI navigation always follows Supabase auth events, never this bool alone.
/// Widget tests replace the service and do not invoke native or browser auth.
abstract class OAuthService {
  Future<bool> startSignIn(OAuthProvider provider);
}

class SupabaseOAuthService implements OAuthService {
  SupabaseOAuthService(
    this._client, {
    required this.native,
    required this.platform,
    this.appleDiagnostics = const AppleAuthDiagnostics(),
    this.webAuthSession = const IosWebAuthSession(),
  });
  final SupabaseClient _client;
  final NativeIdentityProvider native;
  final TargetPlatform platform;
  final AppleAuthDiagnostics appleDiagnostics;
  final IosWebAuthSession webAuthSession;
  bool _busy = false;
  // PKCE storage is shared even if a provider rebuild creates another service.
  static bool _iosKakaoBusy = false;

  @override
  Future<bool> startSignIn(OAuthProvider provider) async {
    final iosKakao =
        provider == OAuthProvider.kakao && platform == TargetPlatform.iOS;
    if (_busy || _iosKakaoBusy) return false;
    _busy = true;
    if (iosKakao) _iosKakaoBusy = true;
    final nativeApple =
        provider == OAuthProvider.apple && platform == TargetPlatform.iOS;
    var appleStage = AppleAuthStage.nativeCredential;
    final startingOwner = _client.auth.currentUser?.id;
    try {
      if (provider == OAuthProvider.google ||
          (provider == OAuthProvider.apple && platform == TargetPlatform.iOS)) {
        final identity = provider == OAuthProvider.google
            ? await native.google()
            : await native.apple();
        if (_client.auth.currentUser?.id != startingOwner) {
          throw const NativeAuthCancelled();
        }
        appleStage = AppleAuthStage.supabaseExchange;
        if (nativeApple) appleDiagnostics.report(appleStage);
        final response = await _client.auth.signInWithIdToken(
          provider: provider,
          idToken: identity.token,
          nonce: identity.nonce,
        );
        appleStage = AppleAuthStage.session;
        if (response.session == null) {
          throw const AuthException(
            'Missing session',
            code: 'session_not_found',
          );
        }
        if (nativeApple) appleDiagnostics.report(appleStage, complete: true);
        return true;
      }
      if (iosKakao) {
        final response = await _client.auth.getOAuthSignInUrl(
          provider: provider,
          redirectTo: oauthCallbackUrl,
          queryParams: const {'scope': 'account_email'},
        );
        if (_client.auth.currentUser?.id != startingOwner) {
          throw const NativeAuthCancelled();
        }
        final callback = await webAuthSession.authenticate(response.url);
        if (_client.auth.currentUser?.id != startingOwner) {
          throw const NativeAuthCancelled();
        }
        // ASWebAuthenticationSession consumes this callback; do not forward it
        // into app_links or call getSessionFromUrl a second time.
        final expected = Uri.parse(oauthCallbackUrl);
        final codes = callback.queryParametersAll['code'];
        if (callback.scheme != expected.scheme ||
            callback.host != expected.host ||
            callback.path != expected.path ||
            callback.hasPort ||
            callback.userInfo.isNotEmpty ||
            callback.fragment.isNotEmpty ||
            callback.queryParameters.containsKey('error') ||
            callback.queryParameters.containsKey('error_code') ||
            codes == null ||
            codes.length != 1 ||
            codes.single.isEmpty) {
          throw const AuthException(
            'Invalid authentication callback',
            code: 'unexpected_failure',
          );
        }
        await _client.auth.exchangeCodeForSession(codes.single);
        return true;
      }
      // Android browser OAuth remains SDK-managed.
      return await _client.auth.signInWithOAuth(
        provider,
        redirectTo: oauthCallbackUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
        // `scopes` appends to the Auth server's Kakao defaults (including
        // profile scopes). Singular OAuth `scope` replaces the final parameter
        // via the SDK's official queryParams passthrough. Keep email only.
        queryParams: provider == OAuthProvider.kakao
            ? const {'scope': 'account_email'}
            : null,
      );
    } catch (error) {
      // Native SDK errors are diagnosed before mapping in DeviceIdentityProvider.
      if (nativeApple && appleStage != AppleAuthStage.nativeCredential) {
        appleDiagnostics.report(appleStage, error: error);
      }
      rethrow;
    } finally {
      _busy = false;
      if (iosKakao) _iosKakaoBusy = false;
    }
  }
}

/// Null until Supabase is initialized, exactly like the recovery seam.
final oauthServiceProvider = Provider<OAuthService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? null
      : SupabaseOAuthService(
          client,
          native: DeviceIdentityProvider(ref.watch(appConfigProvider)),
          platform: defaultTargetPlatform,
        );
});

/// Providers offered on the login screen, in display order.
const supportedOAuthProviders = <OAuthProvider>[
  OAuthProvider.google,
  OAuthProvider.kakao,
  OAuthProvider.apple,
];

// A deployment declaration, not automatic provider discovery.
final availableOAuthProvidersProvider = Provider<List<OAuthProvider>>((ref) {
  final config = ref.watch(appConfigProvider);
  return [
    if (config.googleOAuthEnabled &&
        config.googleServerClientId.isNotEmpty &&
        (defaultTargetPlatform != TargetPlatform.iOS ||
            config.googleIosClientId.isNotEmpty))
      OAuthProvider.google,
    if (config.kakaoOAuthEnabled) OAuthProvider.kakao,
    // Apple sign-in is shown on iOS only (hidden on Android/web); the auth
    // capability itself is preserved.
    if (config.appleOAuthEnabled && defaultTargetPlatform == TargetPlatform.iOS)
      OAuthProvider.apple,
  ];
});
