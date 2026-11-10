import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/supabase/supabase_providers.dart';
import '../personal/personal_providers.dart';
import 'learning_repository.dart';

bool isInviteToken(String t) => RegExp(r'^[0-9a-f]{64}$').hasMatch(t);
String? inviteTokenFromUri(Uri uri) {
  final web =
      uri.scheme == 'https' &&
      uri.host == 'lab.legendstudy.com' &&
      uri.port == 443 &&
      ['/invite', '/invite/'].contains(uri.path);
  final native =
      uri.scheme == 'com.legendstudy.app' &&
      uri.host == 'invite' &&
      ['', '/'].contains(uri.path);
  if ((!web && !native) ||
      uri.userInfo.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      uri.queryParametersAll['t']?.length != 1) {
    return null;
  }
  final t = uri.queryParameters['t'];
  return t != null && isInviteToken(t) ? t : null;
}

String inviteUrl(String token) {
  if (!isInviteToken(token)) throw const LearningFailure();
  return 'https://lab.legendstudy.com/invite/?t=$token';
}

abstract interface class InviteStore {
  Future<String?> read();
  Future<void> write(String? value);
  Future<String> visitor();
}

class PreferenceInviteStore implements InviteStore {
  SharedPreferencesAsync get prefs => SharedPreferencesAsync();
  @override
  Future<String?> read() => prefs.getString('learning.pendingInvite.v1');
  @override
  Future<void> write(String? v) => v == null
      ? prefs.remove('learning.pendingInvite.v1')
      : prefs.setString('learning.pendingInvite.v1', v);
  @override
  Future<String> visitor() async {
    final old = await prefs.getString('learning.inviteVisitor.v1');
    if (old != null) return old;
    final value = const Uuid().v4().replaceAll('-', '');
    await prefs.setString('learning.inviteVisitor.v1', value);
    return value;
  }
}

class InviteLink {
  InviteLink(this.token, this.expires, this.hasSchool);
  final String token;
  final DateTime expires;
  final bool hasSchool;
  String get url => inviteUrl(token);
  factory InviteLink.parse(Object? data) {
    final r = object(data), token = string(object(data)['token']);
    if (!isInviteToken(token)) throw const LearningFailure();
    return InviteLink(
      token,
      DateTime.parse(string(r['expires_at'])),
      r['has_school'] == true,
    );
  }
}

class InviteController extends ChangeNotifier {
  InviteController(this.rpc, this.store);
  final LearningRpc Function() rpc;
  final InviteStore store;
  String? owner, message, token, boundOwner;
  String? confirmOffice, confirmSchool;
  bool busy = false, _disposed = false;
  int _epoch = 0;
  Future<void> _queue = Future.value();
  Future<void> _serial(Future<void> Function() work) {
    final next = _queue.then((_) => work());
    _queue = next.catchError((Object _) {});
    return next;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int e) => !_disposed && e == _epoch;
  Future<void> restore() => _serial(() async {
    try {
      final raw = await store.read();
      if (raw != null) {
        final r = object(jsonDecode(raw));
        final t = r['token'];
        if (t is String && isInviteToken(t)) {
          token = t;
          boundOwner = r['owner'] as String?;
          confirmOffice = r['office'] as String?;
          confirmSchool = r['school'] as String?;
        }
      }
      await _attribute();
    } catch (_) {
      message = '초대 기록을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  });
  Future<void> _save() => store.write(
    token == null
        ? null
        : jsonEncode({
            'token': token,
            'owner': boundOwner,
            'office': confirmOffice,
            'school': confirmSchool,
          }),
  );
  void identity(String? next) {
    if (next == owner) return;
    owner = next;
    _epoch++;
    message = null;
    unawaited(
      _serial(() async {
        await _attribute();
        _notify();
      }),
    );
    _notify();
  }

  Future<void> receive(Uri uri) => _serial(() async {
    final t = inviteTokenFromUri(uri);
    if (t == null) {
      message = '올바른 초대 링크를 입력해 주세요.';
      _notify();
      return;
    }
    final e = _epoch;
    busy = true;
    _notify();
    try {
      final call = rpc();
      final lookup = object(await call('invite_lookup', {'p_token': t}));
      if (!_current(e)) return;
      if (lookup['valid'] != true) {
        message = lookup['reason'] == 'expired'
            ? '초대 링크가 만료되었어요.'
            : '사용할 수 없는 초대 링크예요.';
        return;
      }
      if (token != t) {
        token = t;
        boundOwner = owner;
        confirmOffice = null;
        confirmSchool = null;
      }
      await _save();
      try {
        final visitor = await store.visitor();
        if (_current(e)) {
          await call('invite_record_visit', {
            'p_token': t,
            'p_visitor': visitor,
            'p_source': 'app',
          });
        }
      } catch (_) {
        /* Visit telemetry cannot block attribution. */
      }
      if (_current(e)) await _attribute();
    } catch (_) {
      if (_current(e)) message = '초대를 확인하지 못했어요. 연결을 확인하고 다시 시도해 주세요.';
    } finally {
      busy = false;
      _notify();
    }
  });
  Future<void> retry() => _serial(() async {
    await _attribute();
    _notify();
  });
  Future<void> _attribute() async {
    if (_disposed || token == null) return;
    if (owner == null) {
      message = '초대를 보관했어요. 가입·로그인 후 확인할 수 있어요.';
      return;
    }
    if (boundOwner != null && boundOwner != owner) return;
    if (confirmOffice != null) {
      message = '초대가 연결됐어요. 내 학교를 확인해 주세요.';
      return;
    }
    final e = _epoch, t = token!;
    try {
      boundOwner = owner;
      await _save();
      if (!_current(e)) return;
      final result = object(
        await rpc()('invite_attribute_signup', {'p_token': t}),
      );
      if (!_current(e)) return;
      if (result['attributed'] is! bool) throw const LearningFailure();
      final reason = string(result['reason']);
      if (result['attributed'] == true) {
        confirmOffice = result['office_code'] as String?;
        confirmSchool = result['school_code'] as String?;
        message = '초대가 연결됐어요.${confirmSchool != null ? ' 내 학교를 확인해 주세요.' : ''}';
        if (confirmSchool == null) token = null;
        await _save();
      } else {
        message = switch (reason) {
          'self' || 'self_invite' => '내 초대 링크는 가입 귀속에 사용할 수 없어요.',
          'expired' => '초대 링크가 만료되었어요.',
          'existing_user' ||
          'not_new_user' ||
          'too_old' ||
          'not_new_signup' => '기존 회원은 신규 가입 초대로 집계되지 않아요.',
          _ => '이 계정에는 신규 초대가 연결되지 않았어요.',
        };
        token = null;
        confirmSchool = null;
        confirmOffice = null;
        await _save();
      }
    } catch (_) {
      if (_current(e)) message = '초대 연결에 실패했어요. 연결을 확인하고 다시 시도해 주세요.';
    }
  }

  bool get needsSchoolConfirmation =>
      owner != null && boundOwner == owner && confirmSchool != null;
  Future<void> markSchoolConfirmed() => _serial(() async {
    if (!needsSchoolConfirmation) return;
    final e = _epoch;
    try {
      final result = object(await rpc()('invite_mark_school_confirmed', {}));
      if (result['ok'] != true) throw const LearningFailure();
      if (!_current(e)) return;
      token = null;
      confirmOffice = null;
      confirmSchool = null;
      await _save();
      message = '학교 확인을 완료했어요.';
    } catch (_) {
      if (_current(e)) message = '학교 확인 결과를 전송하지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  });
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}

final inviteStoreProvider = Provider<InviteStore>(
  (ref) => PreferenceInviteStore(),
);
final inviteControllerProvider = ChangeNotifierProvider<InviteController>((
  ref,
) {
  final controller = InviteController(
    () => ref.read(learningRpcProvider),
    ref.watch(inviteStoreProvider),
  );
  // Attribution checks profiles.created_at on the server. Wait for the
  // existing onboarding/profile bootstrap instead of rejecting a new signup.
  void syncIdentity() {
    final auth = ref.read(authStateProvider);
    final profile = ref.read(currentProfileProvider);
    final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
    controller.identity(
      !profile.isLoading && !profile.hasError && profile.value?.id == owner
          ? owner
          : null,
    );
  }

  ref.listen(authStateProvider, (_, _) => syncIdentity());
  ref.listen(currentProfileProvider, (_, _) => syncIdentity());
  syncIdentity();
  unawaited(controller.restore());
  return controller;
});
final inviteShareProvider = Provider<Future<void> Function(String)>(
  (ref) => (url) async {
    await const MethodChannel('com.legendstudy.app/invite-share')
        .invokeMethod<void>('share', url);
  },
);
