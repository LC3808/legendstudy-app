import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class BackendUnavailable implements Exception {
  const BackendUnavailable(this.message);
  final String message;
}

class SignedOutException implements Exception {
  const SignedOutException();
}

// Only the composition root obtains the initialized SDK singleton.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);
final backendIssueProvider = Provider<String?>((ref) {
  final errors = ref.watch(appConfigProvider).validationErrors;
  return errors.isEmpty ? null : errors.join('\n');
});

/// UI-facing state contains identity only, never an access/refresh token.
class AuthStatus {
  const AuthStatus(this.userId, {this.event});
  final String? userId;

  /// The change that produced this status. Recovery must not be mistaken for an
  /// ordinary signed-in session, so the event is carried rather than discarded.
  final AuthChangeEvent? event;
  bool get isAuthenticated => userId != null;
  bool get isPasswordRecovery => event == AuthChangeEvent.passwordRecovery;
}

final authStateProvider = StreamProvider<AuthStatus>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(const AuthStatus(null));
  // onAuthStateChange supplies the SDK initial session event and later changes.
  return client.auth.onAuthStateChange.map(
    (event) => AuthStatus(event.session?.user.id, event: event.event),
  );
});
