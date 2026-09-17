import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../auth_errors.dart';
import '../auth_recovery.dart';

/// Sets a new password for the session a recovery link established.
///
/// `updateUser` requires a session, so without one the form is not offered at
/// all rather than failing after the user has typed a password twice.
class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});
  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return; // duplicate tap guard
    final service = ref.read(authRecoveryServiceProvider);
    if (service == null) {
      setState(() => _error = '지금은 변경할 수 없어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    if (_password.text.length < minimumPasswordLength) {
      setState(() => _error = '비밀번호는 $minimumPasswordLength자 이상으로 입력해 주세요.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = '두 비밀번호가 서로 달라요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await service.updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 변경했어요.')),
      );
      context.go('/my');
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).value;
    if (auth == null || !auth.isAuthenticated) {
      return ShellPage(
        children: [
          const SectionHeader('새 비밀번호 설정'),
          const Text('재설정 링크를 다시 열어 주세요.'),
          const SizedBox(height: 8),
          const Text(
            '비밀번호는 메일로 받은 재설정 링크를 연 뒤에만 변경할 수 있어요.',
            style: TextStyle(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/auth/recovery'),
            child: const Text('재설정 메일 다시 요청'),
          ),
        ],
      );
    }
    return ShellPage(
      children: [
        const SectionHeader('새 비밀번호 설정'),
        const Text('새로 사용할 비밀번호를 입력해 주세요.'),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: '새 비밀번호'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(_error!,
                style: const TextStyle(color: AppTokens.textPrimary)),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? '변경하는 중' : '비밀번호 변경'),
        ),
      ],
    );
  }
}
