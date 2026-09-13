import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../school_providers.dart';

class HomeMealCard extends ConsumerWidget {
  const HomeMealCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(schoolSelectionProvider);
    Widget body;
    String title = '우리 학교 · 오늘 급식';
    if (school.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (school.hasError) {
      body = ErrorState(
        message: '학교 설정을 불러오지 못했어요.',
        onRetry: () => ref.invalidate(schoolSelectionProvider),
      );
    } else if (school.value == null) {
      body = const Text('학교를 설정하면 오늘 급식을 볼 수 있어요.');
    } else {
      title = school.value!.name;
      body = ref
          .watch(todayMealsProvider)
          .when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => ErrorState(
              message: '급식 정보를 불러오지 못했어요.',
              onRetry: () => ref.invalidate(todayMealsProvider),
            ),
            data: (meals) => meals.isEmpty
                ? const Text('오늘 등록된 급식 정보가 없어요.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오늘의 급식'),
                      Text(
                        meals
                            .map(
                              (meal) =>
                                  '${meal.mealType}: ${meal.menuItems.join(' · ')}',
                            )
                            .join(' / '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surfaceWarm,
        border: Border.all(color: AppTokens.cardBorder),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          body,
          TextButton(
            onPressed: () => context.push('/my/school'),
            child: const Text('학교 설정'),
          ),
          if (!school.isLoading && school.value != null)
            const Text('출처: 교육부·시도교육청 / NEIS', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
