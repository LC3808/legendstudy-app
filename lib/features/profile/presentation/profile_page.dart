import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_information.dart';
import '../../../core/links/external_link.dart';
import '../../resources/domain/content_resource.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../feedback/feedback_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final config = ref.watch(appConfigProvider);
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
            title: state.isAuthenticated ? '나의 계정' : '공부의 흐름을 이어가요',
            body: state.isAuthenticated
                ? '내 자료와 학습 기록을 한곳에서 관리해요.'
                : '로그인하면 자료와 공부 기록을 저장할 수 있어요.',
            action: state.isAuthenticated
                ? null
                : FilledButton(
                    onPressed: () => context.push('/auth'),
                    child: const Text('로그인 / 시작하기'),
                  ),
          ),
        ),
        if (auth.value?.isAuthenticated == true)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final client = ref.read(supabaseClientProvider);
                if (client == null) return;
                await client.auth.signOut(scope: SignOutScope.local);
              },
              child: const Text('로그아웃'),
            ),
          ),
        const SectionHeader('나의 설정'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.school_outlined),
          title: const Text('학교 설정'),
          subtitle: Text(
            isAuthenticated ? '학교와 급식 설정을 관리해요' : '학교 저장은 로그인 후 가능해요',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/my/school'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('학년 설정'),
          subtitle: Text(
            isAuthenticated ? '학년을 저장하고 학습을 맞춤 설정해요' : '로그인 후 학년을 저장할 수 있어요',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/my/grade'),
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
        if (isAuthenticated)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('회원탈퇴'),
            subtitle: const Text('계정과 내 기록을 삭제해요'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/my/delete-account'),
          ),
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
      ],
    );
  }
}
