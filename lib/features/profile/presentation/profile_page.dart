import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_email.dart';
import '../../personal/personal_providers.dart';
import '../../school/school_providers.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_information.dart';
import '../../../core/links/external_link.dart';
import '../../resources/domain/content_resource.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../../shared/widgets/legendstudy_lab_entry.dart';
import '../../feedback/feedback_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final config = ref.watch(appConfigProvider);
    final email = ref.watch(currentAccountEmailProvider);
    final admin = ref.watch(adminAccessProvider);
    final currentUserId = auth.value?.userId;
    final isAuthenticated = auth.value?.isAuthenticated == true;
    final showAdminMenu =
        currentUserId != null &&
        admin.value?.userId == currentUserId &&
        admin.value?.isAdmin == true;
    return ShellPage(
      children: [
        const AppHeader(title: 'MY', subtitle: '나의 학습 공간'),
        auth.when(
          loading: () =>
              const LinearProgressIndicator(semanticsLabel: '계정 상태 확인'),
          error: (_, _) => ErrorState(
            message: '계정 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(authStateProvider),
          ),
          data: (state) => CompactUtilityCard(
            title: state.isAuthenticated ? '로그인 계정' : '공부의 흐름을 이어가요',
            body: state.isAuthenticated
                ? [
                    if (email != null) email,
                    '내 자료와 학습 기록을 한곳에서 관리해요.',
                  ].join('\n')
                : '로그인하면 자료와 공부 기록을 저장할 수 있어요.',
            action: state.isAuthenticated
                ? null
                : FilledButton(
                    onPressed: () => context.push('/auth'),
                    child: const Text('로그인 / 시작하기'),
                  ),
          ),
        ),
        const SectionHeader('내 정보'),
        _ProfileSetting(
          label: '학교',
          value: ref.watch(schoolSelectionProvider).whenData((s) => s?.name),
          authLoading: auth.isLoading,
          authError: auth.hasError,
          onRetry: () => auth.hasError
              ? ref.invalidate(authStateProvider)
              : ref.invalidate(schoolSelectionProvider),
          onEdit: () => context.push('/my/school'),
        ),
        _ProfileSetting(
          label: '학년',
          value: ref
              .watch(currentProfileProvider)
              .whenData(
                (p) => p?.gradeLevel == null ? null : '고등학교 ${p!.gradeLevel}학년',
              ),
          authLoading: auth.isLoading,
          authError: auth.hasError,
          onRetry: () => auth.hasError
              ? ref.invalidate(authStateProvider)
              : ref.invalidate(currentProfileProvider),
          onEdit: () => context.push('/my/grade'),
        ),
        const Divider(),
        const SectionHeader('나의 자료'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('저장한 자료'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/my/saved'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('최근 본 자료'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/my/recent'),
        ),
        const Divider(),
        const SectionHeader('서비스'),
        const LegendStudyLabEntry(),
        const SectionHeader('설정 · 지원'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('문의·건의사항'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/my/feedback'),
        ),
        if (showAdminMenu) ...[
          const Divider(),
          const SectionHeader('관리자'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inbox_outlined),
            title: const Text('문의 관리'),
            subtitle: const Text('접수된 문의를 확인하고 상태를 관리해요.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/my/admin/feedback'),
          ),
        ],
        const Divider(),
        const SectionHeader('앱 정보 · 정책'),
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
            title: const Text('회원탈퇴'),
            subtitle: const Text('계정과 내 기록을 삭제해요'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/my/delete-account'),
          ),
        ],
      ],
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

class _ProfileSetting extends StatelessWidget {
  const _ProfileSetting({
    required this.label,
    required this.value,
    required this.authLoading,
    required this.authError,
    required this.onRetry,
    required this.onEdit,
  });
  final String label;
  final AsyncValue<String?> value;
  final bool authLoading, authError;
  final VoidCallback onRetry, onEdit;

  @override
  Widget build(BuildContext context) {
    final loading = authLoading || value.isLoading;
    final failed = authError || value.hasError;
    final configured = value.value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          if (loading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(semanticsLabel: '$label 불러오는 중'),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    failed
                        ? '$label 정보를 불러오지 못했어요.'
                        : value.value ??
                              (label == '학교' ? '학교를 설정해 주세요' : '학년을 설정해 주세요'),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label:
                      '$label ${failed
                          ? '다시 시도'
                          : configured
                          ? '변경'
                          : '설정'}',
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: failed ? onRetry : onEdit,
                    child: Text(
                      failed
                          ? '재시도'
                          : configured
                          ? '변경'
                          : '설정',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
