import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../school_providers.dart';
import '../domain/school.dart';

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
                : MealSummary(
                    key: ValueKey(
                      '${school.value!.identity}/${meals.first.date}',
                    ),
                    meals: meals,
                  ),
          );
    }
    return DailyUtilityCard(
      wrapHeader: true,
      title: title,
      action: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: () => context.push('/my/school'),
        child: const Text('학교 설정'),
      ),
      body: body,
    );
  }
}

/// Compact by default; expanded menus participate in the Home scroll view.
class MealSummary extends StatefulWidget {
  const MealSummary({super.key, required this.meals});
  final List<Meal> meals;
  @override
  State<MealSummary> createState() => _MealSummaryState();
}

class _MealSummaryState extends State<MealSummary> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: expanded,
    child: InkWell(
      onTap: () => setState(() => expanded = !expanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '오늘의 급식',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(expanded ? '접기' : '펼치기'),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (!expanded)
              Text(
                widget.meals
                    .map((m) => '${m.mealType}: ${m.menuItems.join(' · ')}')
                    .join(' / '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              for (final meal in widget.meals) ...[
                const SizedBox(height: 12),
                Text(
                  meal.mealType,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(meal.menuItems.join('\n')),
              ],
          ],
        ),
      ),
    ),
  );
}
