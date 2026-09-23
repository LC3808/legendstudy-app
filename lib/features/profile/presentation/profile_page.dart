import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'learning_info_row.dart';
import '../../study/study_providers.dart';
import '../../personal/personal_providers.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../feedback/feedback_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(currentProfileProvider);
    final admin = ref.watch(adminAccessProvider);
    final currentUserId = auth.value?.userId;
    final showAdminMenu =
        currentUserId != null &&
        admin.value?.userId == currentUserId &&
        admin.value?.isAdmin == true;
    return ShellPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: AppHeader(title: 'MY')),
            IconButton(
              tooltip: '설정',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => context.push('/my/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        auth.when(
          loading: () =>
              const LinearProgressIndicator(semanticsLabel: '계정 상태 확인'),
          error: (_, _) => ErrorState(
            message: '계정 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(authStateProvider),
          ),
          data: (state) => state.isAuthenticated
              ? profile.when(
                  loading: () => const LinearProgressIndicator(
                    semanticsLabel: '프로필 불러오는 중',
                  ),
                  error: (_, _) => ErrorState(
                    message: '프로필을 불러오지 못했어요.',
                    onRetry: () => ref.invalidate(currentProfileProvider),
                  ),
                  data: (p) => Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p?.displayName ?? '닉네임 설정',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () => context.push('/my/edit'),
                              child: const Text('프로필 편집'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () => context.push('/auth'),
                    child: const Text('로그인 / 시작하기'),
                  ),
                ),
        ),
        const LearningInfoRow(),
        const SectionHeader('학습'),
        Consumer(
          builder: (context, ref, _) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ref.watch(studyControllerProvider).summary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/study'),
          ),
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
      ],
    );
  }
}
