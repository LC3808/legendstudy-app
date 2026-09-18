import 'dart:async';

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
  const AuthStatus(this.userId, {this.event, this.failure});
  final String? userId;

  /// The change that produced this status. Recovery must not be mistaken for an
  /// ordinary signed-in session, so the event is carried rather than discarded.
  final AuthChangeEvent? event;

  /// A transient auth failure that arrived instead of an event, typically a
  /// deep link that could not be exchanged for a session. It is classified by
  /// the auth feature and never rendered raw; identity above is unaffected.
  final Object? failure;
  bool get isAuthenticated => userId != null;
  bool get isPasswordRecovery => event == AuthChangeEvent.passwordRecovery;
}

/// Carries auth-stream errors as values instead of letting them fail the
/// provider.
///
/// gotrue reports a recovery link it cannot exchange by adding an error to
/// `onAuthStateChange`, not by emitting an event. Left as a provider error that
/// would do two wrong things: Riverpod would start its automatic retry (the
/// first backoff is 200ms) on a stream that cannot be rebuilt, and every widget
/// reading this provider would lose the user id — the app would look signed out
/// because a link expired. The identity last seen is therefore preserved and
/// the failure travels beside it.
Stream<AuthStatus> withAuthFailures(Stream<AuthStatus> source) {
  String? identity;
  return source.transform(
    StreamTransformer<AuthStatus, AuthStatus>.fromHandlers(
      handleData: (status, sink) {
        identity = status.userId;
        sink.add(status);
      },
      handleError: (error, _, sink) =>
          sink.add(AuthStatus(identity, failure: error)),
    ),
  );
}

final authStateProvider = StreamProvider<AuthStatus>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return Stream.value(const AuthStatus(null));
    // onAuthStateChange supplies the SDK initial session event and later
    // changes; failures on it become values (see withAuthFailures).
    return withAuthFailures(
      client.auth.onAuthStateChange.map(
        (event) => AuthStatus(event.session?.user.id, event: event.event),
      ),
    );
  },
  // Rebuilding this provider re-subscribes to the same SDK stream, so a retry
  // cycle would repeat rather than recover. Failures are handled above.
  retry: (_, _) => null,
);
