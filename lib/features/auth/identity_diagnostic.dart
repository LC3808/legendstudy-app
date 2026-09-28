import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const identityProject = 'stlhijzpjfgwwdgunlsd';

/// One-time, private diagnostic only. A digest is pseudonymous, not public data.
String identityDigest(String salt, String userId) =>
    Hmac(sha256, utf8.encode(salt))
        .convert(
          utf8.encode('legendstudy-identity-v1|$identityProject|$userId'),
        )
        .toString();

class IdentityDiagnostic {
  IdentityDiagnostic(this.client, this.salt, this.expires, this.emit);
  final SupabaseClient client;
  final String salt;
  final DateTime expires;
  final void Function(Map<String, Object>) emit;
  int _epoch = 0;
  bool _closed = false;
  StreamSubscription<AuthState>? _subscription;

  void start() {
    _subscription = client.auth.onAuthStateChange.listen((state) {
      // Do not await an Auth request inside the SDK auth-event callback.
      unawaited(probe(state.event.name));
    });
    unawaited(probe('initial_snapshot'));
  }

  Future<void> probe(String event) async {
    final epoch = ++_epoch;
    await Future<void>.delayed(Duration.zero);
    if (_closed || epoch != _epoch || !DateTime.now().isBefore(expires)) return;
    final before = client.auth.currentSession;
    Map<String, Object> record(String status) => {
      'schema': 'legendstudy-identity-v1',
      'surface': 'app',
      'project': identityProject,
      'challenge': sha256.convert(utf8.encode(salt)).toString(),
      'observed_at': DateTime.now().toUtc().toIso8601String(),
      'event': event,
      'status': status,
    };
    if (before == null) {
      emit(record('signed_out'));
      return;
    }
    try {
      final result = await client.auth.getUser(); // server validated, GET only
      if (_closed || epoch != _epoch || !DateTime.now().isBefore(expires)) {
        return;
      }
      final after = client.auth.currentSession;
      if (after == null ||
          after.accessToken != before.accessToken ||
          after.user.id != before.user.id ||
          result.user?.id != before.user.id) {
        emit(record('session_changed'));
        return;
      }
      emit({
        ...record('verified'),
        'digest': identityDigest(salt, result.user!.id),
      });
    } catch (_) {
      if (!_closed && epoch == _epoch) emit(record('verification_failed'));
      // Never log SDK exceptions, tokens, provider metadata, email or raw IDs.
    }
  }

  Future<void> close() async {
    _closed = true;
    _epoch++;
    await _subscription?.cancel();
  }
}

/// Default OFF; Release always OFF. Operator generates short-lived defines locally.
void startIdentityDiagnostic(SupabaseClient? client) {
  if (kReleaseMode || !const bool.fromEnvironment('IDENTITY_DIAGNOSTIC')) {
    return;
  }
  const salt = String.fromEnvironment('IDENTITY_DIAGNOSTIC_SALT');
  const deadline = String.fromEnvironment('IDENTITY_DIAGNOSTIC_EXPIRES');
  final expires = DateTime.tryParse(deadline);
  if (client == null ||
      !RegExp(r'^[0-9a-f]{64}$').hasMatch(salt) ||
      expires == null ||
      !DateTime.now().isBefore(expires) ||
      expires.difference(DateTime.now()) > const Duration(hours: 2)) {
    return;
  }
  IdentityDiagnostic(client, salt, expires, (record) {
    debugPrint('LS_IDENTITY_CHECK ${jsonEncode(record)}');
  }).start();
}
