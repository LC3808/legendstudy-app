import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/config/app_config.dart';

/// Session material stays inside the SDK; UI receives only completion state.
abstract class EmailAuthService {
  Future<void> login(String email, String password);
  Future<bool> signUp(String email, String password);
}

class SupabaseEmailAuthService implements EmailAuthService {
  const SupabaseEmailAuthService(this.client, {this.signupRedirectTo});
  final String? signupRedirectTo;
  final SupabaseClient client;
  @override
  Future<void> login(String email, String password) async {
    final result = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (result.session == null) {
      throw const AuthException('Session missing', code: 'session_not_found');
    }
  }

  @override
  Future<bool> signUp(String email, String password) async {
    final result = await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: signupRedirectTo,
    );
    return result.session != null;
  }
}

final emailAuthServiceProvider = Provider<EmailAuthService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? null
      : SupabaseEmailAuthService(
          client,
          signupRedirectTo: ref.watch(appConfigProvider).signupRedirectTo,
        );
});
final localLogoutProvider = Provider<Future<void> Function()?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? null
      : () => client.auth.signOut(scope: SignOutScope.local);
});

// Email belongs to the currently observed SDK identity, never a previous owner.
final currentAccountEmailProvider = Provider<String?>((ref) {
  final owner = ref.watch(authStateProvider).value?.userId;
  final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
  return owner != null && user?.id == owner ? user?.email : null;
});

/// Explicit user action only; never resend on resume or an auth-state event.
final resendSignupEmailProvider = Provider<Future<void> Function(String)?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  final redirect = ref.watch(appConfigProvider).signupRedirectTo;
  return client == null
      ? null
      : (email) async {
          await client.auth.resend(
            type: OtpType.signup,
            email: email,
            emailRedirectTo: redirect,
          );
        };
});

/// Process-local abuse guard shared across Auth page recreation. Contains no PII.
/// Server limits remain authoritative; this is not a promised quota reset time.
class EmailRequestCooldown {
  EmailRequestCooldown({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  DateTime? _until;
  int get remainingSeconds {
    final milliseconds = _until?.difference(_now()).inMilliseconds ?? 0;
    return milliseconds > 0 ? (milliseconds / 1000).ceil() : 0;
  }

  void start() => _until = _now().add(const Duration(seconds: 60));
}

final emailRequestCooldownProvider = Provider((ref) => EmailRequestCooldown());
