import 'learning_info_row.dart';
import '../../study/study_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_email.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_information.dart';
import '../../../core/links/external_link.dart';
import '../../resources/domain/content_resource.dart';
import '../../../shared/widgets/shell_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final config = ref.watch(appConfigProvider);
    final email = ref.watch(currentAccountEmailProvider);
    final isAuthenticated =
        !auth.isLoading &&
        !auth.hasError &&
        auth.value?.isAuthenticated == true;
    return SafeArea(
      child: ShellPage(
        children: [
          const SectionHeader('계정'),
          if (auth.isLoading)
            const LinearProgressIndicator(semanticsLabel: '계정 확인 중')
          else if (auth.hasError)
            ErrorState(
              message: '계정을 불러오지 못했어요.',
              onRetry: () => ref.invalidate(authStateProvider),
            )
          else
            Text(isAuthenticated ? email ?? '로그인됨' : '로그인하지 않은 상태예요.'),
          const SectionHeader('프로필'),
          if (isAuthenticated)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('닉네임'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my/edit'),
            ),
          const SectionHeader('학습 정보'),
          const LearningInfoRow(),
          Consumer(
            builder: (context, ref, _) {
              final study = ref.watch(studyControllerProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('모의고사 응시시간을 공부시간에 포함'),
                    subtitle: const Text('이 기기의 기본값 · 시험마다 변경할 수 있어요'),
                    value: study.includeMockDefault,
                    onChanged: study.ready && !study.preferenceBusy
                        ? study.setIncludeMockDefault
                        : null,
                  ),
                  if (study.preferenceError != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(study.preferenceError!),
                    ),
                ],
              );
            },
          ),
          const SectionHeader('서비스 정보'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('문의·건의사항'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/my/feedback'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('앱 정보'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: '레전드스터디+',
              children: [
                Consumer(
                  builder: (context, ref, _) => ref
                      .watch(appVersionProvider)
                      .when(
                        data: (v) => Text('버전 $v'),
                        loading: () => const Text('버전 확인 중…'),
                        error: (_, _) => TextButton(
                          onPressed: () => ref.invalidate(appVersionProvider),
                          child: const Text('버전 다시 확인'),
                        ),
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
          const SectionHeader('약관 및 개인정보'),
          for (final policy in [
            ('개인정보처리방침', config.privacyUrl),
            ('이용약관', config.termsUrl),
          ])
            publicWebUri(policy.$2) == null
                ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(policy.$1),
                    subtitle: const Text('준비 중 · 문의·건의사항으로 연락해 주세요.'),
                  )
                : ExternalLinkButton(
                    uri: publicWebUri(policy.$2),
                    label: policy.$1,
                  ),
          if (isAuthenticated) ...[
            const Divider(),
            const SectionHeader('계정 관리'),
            const _LogoutButton(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '회원탈퇴',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('계정과 내 기록을 삭제해요'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my/delete-account'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerStatefulWidget {
  const _LogoutButton();
  @override
  ConsumerState<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends ConsumerState<_LogoutButton> {
  bool busy = false;
  String? error;
  Future<void> logout() async {
    if (busy) return;
    final action = ref.read(localLogoutProvider);
    if (action == null) {
      setState(() => error = '지금은 로그아웃할 수 없어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final owner = ref.read(authStateProvider).value?.userId;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      );
      if (!mounted ||
          confirmed != true ||
          ref.read(authStateProvider).value?.userId != owner) {
        return;
      }
      await action();
      // SDK auth event changes this page to Guest and invalidates owner providers.
    } catch (_) {
      if (mounted) setState(() => error = '로그아웃하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('이 기기에서 로그아웃해요. 저장한 자료와 계정은 삭제되지 않아요.'),
      if (error != null) Semantics(liveRegion: true, child: Text(error!)),
      TextButton(
        onPressed: busy ? null : logout,
        child: Text(busy ? '로그아웃 중…' : '로그아웃'),
      ),
    ],
  );
}
