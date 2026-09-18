import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';
import '../auth_errors.dart';
import '../auth_oauth.dart';

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
        final response = await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await _ensureProfile();
        await _waitForAuthenticatedState(response.user?.id);
        if (mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/my');
          }
        }
        _message('로그인했어요.');
      }
    } catch (error) {
      // Raw SDK English never reaches the user.
      _message(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    if (_busy) return; // one flow at a time, across all three providers
    final service = ref.read(oauthServiceProvider);
    if (service == null) {
      _message('지금은 소셜 로그인을 사용할 수 없어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      // The result only says the provider page opened. The session, if any,
      // arrives later on the auth stream and is handled by _onAuthStatus.
      final opened = await service.startSignIn(provider);
      if (!opened) {
        _message('소셜 로그인 화면을 열지 못했어요. provider 설정을 확인해 주세요.');
      }
    } catch (error) {
      _message(authErrorMessage(error));
    } finally {
      // Always released: the user may come straight back by cancelling, and a
      // stuck busy flag would disable every sign-in button on this screen.
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Single return policy for this screen, whichever way the user signed in.
  ///
  /// Scope is deliberately narrow, because this is the only screen allowed to
  /// act on an ordinary sign-in:
  ///
  /// * only `signedIn` moves anyone. `tokenRefreshed` and `userUpdated` are
  ///   housekeeping on a session the user already had, and must not navigate.
  /// * only while this screen is the current route, so a cold-start callback —
  ///   where the app simply starts signed in somewhere else — is left alone,
  ///   and so is the password path if it pops first.
  /// * never on recovery: `/auth/new-password` is the router's to open.
  ///
  /// A cancelled or failed provider callback arrives as a carried failure
  /// rather than an event, so it is reported in Korean instead of silence.
  void _onAuthStatus(AuthStatus? status) {
    if (status == null || !mounted) return;
    final failure = status.failure;
    if (failure != null) {
      // An unusable recovery link is explained by the recovery screen the
      // router is already opening; saying it twice would be noise.
      if (!isRecoveryLinkFailure(failure)) _message(authErrorMessage(failure));
      return;
    }
    if (!status.isAuthenticated ||
        status.event != AuthChangeEvent.signedIn ||
        status.isPasswordRecovery) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.routerDelegate.currentConfiguration.uri.path != '/auth') return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my');
    }
  }

  Future<void> _ensureProfile() async {
    try {
      await ref.read(profileRepositoryProvider).upsertCurrentProfile();
    } catch (_) {
      // Auth success remains valid; profile retry can happen on settings use.
    }
  }

  Future<void> _waitForAuthenticatedState(String? expectedUserId) async {
    if (expectedUserId == null) throw StateError('Missing authenticated user');
    final current = ref.read(authStateProvider).value?.userId;
    if (current == expectedUserId) return;
    final state = await ref.read(authStateProvider.future);
    if (state.userId != expectedUserId) {
      throw StateError('Auth state did not settle for the signed-in user');
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthStatus>>(
      authStateProvider,
      (_, next) => _onAuthStatus(next.value),
    );
    return ShellPage(
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
        if (!_signUp)
          TextButton(
            onPressed: _busy ? null : () => context.push('/auth/recovery'),
            child: const Text('비밀번호를 잊으셨나요?'),
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
}
