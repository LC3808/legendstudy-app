import '../../lab/score_summary.dart';
import '../avatar.dart';

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
        LsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                            SizedBox(
                              width: 72,
                              child: ProfileAvatar(
                                key: ValueKey(currentUserId),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p?.displayName ?? '닉네임 설정',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  if (p?.displayName?.trim().isNotEmpty != true)
                                    TextButton(
                                      onPressed: () => context.push('/my/edit'),
                                      child: const Text('프로필 설정'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GuestAccountPrompt(onLogin: () => context.push('/auth')),
              ),
              if (auth.value?.isAuthenticated == true) const LearningInfoRow(),
            ],
          ),
        ),
        if (!auth.isLoading &&
            !auth.hasError &&
            auth.value?.isAuthenticated == true) ...[
          const SectionHeader('학습'),
          Consumer(
            builder: (context, ref, _) {
              final study = ref.watch(studyControllerProvider);
              return LsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(study.summary),
                    const SizedBox(height: 8),
                    LsListRow(
                      title: '공부 추이 보기',
                      icon: Icons.bar_chart,
                      onTap: () => context.push('/my/trends'),
                    ),
                    const Divider(),
                    LsListRow(
                      title: '공부하러 가기',
                      icon: Icons.timer_outlined,
                      onTap: () {
                        study.selectMock(false);
                        context.go('/study');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SectionHeader('성적'),
          const LsCard(child: MyScoreSummary()),
          const SectionHeader('나의 자료'),
          LsCard(
            child: Column(
              children: [
                LsListRow(
                  title: '저장한 자료',
                  onTap: () => context.push('/my/saved'),
                ),
                const Divider(),
                LsListRow(
                  title: '최근 본 자료',
                  onTap: () => context.push('/my/recent'),
                ),
              ],
            ),
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
        ],
      ],
    );
  }
}
