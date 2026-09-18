import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../auth_errors.dart';
import '../auth_recovery.dart';

/// Starts password recovery. The success copy is identical whether or not the
/// address has an account, so the screen never discloses who is registered.
class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key, this.linkFailed = false});

  /// Set when the screen was opened because a recovery link could not be used.
  final bool linkFailed;

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  final _email = TextEditingController();
  bool _busy = false, _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.linkFailed) _error = recoveryLinkUnusableMessage;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return; // duplicate tap guard
    final service = ref.read(authRecoveryServiceProvider);
    if (service == null) {
      setState(() => _error = '지금은 요청할 수 없어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    if (!isPlausibleEmail(_email.text)) {
      setState(() => _error = '이메일 형식을 확인해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await service.sendRecoveryEmail(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ShellPage(
    children: _sent ? _sentView(context) : _formView(context),
  );

  List<Widget> _sentView(BuildContext context) => [
    const SectionHeader('비밀번호 재설정'),
    const Text('비밀번호 재설정 안내를 확인해 주세요.'),
    const SizedBox(height: 8),
    const Text(
      '입력한 주소로 가입된 계정이 있다면 재설정 메일이 발송돼요. 메일이 보이지 않으면 스팸함도 확인해 주세요.',
      style: TextStyle(color: AppTokens.textSecondary),
    ),
    const SizedBox(height: 20),
    FilledButton(
      onPressed: () => context.canPop() ? context.pop() : context.go('/auth'),
      child: const Text('로그인으로 돌아가기'),
    ),
  ];

  List<Widget> _formView(BuildContext context) => [
    const SectionHeader('비밀번호 재설정'),
    const Text('가입할 때 사용한 이메일 주소를 입력해 주세요.'),
    const SizedBox(height: 16),
    TextField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enabled: !_busy,
      decoration: const InputDecoration(labelText: '이메일'),
      onSubmitted: (_) => _submit(),
    ),
    if (_error != null) ...[
      const SizedBox(height: 12),
      Semantics(
        liveRegion: true,
        child: Text(_error!, style: const TextStyle(color: AppTokens.textPrimary)),
      ),
    ],
    const SizedBox(height: 20),
    FilledButton(
      onPressed: _busy ? null : _submit,
      child: Text(_busy ? '보내는 중' : '재설정 메일 보내기'),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => context.canPop() ? context.pop() : context.go('/auth'),
      child: const Text('로그인으로 돌아가기'),
    ),
  ];
}
