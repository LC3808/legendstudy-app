import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppleAuthStage {
  nativeCredential,
  identityToken,
  supabaseExchange,
  session,
}

/// Explicit Profile/debug opt-in. Never serialize an exception or its message,
/// details, status/body, credential, nonce, authorization code or user identity.
class AppleAuthDiagnostics {
  const AppleAuthDiagnostics({
    this.enabled = const bool.fromEnvironment('APPLE_AUTH_DIAGNOSTICS'),
    this.sink,
  });
  final bool enabled;
  final void Function(String)? sink;
  void report(AppleAuthStage stage, {Object? error, bool complete = false}) {
    if (kReleaseMode || !enabled) return;
    var kind = error == null ? (complete ? 'complete' : 'start') : 'unknown';
    var code = 'none';
    if (error is SignInWithAppleAuthorizationException) {
      kind = 'apple_authorization';
      code = error.code.name; // SDK enum, never arbitrary native text.
    } else if (error is AuthException) {
      kind = 'supabase_auth';
      const allowed = {
        'bad_jwt',
        'validation_failed',
        'provider_disabled',
        'oauth_provider_not_supported',
        'unexpected_failure',
        'session_not_found',
        'bad_oauth_response',
        'bad_oauth_callback',
        'identity_already_exists',
        'email_exists',
        'email_not_confirmed',
        'over_request_rate_limit',
        'request_timeout',
      };
      code = allowed.contains(error.code) ? error.code! : 'unknown';
    } else if (error is PlatformException) {
      kind = 'platform';
      code = 'unknown'; // Platform codes/details are uncontrolled strings.
    }
    final line =
        'APPLE_AUTH stage=${stage.name} provider=apple kind=$kind code=$code';
    if (sink != null) {
      sink!(line);
    } else {
      debugPrint(line);
    }
  }
}
