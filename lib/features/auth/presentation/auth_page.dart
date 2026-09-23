import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';
import '../auth_errors.dart';
import '../native_auth.dart';
import '../auth_oauth.dart';
import '../auth_email.dart';
import '../auth_recovery.dart';
import 'auth_support_links.dart';
import 'provider_button.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.returnToPrevious = false});
  final bool returnToPrevious;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _signUp = false, _busy = false, _visible = false;
  String? _error, _notice;

  @override
  void dispose() {
    _confirm.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _passwordAuth() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) return;
    final service = ref.read(emailAuthServiceProvider);
    if (service == null) {
      setState(() => _error = '현재 로그인할 수 없어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    final profile = ref.read(profileRepositoryProvider);
    final signingUp = _signUp;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final authenticated = signingUp
          ? await service.signUp(_email.text.trim(), _password.text)
          : await service
                .login(_email.text.trim(), _password.text)
                .then((_) => true);
      if (authenticated) {
        try {
          await profile.upsertCurrentProfile();
        } catch (_) {
          /* Settings can retry. */
        }
      } else if (mounted) {
        setState(() {
          _notice = '가입을 요청했어요. 이메일 인증이 필요한 경우 받은 편지함과 스팸함을 확인한 뒤 로그인해 주세요.';
          _signUp = false;
          _password.clear();
          _confirm.clear();
          _form.currentState?.reset();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    if (_busy) return; // one flow at a time, across all three providers
    if (!ref.read(availableOAuthProvidersProvider).contains(provider)) {
      _message('현재 이 로그인 방식을 사용할 수 없습니다.');
      return;
    }
    final service = ref.read(oauthServiceProvider);
    if (service == null) {
      _message('지금은 소셜 로그인을 사용할 수 없어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      // Browser success only means opened; native success includes token exchange.
      // Both navigate only through the Supabase event handled by _onAuthStatus.
      final opened = await service.startSignIn(provider);
      if (!opened) {
        _message('소셜 로그인 화면을 열지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
    } on NativeAuthCancelled {
      _message('로그인을 취소했어요.');
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
    // Imperative push keeps the branch URI; the visible route owns the return.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (widget.returnToPrevious && context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
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
    final providers = ref.watch(availableOAuthProvidersProvider);
    return Form(
      key: _form,
      child: AutofillGroup(
        child: ShellPage(
          children: [
            const Text('나의 학습 기록을 이어가세요.'),
            SectionHeader(_signUp ? '회원가입' : '로그인'),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '이메일',
                errorMaxLines: 3,
              ),
              validator: (value) =>
                  isPlausibleEmail(value ?? '') ? null : '이메일 형식을 확인해 주세요.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: !_visible,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: [
                _signUp ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: _signUp
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: InputDecoration(
                labelText: '비밀번호',
                errorMaxLines: 3,
                helperMaxLines: 3,
                helperText: _signUp
                    ? '비밀번호는 $minimumPasswordLength자 이상 입력해 주세요.'
                    : null,
                suffixIcon: IconButton(
                  tooltip: _visible ? '비밀번호 숨기기' : '비밀번호 보기',
                  onPressed: _busy
                      ? null
                      : () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요.';
                if (_signUp && value.length < minimumPasswordLength) {
                  return '비밀번호는 $minimumPasswordLength자 이상으로 입력해 주세요.';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!_signUp) _passwordAuth();
              },
            ),
            if (_signUp) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  errorMaxLines: 3,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 한 번 더 입력해 주세요.';
                  }
                  return value == _password.text ? null : '두 비밀번호가 서로 달라요.';
                },
                onFieldSubmitted: (_) => _passwordAuth(),
              ),
            ],
            if (_error != null || _notice != null) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: Text(_error ?? _notice!)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _passwordAuth,
              child: Text(
                _busy
                    ? '처리 중…'
                    : _signUp
                    ? '회원가입'
                    : '로그인',
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _signUp = !_signUp;
                      _error = null;
                      _notice = null;
                      _password.clear();
                      _confirm.clear();
                      _visible = false;
                      _form.currentState?.reset();
                    }),
              child: Text(_signUp ? '로그인으로 돌아가기' : '처음이신가요? 회원가입'),
            ),
            if (!_signUp)
              TextButton(
                onPressed: _busy ? null : () => context.push('/auth/recovery'),
                child: const Text('비밀번호를 잊으셨나요?'),
              ),
            AuthSupportLinks(enabled: !_busy),
            if (providers.isNotEmpty) ...[
              const Divider(height: 32),
              const Text('다른 방법으로 로그인'),
              const SizedBox(height: 12),
              for (final provider in providers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ProviderButton(
                    provider: provider,
                    onPressed: _busy ? null : () => _oauth(provider),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
