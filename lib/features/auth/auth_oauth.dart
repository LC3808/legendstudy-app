import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/config/app_config.dart';
import 'native_auth.dart';
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
/// Browser paths return launch success; native paths exchange an ID token first.
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
  });
  final SupabaseClient _client;
  final NativeIdentityProvider native;
  final TargetPlatform platform;
  final AppleAuthDiagnostics appleDiagnostics;
  bool _busy = false;

  @override
  Future<bool> startSignIn(OAuthProvider provider) async {
    if (_busy) return false;
    _busy = true;
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
      // Kakao keeps the approved browser/PKCE path; Android Apple also retains
      // its browser path. No native Kakao token-to-identity assumptions.
      return await _client.auth.signInWithOAuth(
        provider,
        redirectTo: oauthCallbackUrl,
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
    if (config.appleOAuthEnabled) OAuthProvider.apple,
  ];
});
