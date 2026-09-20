import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/config/app_config.dart';

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
/// `signInWithOAuth` opens a browser, so a widget test can never call it. The
/// returned bool is only "the provider page opened", not an authenticated
/// session: the session arrives later through `onAuthStateChange`.
abstract class OAuthService {
  Future<bool> startSignIn(OAuthProvider provider);
}

class SupabaseOAuthService implements OAuthService {
  const SupabaseOAuthService(this._client);
  final SupabaseClient _client;

  @override
  Future<bool> startSignIn(OAuthProvider provider) =>
      _client.auth.signInWithOAuth(provider, redirectTo: oauthCallbackUrl);
}

/// Null until Supabase is initialized, exactly like the recovery seam.
final oauthServiceProvider = Provider<OAuthService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseOAuthService(client);
});

/// Providers offered on the login screen, in display order.
const supportedOAuthProviders = <OAuthProvider>[
  OAuthProvider.google,
  OAuthProvider.apple,
  OAuthProvider.kakao,
];

// A deployment declaration, not automatic provider discovery.
final availableOAuthProvidersProvider = Provider<List<OAuthProvider>>((ref) {
  final config = ref.watch(appConfigProvider);
  return [
    if (config.googleOAuthEnabled) OAuthProvider.google,
    if (config.appleOAuthEnabled) OAuthProvider.apple,
    if (config.kakaoOAuthEnabled) OAuthProvider.kakao,
  ];
});
