import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/supabase/supabase_providers.dart';

/// Password recovery seam.
///
/// The UI never touches the SDK directly, so tests drive the screens with an
/// in-memory double and no network call is possible from a widget test.
abstract class AuthRecoveryService {
  /// Starts recovery for [email]. Supabase answers the same way whether or not
  /// the address has an account, which is what keeps the UI from disclosing it.
  Future<void> sendRecoveryEmail(String email);

  /// Sets a new password for the session the recovery link established.
  Future<void> updatePassword(String password);
}

class SupabaseAuthRecoveryService implements AuthRecoveryService {
  const SupabaseAuthRecoveryService(this._client, {this.redirectTo});
  final SupabaseClient _client;

  /// Configured, never invented. Null lets Supabase use the project Site URL;
  /// the production value is still pending (see wiki/auth-recovery.md).
  final String? redirectTo;

  @override
  Future<void> sendRecoveryEmail(String email) =>
      _client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo);

  @override
  Future<void> updatePassword(String password) =>
      _client.auth.updateUser(UserAttributes(password: password));
}

final authRecoveryServiceProvider = Provider<AuthRecoveryService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseAuthRecoveryService(
    client,
    redirectTo: ref.watch(appConfigProvider).recoveryRedirectTo,
  );
});

/// Basic shape check only. The server remains the authority on the address.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]{2,}$');

bool isPlausibleEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Minimum the client enforces. Supabase owns the real policy, and its
/// rejection is surfaced through [authErrorMessage] rather than duplicated here.
const minimumPasswordLength = 8;
