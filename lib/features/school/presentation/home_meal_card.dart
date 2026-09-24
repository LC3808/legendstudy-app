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
  bool _wasActive = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(mealBoundaryRefreshEnabledProvider)) {
          didChangeAppLifecycleState(AppLifecycleState.resumed);
        }
      });
    }
    _wasActive = active;
  }

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
      ref.invalidate(nextHomeMealsProvider);
      _scheduleBoundaryRefresh();
    }
  }

  void _scheduleBoundaryRefresh() {
    _boundaryTimer?.cancel();
    final now = ref.read(mealNowProvider)();
    final wait = nextMealBoundary(now).difference(now);
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
        ref.invalidate(nextHomeMealsProvider);
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
      final tomorrow = ref.watch(nextHomeMealsProvider);
      final loading = today.isLoading || tomorrow.isLoading;
      final failed = today.hasError || tomorrow.hasError;
      body = loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? ErrorState(
              message: '급식 정보를 불러오지 못했어요.',
              onRetry: () {
                ref.invalidate(todayMealsProvider);
                ref.invalidate(tomorrowMealsProvider);
                ref.invalidate(nextHomeMealsProvider);
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
      action: !school.isLoading && !school.hasError && school.value == null
          ? TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => context.push('/my/school'),
              child: const Text('학교 설정'),
            )
          : null,
      body: body,
    );
  }
}

/// Time-selected preview and full dated menus stay inside the Home scroll.
class MealSummary extends StatefulWidget {
  const MealSummary({
    super.key,
    required this.meals,
    this.tomorrowMeals = const [],
    required this.now,
  });
  final List<Meal> meals, tomorrowMeals;
  final DateTime now;
  @override
  State<MealSummary> createState() => _MealSummaryState();
}

class _MealSummaryState extends State<MealSummary> {
  bool expanded = false;
  bool? selectedTomorrow;
  @override
  Widget build(BuildContext context) {
    final plan = mealDisplayPlan(
      now: widget.now,
      today: widget.meals,
      tomorrow: widget.tomorrowMeals,
    );
    final tomorrow = expanded
        ? selectedTomorrow ?? plan.primaryIsTomorrow
        : plan.primaryIsTomorrow;
    final nextDate =
        widget.tomorrowMeals.firstOrNull?.date ??
        koreanDateOffset(widget.now, 1);
    final date = tomorrow ? nextDate : koreanDateOffset(widget.now, 0);
    final dayLabel = !tomorrow
        ? '오늘'
        : nextDate == koreanDateOffset(widget.now, 1)
        ? '내일'
        : '다음';
    final label = expanded
        ? '$dayLabel 급식'
        : '$dayLabel ${plan.isEmpty ? '급식' : plan.primary.first.mealType}';
    final meals = tomorrow ? widget.tomorrowMeals : widget.meals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          label: expanded ? '급식 상세 접기' : '급식 상세 펼치기',
          child: InkWell(
            onTap: () => setState(() {
              expanded = !expanded;
              if (expanded) selectedTomorrow = plan.primaryIsTomorrow;
            }),
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Icon(expanded ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                    Text(mealDateLabel(date)),
                    if (!expanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.isEmpty
                            ? '예정된 급식이 없어요.'
                            : plan.primary.first.menuItems.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => selectedTomorrow = !tomorrow),
              child: Text(
                '${mealDateLabel(tomorrow ? koreanDateOffset(widget.now, 0) : nextDate)} 급식 보기',
              ),
            ),
          ),
          if (meals.isEmpty) const Text('등록된 급식 정보가 없어요.'),
          for (final type in ['조식', '중식', '석식'])
            for (final meal in meals.where((m) => m.mealType == type)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  type,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(meal.menuItems.join('\n')),
            ],
        ],
      ],
    );
  }
}

String mealDateLabel(String date) =>
    '${int.parse(date.substring(4, 6))}월 ${int.parse(date.substring(6, 8))}일';
