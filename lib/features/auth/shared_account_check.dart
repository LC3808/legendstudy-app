import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only, explicit Owner comparison. Never logs or returns either identity.
Future<bool> verifySharedAccount(SupabaseClient client, String expected) async {
  final before = client.auth.currentUser?.id;
  if (before == null || expected.trim().isEmpty) return false;
  final server = await client.auth.getUser();
  return client.auth.currentUser?.id == before &&
      server.user?.id == before &&
      before == expected.trim();
}
