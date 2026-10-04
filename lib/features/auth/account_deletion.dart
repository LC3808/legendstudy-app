import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/supabase/supabase_providers.dart';

const accountDeletionFunction = 'delete-account';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.code);
  final String code;
}

const accountDeletionGenericFailure =
    '탈퇴 요청을 처리하지 못했어요. 다시 로그인하거나 잠시 후 시도해 주세요.';
String accountDeletionMessage(Object? error) => accountDeletionGenericFailure;

class DeletionStatus {
  const DeletionStatus(this.state, {this.requestId, this.deadline});
  final String state;
  final String? requestId;
  final DateTime? deadline;
  factory DeletionStatus.fromJson(Map<String, dynamic> value) {
    final state = value['state'];
    if (!const [
      'NORMAL',
      'DELETION_PENDING',
      'ERASING',
      'CANCELLED',
      'ERASED',
    ].contains(state)) {
      throw const AccountDeletionException('invalid_response');
    }
    final deadline = value['scheduled_deletion_at'] == null
        ? null
        : DateTime.tryParse(value['scheduled_deletion_at'] as String);
    if ((state == 'DELETION_PENDING' || state == 'ERASING') &&
        deadline == null) {
      throw const AccountDeletionException('invalid_response');
    }
    return DeletionStatus(
      state as String,
      requestId: value['request_id'] as String?,
      deadline: deadline,
    );
  }
}

abstract class AccountDeletionService {
  bool get requiresRecentAuthentication;
  Future<DeletionStatus> requestDeletion();
  Future<DeletionStatus> readStatus();
  Future<DeletionStatus> cancelDeletion();
}

class SupabaseAccountDeletionService implements AccountDeletionService {
  const SupabaseAccountDeletionService(this._client);
  final SupabaseClient _client;
  @override
  bool get requiresRecentAuthentication => true;
  Future<DeletionStatus> _call(String operation) async {
    try {
      final response = await _client.functions.invoke(
        accountDeletionFunction,
        body: {'operation': operation},
      );
      if (response.status != 200 && response.status != 202) {
        throw const AccountDeletionException('denied');
      }
      return DeletionStatus.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      throw const AccountDeletionException('lifecycle_request_denied');
    }
  }

  @override
  Future<DeletionStatus> requestDeletion() => _call('request');
  @override
  Future<DeletionStatus> readStatus() => _call('status');
  @override
  Future<DeletionStatus> cancelDeletion() => _call('cancel');
}

final accountDeletionServiceProvider = Provider<AccountDeletionService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null || !ref.watch(appConfigProvider).accountDeletionEnabled) {
    return null;
  }
  return SupabaseAccountDeletionService(client);
});

// A lifecycle lookup is scoped to the observed owner. Unknown/error states do
// not reopen personalized routes while deletion protection is enabled.
final accountLifecycleStatusProvider = FutureProvider<DeletionStatus?>((
  ref,
) async {
  final owner = ref.watch(authStateProvider).value?.userId;
  final service = ref.watch(accountDeletionServiceProvider);
  if (owner == null || service == null) return null;
  return service.readStatus().timeout(const Duration(seconds: 15));
});

String? accountLifecycleRedirect({
  required bool enabled,
  required bool authenticated,
  required AsyncValue<DeletionStatus?> status,
  required String location,
}) {
  if (!enabled || !authenticated) return null;
  if (location == '/my/delete-account' || location.startsWith('/auth')) {
    return null;
  }
  final state = status.asData?.value?.state;
  if (state == 'NORMAL' || state == 'CANCELLED') return null;
  return '/my/delete-account';
}

final accountEmailReauthenticationProvider =
    Provider<Future<void> Function(String)?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return null;
      return (password) async {
        final response = await client.functions
            .invoke(
              'account-deletion-worker/reauth',
              body: {'provider': 'email', 'password': password},
            )
            .timeout(const Duration(seconds: 20));
        if (response.status != 200 ||
            response.data is! Map ||
            response.data['state'] != 'REAUTHENTICATED') {
          throw const AccountDeletionException('reauth_required');
        }
      };
    });
