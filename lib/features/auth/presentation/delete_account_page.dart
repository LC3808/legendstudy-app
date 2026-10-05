import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../study/data/study_local.dart';
import '../../study/study_providers.dart';
import '../account_deletion.dart';
import '../auth_email.dart';

/// Minimal lifecycle screen; shared restricted routing/reauth flow remains gated.
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});
  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  DeletionStatus? _status;
  String? _loadedOwner;
  bool _busy = false, _confirmed = false;
  String? _error;
  final _password = TextEditingController();
  String? _viewOwner;
  bool _cleanupPending = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _cleanup(String owner) async {
    try {
      await purgeStudyOwner(ref.read(studyLocalStoreProvider), owner);
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() => _cleanupPending = false);
      }
    } catch (_) {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() {
          _cleanupPending = true;
          _error = '탈퇴 요청은 접수됐어요. 기기 기록 정리를 다시 시도해 주세요.';
        });
      }
    }
  }

  String _providerLabel(String provider) => switch (provider) {
    'google' => 'Google',
    'apple' => 'Apple',
    'kakao' => 'Kakao',
    _ => provider,
  };

  Future<void> _logout() async {
    final logout = ref.read(localLogoutProvider);
    if (_busy || logout == null) return;
    setState(() => _busy = true);
    try {
      await logout().timeout(const Duration(seconds: 15));
    } catch (_) {
      if (mounted) setState(() => _error = '로그아웃하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _run(String operation) async {
    if (_busy || !mounted) return;
    final service = ref.read(accountDeletionServiceProvider);
    if (service == null) return;
    final ownerAtStart = ref.read(authStateProvider).value?.userId;
    if (ownerAtStart == null) return;
    if (operation == 'status') _loadedOwner = ownerAtStart;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (operation == 'cancel') {
        // Pick the reauthentication path from the verified sign-in provider, not from
        // any user-editable field. A fresh same-owner challenge is required to cancel.
        final provider = ref.read(accountPrimaryProviderProvider);
        Future<void>? reauth;
        switch (provider) {
          case 'email':
            final email = ref.read(accountEmailReauthenticationProvider);
            if (email != null) {
              final password = _password.text;
              _password.clear();
              reauth = email(password);
            }
          case 'google':
            reauth = ref.read(accountGoogleReauthenticationProvider)?.call();
          case 'apple':
            reauth = ref.read(accountAppleReauthenticationProvider)?.call();
          case 'kakao':
            reauth = ref.read(accountKakaoReauthenticationProvider)?.call();
        }
        if (reauth == null) {
          setState(() => _error = '이 계정의 재인증 방식을 사용할 수 없어요.');
          return;
        }
        await reauth;
        if (!mounted ||
            ref.read(authStateProvider).value?.userId != ownerAtStart) {
          return;
        }
      }
      final status = await (switch (operation) {
        'request' => service.requestDeletion(),
        'cancel' => service.cancelDeletion(),
        _ => service.readStatus(),
      }).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (ref.read(authStateProvider).value?.userId != ownerAtStart) {
        setState(() => _status = null);
        return;
      }
      setState(() => _status = status);
      ref.invalidate(accountLifecycleStatusProvider);
      if (status.state == 'DELETION_PENDING' ||
          status.state == 'ERASING' ||
          status.state == 'ERASED') {
        await _cleanup(ownerAtStart);
      }
    } catch (_) {
      if (mounted &&
          ref.read(authStateProvider).value?.userId == ownerAtStart) {
        setState(
          () => _error = operation == 'cancel'
              ? '본인 재인증이 필요하거나 취소 가능 시간이 지났어요.'
              : accountDeletionGenericFailure,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(authStateProvider).value?.userId;
    if (owner != _viewOwner) {
      _viewOwner = owner;
      _confirmed = false;
      _password.clear();
      _error = null;
      _status = null;
      _loadedOwner = null;
      _cleanupPending = false;
    }
    final signedIn = owner != null;
    final provider = ref.watch(accountPrimaryProviderProvider);
    final available =
        signedIn && ref.watch(accountDeletionServiceProvider) != null;
    if (available && owner != _loadedOwner && !_busy) {
      Future.microtask(() => _run('status'));
    }
    final state = owner == _loadedOwner ? _status?.state : null;
    final pending = state == 'DELETION_PENDING';
    final normal = state == 'NORMAL' || state == 'CANCELLED';
    return ShellPage(
      children: [
        const SectionHeader('탈퇴 요청'),
        if (!signedIn) const Text('로그인한 뒤에 탈퇴를 요청할 수 있어요.'),
        if (signedIn && !available) const Text('회원탈퇴는 아직 준비 중이에요.'),
        if (_busy) const LinearProgressIndicator(),
        if (pending) const Text('탈퇴 요청이 접수됐어요. 개인화 서비스 이용이 제한됩니다.'),
        if (state == 'ERASING') const Text('개인정보 파기 중이에요. 탈퇴를 취소할 수 없어요.'),
        if (state == 'ERASED') const Text('개인정보 파기가 확인됐어요.'),
        if (state == 'CANCELLED') const Text('탈퇴 요청을 취소했어요.'),
        if (owner == _loadedOwner && _status?.deadline != null)
          Text('파기 예정 시각: ${_status!.deadline!.toLocal().toIso8601String()}'),
        if (available && normal) ...[
          const Text(
            '요청 즉시 개인화 서비스가 제한되며, 336시간 후 개인정보를 자동 파기합니다. 로그인만으로 취소되지 않습니다.',
          ),
          CheckboxListTile(
            value: _confirmed,
            onChanged: _busy
                ? null
                : (v) => setState(() => _confirmed = v ?? false),
            title: const Text('삭제 일정과 이용 제한을 이해했어요'),
          ),
          FilledButton(
            onPressed: !_busy && _confirmed ? () => _run('request') : null,
            child: const Text('탈퇴 요청하기'),
          ),
        ],
        if (available && pending) ...[
          const Text('예정 시각 전 본인 재인증 후에만 명시적으로 취소할 수 있어요.'),
          if (provider == 'email' &&
              ref.watch(accountEmailReauthenticationProvider) != null)
            TextField(
              controller: _password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: '이메일 계정 비밀번호'),
            ),
          if (provider == 'google' ||
              provider == 'apple' ||
              provider == 'kakao')
            Text(
              '탈퇴를 취소하려면 ${_providerLabel(provider!)} 계정으로 다시 로그인해 본인 확인을 완료해요. 로그인만으로 탈퇴가 취소되지는 않습니다.',
            ),
          OutlinedButton(
            onPressed: _busy ? null : () => _run('cancel'),
            child: const Text('탈퇴 취소'),
          ),
        ],
        if (available)
          TextButton(
            onPressed: _busy ? null : () => _run('status'),
            child: const Text('상태 확인'),
          ),
        if (_cleanupPending && owner != null)
          TextButton(
            onPressed: _busy ? null : () => _cleanup(owner),
            child: const Text('기기 기록 정리 재시도'),
          ),
        if (signedIn && ref.watch(localLogoutProvider) != null)
          TextButton(
            onPressed: _busy ? null : _logout,
            child: const Text('로그아웃'),
          ),
        if (_error != null) Text(_error!),
      ],
    );
  }
}
