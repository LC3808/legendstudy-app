import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../school_providers.dart';
import '../domain/school.dart';

class HomeMealCard extends ConsumerStatefulWidget {
  const HomeMealCard({super.key});

  @override
  ConsumerState<HomeMealCard> createState() => _HomeMealCardState();
}

class _HomeMealCardState extends ConsumerState<HomeMealCard>
    with WidgetsBindingObserver {
  Timer? _boundaryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _boundaryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!ref.read(mealBoundaryRefreshEnabledProvider)) return;
      ref.invalidate(koreanMealClockProvider);
      ref.invalidate(koreanTodayProvider);
      ref.invalidate(todayMealsProvider);
      ref.invalidate(tomorrowMealsProvider);
      _scheduleBoundaryRefresh();
    }
  }

  void _scheduleBoundaryRefresh() {
    _boundaryTimer?.cancel();
    final now = DateTime.now();
    final kst = koreanLocalTime(now);
    final nextBoundary = kst.hour < 17
        ? DateTime.utc(kst.year, kst.month, kst.day, 17)
        : DateTime.utc(kst.year, kst.month, kst.day + 1);
    final wait = nextBoundary.difference(kst);
    _boundaryTimer = Timer(
      wait.isNegative || wait == Duration.zero
          ? const Duration(seconds: 1)
          : wait,
      () {
        if (!mounted) return;
        ref.invalidate(koreanMealClockProvider);
        ref.invalidate(koreanTodayProvider);
        ref.invalidate(todayMealsProvider);
        ref.invalidate(tomorrowMealsProvider);
        setState(_scheduleBoundaryRefresh);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(schoolSelectionProvider);
    if (school.value != null &&
        ref.watch(mealBoundaryRefreshEnabledProvider) &&
        _boundaryTimer == null) {
      _scheduleBoundaryRefresh();
    }
    if (school.value == null) {
      _boundaryTimer?.cancel();
      _boundaryTimer = null;
    }
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
      final clock = ref.watch(koreanMealClockProvider);
      final today = ref.watch(todayMealsProvider);
      final tomorrow = ref.watch(tomorrowMealsProvider);
      final loading = today.isLoading;
      final failed =
          today.hasError &&
          (tomorrow.hasError || tomorrow.asData?.value.isEmpty != false);
      body = loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? ErrorState(
              message: '급식 정보를 불러오지 못했어요.',
              onRetry: () {
                ref.invalidate(todayMealsProvider);
                ref.invalidate(tomorrowMealsProvider);
              },
            )
          : MealSummary(
              key: ValueKey('${school.value!.identity}/$clock'),
              meals: today.value ?? const [],
              tomorrowMeals: tomorrow.value ?? const [],
              now: clock,
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
  const MealSummary({
    super.key,
    required this.meals,
    this.tomorrowMeals = const [],
    this.now,
  });

  final List<Meal> meals;
  final List<Meal> tomorrowMeals;

  /// Null preserves the pre-v2 fixture contract for direct widget tests.
  final DateTime? now;

  @override
  State<MealSummary> createState() => _MealSummaryState();
}

class _MealSummaryState extends State<MealSummary> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.now == null
        ? MealDisplayPlan(
            primary: widget.meals,
            secondary: widget.tomorrowMeals,
            primaryIsTomorrow: false,
          )
        : mealDisplayPlan(
            now: widget.now!,
            today: widget.meals,
            tomorrow: widget.tomorrowMeals,
          );
    final primaryLabel = plan.primaryIsTomorrow ? '내일 급식' : '오늘의 급식';
    final canExpand = widget.now == null
        ? widget.meals.isNotEmpty
        : plan.canExpand;
    return Semantics(
      button: true,
      expanded: expanded,
      label: canExpand ? '$primaryLabel, 내일 급식 펼치기' : primaryLabel,
      child: InkWell(
        onTap: plan.isEmpty ? null : () => setState(() => expanded = !expanded),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: plan.isEmpty
              ? const Text('오늘 등록된 급식 정보가 없어요.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              primaryLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (canExpand) ...[
                            Text(expanded ? '접기' : '펼치기'),
                            Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!expanded)
                      Text(
                        plan.primary
                            .map(
                              (meal) =>
                                  '${meal.mealType}: ${meal.menuItems.join(' · ')}',
                            )
                            .join(' / '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      ..._expandedMeals(context, plan),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _expandedMeals(BuildContext context, MealDisplayPlan plan) {
    final widgets = <Widget>[];
    for (final meal in plan.primary) {
      widgets.addAll(_mealWidgets(meal));
    }
    if (plan.secondary.isNotEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 4),
          child: Text('내일 급식', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
      for (final meal in plan.secondary) {
        widgets.addAll(_mealWidgets(meal));
      }
    }
    return widgets;
  }

  List<Widget> _mealWidgets(Meal meal) => [
    const SizedBox(height: 12),
    Text(meal.mealType, style: const TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    Text(meal.menuItems.join('\n')),
  ];
}
