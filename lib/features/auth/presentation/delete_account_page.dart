import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../study/data/study_local.dart';
import '../../study/study_providers.dart';
import '../account_deletion.dart';

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
      final status = switch (operation) {
        'request' => await service.requestDeletion(),
        'cancel' => await service.cancelDeletion(),
        _ => await service.readStatus(),
      };
      if (!mounted) return;
      if (ref.read(authStateProvider).value?.userId != ownerAtStart) {
        setState(() => _status = null);
        return;
      }
      setState(() => _status = status);
      if (operation == 'request') {
        final owner = ownerAtStart;
        try {
          await purgeStudyOwner(ref.read(studyLocalStoreProvider), owner);
        } catch (_) {
          if (mounted) {
            setState(() => _error = '탈퇴 요청은 접수됐어요. 이 기기의 기록 정리는 다시 확인해야 해요.');
          }
        }
      }
    } catch (_) {
      if (mounted) {
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
    final signedIn = owner != null;
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
        if (_status?.deadline != null)
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
        if (_error != null) Text(_error!),
      ],
    );
  }
}
