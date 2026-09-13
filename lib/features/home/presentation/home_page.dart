import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/content_providers.dart';
import '../../content/presentation/content_results.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShellPage(
    children: [
      const AppHeader(title: '레전드스터디', branded: true),
      const CompactUtilityCard(title: 'D-DAY', body: '목표 일정과 함께 하루를 준비해요.'),
      const SizedBox(height: 12),
      CompactUtilityCard(
        title: '우리 학교 · 오늘 급식',
        body: '학교를 설정하면 오늘 급식을 볼 수 있어요.',
        action: TextButton(
          onPressed: () => context.push('/my/school'),
          child: const Text('학교 설정'),
        ),
      ),
      const SizedBox(height: AppTokens.sectionGap),
      SearchEntry(onTap: () => context.go('/materials')),
      const SectionHeader('빠르게 찾기'),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final label in ['기출문제', '영어', '논술', '학습 자료'])
            QuickFilterChip(
              label,
              onTap: () => context.go(
                Uri(
                  path: '/materials',
                  queryParameters: {'q': label},
                ).toString(),
              ),
            ),
        ],
      ),
      const SectionHeader('오늘의 공부'),
      CompactUtilityCard(
        title: '나의 공부 시간',
        body: '오늘 공부 기록이 아직 없어요.',
        action: TextButton(
          onPressed: () => context.go('/study'),
          child: const Text('학습으로 이동'),
        ),
      ),
      const SectionHeader('최근 업데이트'),
      ContentResults(
        state: ref.watch(recentContentProvider),
        onRetry: () => ref.invalidate(recentContentProvider),
      ),
      const SectionHeader('최근 본 자료'),
      const EmptyState('최근 본 자료를 로그인 후 모아 볼 수 있어요.'),
    ],
  );
}
