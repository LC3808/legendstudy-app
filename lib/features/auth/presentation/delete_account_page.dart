import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
const anonymizedItems = <String>[
  '보내주신 문의·건의사항은 내용만 남고 계정 연결이 끊어져요',
];

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});
  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _understood = false, _busy = false;
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
    if (_busy) return; // duplicate tap guard
    final service = ref.read(accountDeletionServiceProvider);
    if (service == null) {
      setState(() => _error = accountDeletionMessage(
        const AccountDeletionException('unavailable'),
      ));
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
      // Only past this point is the account actually gone, so only now is any
      // local trace removed and the session ended.
      if (userId != null) {
        await purgeStudyOwner(ref.read(studyLocalStoreProvider), userId);
      }
      await ref.read(supabaseClientProvider)?.auth.signOut(
        scope: SignOutScope.local,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴가 완료되었어요. 그동안 이용해 주셔서 고맙습니다.')),
      );
      context.go('/home');
    } catch (error) {
      // The account may still exist, so nothing is signed out and no success
      // is claimed. Raw server text never reaches the user.
      if (mounted) setState(() => _error = accountDeletionMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authenticated =
        ref.watch(authStateProvider).value?.isAuthenticated ?? false;
    final available = ref.watch(accountDeletionServiceProvider) != null;
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
          const Text('남지만 연결이 끊어지는 것',
              style: TextStyle(fontWeight: FontWeight.w600)),
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
