import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';

/// Session material stays inside the SDK; UI receives only completion state.
abstract class EmailAuthService {
  Future<void> login(String email, String password);
  Future<bool> signUp(String email, String password);
}

class SupabaseEmailAuthService implements EmailAuthService {
  const SupabaseEmailAuthService(this.client);
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
    final result = await client.auth.signUp(email: email, password: password);
    return result.session != null;
  }
}

final emailAuthServiceProvider = Provider<EmailAuthService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseEmailAuthService(client);
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
