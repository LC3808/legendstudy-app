import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false, _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _passwordAuth() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해 주세요.')));
      return;
    }
    setState(() => _busy = true);
    try {
      if (_signUp) {
        final response = await client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (response.session == null) {
          _message('가입 안내가 이메일로 전송되었어요. 이메일 확인 후 로그인해 주세요.');
        } else {
          await _ensureProfile();
          _message('가입하고 로그인했어요.');
        }
      } else {
        await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await _ensureProfile();
        _message('로그인했어요.');
      }
    } on AuthException catch (error) {
      _message(error.message.isEmpty ? '인증에 실패했어요.' : error.message);
    } catch (_) {
      _message('인증에 실패했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null || _busy) return;
    setState(() => _busy = true);
    try {
      await client.auth.signInWithOAuth(
        provider,
        redirectTo: 'com.legendstudy.app://login-callback',
      );
    } catch (_) {
      _message('소셜 로그인을 시작하지 못했어요. provider 설정을 확인해 주세요.');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ensureProfile() async {
    try {
      await ref.read(profileRepositoryProvider).upsertCurrentProfile();
    } catch (_) {
      // Auth success remains valid; profile retry can happen on settings use.
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => ShellPage(
    children: [
      SectionHeader(_signUp ? '회원가입' : '로그인'),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: '이메일'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(labelText: '비밀번호'),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _passwordAuth,
        child: Text(_signUp ? '이메일로 회원가입' : '이메일로 로그인'),
      ),
      TextButton(
        onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
        child: Text(_signUp ? '이미 계정이 있어요' : '처음 시작하시나요? 회원가입'),
      ),
      const Divider(height: 28),
      const Text('소셜 로그인은 Supabase provider와 redirect 설정이 필요해요.'),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _oauth(OAuthProvider.google),
        icon: const Icon(Icons.account_circle_outlined),
        label: const Text('Google로 계속하기'),
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _oauth(OAuthProvider.apple),
        icon: const Icon(Icons.apple),
        label: const Text('Apple로 계속하기'),
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _oauth(OAuthProvider.kakao),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Kakao로 계속하기'),
      ),
    ],
  );
}
