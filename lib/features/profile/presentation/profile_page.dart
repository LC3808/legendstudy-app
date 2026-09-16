import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
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
          subtitle: const Text('학교 저장은 로그인 후 가능해요'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/my/school'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('학년 설정'),
          subtitle: Text('로그인 후 학년을 저장할 수 있어요'),
          enabled: false,
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
        const Divider(),
        const SectionHeader('레전드스터디와 함께'),
        const CompactUtilityCard(
          title: '커피 한 잔 후원',
          body: '₩4,900 한 번의 후원으로 광고를 영구 제거해요. 후원 기능은 곧 만나요.',
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('앱 정보'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: '레전드스터디',
            applicationVersion: '0.1.0',
          ),
        ),
      ],
    );
  }
}
