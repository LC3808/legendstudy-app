import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/content_providers.dart';
import 'day_target_card.dart';
import '../../school/presentation/home_meal_card.dart';
import '../../content/domain/content_types.dart';
import '../../content/presentation/content_results.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShellPage(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    children: [
      const AppHeader(title: '레전드스터디', branded: true),
      const DayTargetCard(),
      const SizedBox(height: 8),
      const HomeMealCard(),
      const SizedBox(height: 8),
      SearchEntry(onTap: () => context.go('/materials')),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Semantics(
          header: true,
          child: const Text('빠르게 찾기', style: AppTokens.sectionTitle),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final type in [
            'exam',
            'study_material',
            'university_essay',
            'admissions_info',
          ])
            QuickFilterChip(
              contentTypeLabels[type]!,
              onTap: () => context.go(
                Uri(
                  path: '/materials',
                  queryParameters: {'type': type},
                ).toString(),
              ),
            ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Semantics(
          header: true,
          child: const Text('오늘의 공부', style: AppTokens.sectionTitle),
        ),
      ),
      DailyUtilityCard(
        title: '나의 공부 시간',
        body: const Text('오늘 공부 기록이 아직 없어요.'),
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
