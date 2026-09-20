import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../study/data/study_local.dart';
import '../../study/study_providers.dart';
import '../account_deletion.dart';

/// What deletion actually does, stated at the level the schema guarantees.
///
/// Each line matches a real foreign key: everything user-owned cascades from
/// the auth user, and feedback is detached rather than removed because it is
/// an operational record. Nothing here promises more than that.
const deletedItems = <String>[
  '프로필 (이름, 학년, 학교 설정, D-Day)',
  '저장한 자료와 최근 본 자료',
  '공부 기록과 모의고사 채점 기록',
  '이 기기에 저장된 내 공부 기록',
];
const anonymizedItems = <String>['보내주신 문의·건의사항은 내용만 남고 계정 연결이 끊어져요'];

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});
  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _understood = false, _busy = false, _serverDeleted = false;
  bool _localCleaned = false, _signedOut = false;
  String? _deletedOwner;
  String? _error;

  Future<bool> _confirm() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정말 탈퇴할까요?'),
        content: const Text('탈퇴하면 위 내용이 처리되고, 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _delete() async {
    if (_busy || _serverDeleted) return; // never resend a confirmed deletion
    final service = ref.read(accountDeletionServiceProvider);
    if (service == null) {
      setState(
        () => _error = accountDeletionMessage(
          const AccountDeletionException('unavailable'),
        ),
      );
      return;
    }
    if (!await _confirm() || !mounted) return;
    final userId = ref.read(authStateProvider).value?.userId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await service.deleteAccount();
      _serverDeleted = true;
      _deletedOwner = userId;
      await _finishLocalCleanup();
    } catch (error) {
      // Only a failed server request reaches here. Raw server text is hidden.
      if (mounted) setState(() => _error = accountDeletionMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishLocalCleanup() async {
    if (!_serverDeleted) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    if (!_localCleaned) {
      try {
        if (_deletedOwner != null) {
          await purgeStudyOwner(
            ref.read(studyLocalStoreProvider),
            _deletedOwner!,
          );
        }
        _localCleaned = true;
      } catch (_) {
        /* Retry only this device's cleanup, never the server delete. */
      }
    }
    if (!_signedOut) {
      try {
        // Do not sign out a different user who signed in while deletion ran.
        if (ref.read(authStateProvider).value?.userId == _deletedOwner) {
          await ref.read(postDeleteSignOutProvider)();
        }
        _signedOut = true;
      } catch (_) {
        /* Still try logout even if local file cleanup failed. */
      }
    }
    if (!mounted) return;
    if (_localCleaned && _signedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴가 완료되었어요. 그동안 이용해 주셔서 고맙습니다.')),
      );
      context.go('/home');
    } else {
      setState(() {
        _busy = false;
        _error = '계정 삭제는 완료됐어요. 이 기기의 기록 또는 로그인 정보 정리가 남아 있어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: !_busy, child: _content(context));

  Widget _content(BuildContext context) {
    final authenticated =
        ref.watch(authStateProvider).value?.isAuthenticated ?? false;
    final available = ref.watch(accountDeletionServiceProvider) != null;
    if (_serverDeleted) {
      return ShellPage(
        children: [
          const SectionHeader('계정 삭제 완료'),
          Text(_error ?? '이 기기의 정보를 정리하고 있어요.'),
          FilledButton(
            onPressed: _busy ? null : _finishLocalCleanup,
            child: Text(_busy ? '정리 중…' : '기기 정보 정리 다시 시도'),
          ),
          const Text('계정을 다시 삭제하지 않아요. 정리가 계속 실패하면 문의해 주세요.'),
        ],
      );
    }
    if (authenticated && !available) {
      return ShellPage(
        children: [
          const SectionHeader('회원탈퇴'),
          Text(
            accountDeletionMessage(
              const AccountDeletionException('unavailable'),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/my/feedback'),
            child: const Text('문의·건의사항'),
          ),
        ],
      );
    }
    return ShellPage(
      children: [
        const SectionHeader('회원탈퇴'),
        if (!authenticated) ...[
          const Text('로그인한 뒤에 탈퇴할 수 있어요.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/auth'),
            child: const Text('로그인하러 가기'),
          ),
        ] else ...[
          const Text('탈퇴하면 아래 내용이 처리돼요.'),
          const SizedBox(height: 16),
          const Text('삭제되는 것', style: TextStyle(fontWeight: FontWeight.w600)),
          for (final item in deletedItems) Text('· $item'),
          const SizedBox(height: 12),
          const Text(
            '남지만 연결이 끊어지는 것',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final item in anonymizedItems) Text('· $item'),
          const SizedBox(height: 12),
          const Text(
            '탈퇴 후에는 같은 이메일로 다시 가입할 수 있지만, 이전 기록은 복구할 수 없어요.',
            style: TextStyle(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _understood,
            onChanged: _busy
                ? null
                : (value) => setState(() => _understood = value ?? false),
            title: const Text('위 내용을 이해했어요'),
          ),
          if (!available) ...[
            const SizedBox(height: 8),
            const Text('회원탈퇴는 아직 준비 중이에요. 준비되면 알려 드릴게요.'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: const TextStyle(color: AppTokens.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (!_understood || _busy || !available) ? null : _delete,
            child: Text(_busy ? '처리 중' : '회원탈퇴'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => context.canPop() ? context.pop() : context.go('/my'),
            child: const Text('돌아가기'),
          ),
        ],
      ],
    );
  }
}
