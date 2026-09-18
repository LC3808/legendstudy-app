import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/supabase/supabase_providers.dart';

/// The server endpoint that owns the deletion. Nothing about deletion happens
/// from the client: the app cannot remove an auth user, and widening RLS so it
/// could would hand every signed-in session a delete grant.
const accountDeletionFunction = 'delete-account';

/// A failure the user can be told about, by code rather than by server text.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.code);
  final String code;
}

const accountDeletionGenericFailure =
    '탈퇴를 처리하지 못했어요. 잠시 후 다시 시도하거나 문의해 주세요.';

const _byCode = <String, String>{
  'unauthorized': '로그인 정보가 만료되었어요. 다시 로그인한 뒤 시도해 주세요.',
  'admin_blocked': '관리자 계정은 앱에서 탈퇴할 수 없어요. 운영 담당자에게 문의해 주세요.',
  'unavailable': '회원탈퇴는 아직 준비 중이에요. 준비되면 알려 드릴게요.',
};

/// Never returns server text, a status code or a schema detail.
String accountDeletionMessage(Object? error) {
  if (error is! AccountDeletionException) return accountDeletionGenericFailure;
  return _byCode[error.code] ?? accountDeletionGenericFailure;
}

String _codeForStatus(int status) => switch (status) {
  401 => 'unauthorized',
  403 => 'admin_blocked',
  503 => 'unavailable',
  _ => 'deletion_failed',
};

abstract class AccountDeletionService {
  /// Whether the server refuses a deletion from a stale session.
  ///
  /// False in v1, and deliberately a contract rather than a behaviour: what
  /// counts as a recent authentication differs per provider, and Google, Apple
  /// and Kakao have not been through production sign-in yet. When that lands,
  /// the server decides and this flag reports it — the client never invents a
  /// re-authentication rule of its own.
  bool get requiresRecentAuthentication;

  /// Deletes the caller's own account. The caller is never named by the
  /// client; the server resolves it from the session.
  Future<void> deleteAccount();
}

class SupabaseAccountDeletionService implements AccountDeletionService {
  const SupabaseAccountDeletionService(this._client);
  final SupabaseClient _client;

  @override
  bool get requiresRecentAuthentication => false;

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await _client.functions.invoke(accountDeletionFunction);
      if (response.status == 200) return;
      throw AccountDeletionException(_codeForStatus(response.status));
    } on FunctionException catch (error) {
      throw AccountDeletionException(_codeForStatus(error.status));
    } on AccountDeletionException {
      rethrow;
    } catch (_) {
      // Network or transport failure. The account may or may not be gone, so
      // the screen must not claim either.
      throw const AccountDeletionException('deletion_failed');
    }
  }
}

/// Null until both the backend and the deletion endpoint are configured.
///
/// Fail-closed on purpose: the endpoint is a reviewed candidate that has not
/// been deployed, and an unconfigured build must say so rather than show a
/// fake success or a raw transport error.
final accountDeletionServiceProvider = Provider<AccountDeletionService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  if (!ref.watch(appConfigProvider).accountDeletionEnabled) return null;
  return SupabaseAccountDeletionService(client);
});
