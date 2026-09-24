import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../../../core/theme/app_theme.dart';
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
      ref.invalidate(mealContextProvider);
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
        ref.invalidate(mealContextProvider);
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
                ref.invalidate(datedMealsProvider);
                ref.invalidate(todayMealsProvider);
                ref.invalidate(tomorrowMealsProvider);
                ref.invalidate(nextHomeMealsProvider);
                ref.invalidate(mealContextProvider);
              },
            )
          : MealSummary(
              key: ValueKey('${school.value!.identity}/$clock'),
              schoolName: school.value!.name,
              loadDates: () {
                if (ref.read(mealContextProvider).hasError) {
                  ref.invalidate(datedMealsProvider);
                  ref.invalidate(mealContextProvider);
                }
                return ref.read(mealContextProvider.future);
              },
              meals: today.value ?? const [],
              tomorrowMeals: tomorrow.value ?? const [],
              now: clock,
            );
    }
    if (school.value != null && !school.isLoading && !school.hasError) {
      return LsCard(dailySurface: true, child: body);
    }
    return DailyUtilityCard(
      icon: Icons.restaurant_outlined,
      accentColor: AppTokens.success,
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
    this.schoolName,
    this.loadDates,
    this.tomorrowMeals = const [],
    required this.now,
  });
  final List<Meal> meals, tomorrowMeals;
  final String? schoolName;
  final Future<List<Meal>> Function()? loadDates;
  final DateTime now;
  @override
  State<MealSummary> createState() => _MealSummaryState();
}

class _MealSummaryState extends State<MealSummary> {
  bool expanded = false;
  String? selectedDate;
  List<Meal>? contextMeals;
  bool datesLoading = false, datesFailed = false;
  Future<void> loadDates() async {
    if (widget.loadDates == null || datesLoading) return;
    setState(() {
      datesLoading = true;
      datesFailed = false;
    });
    try {
      final result = await widget.loadDates!();
      if (mounted) {
        setState(() {
          contextMeals = result;
          if (!result.any((m) => m.date == selectedDate)) {
            final today = koreanDateOffset(widget.now, 0);
            selectedDate =
                result
                    .where((m) => m.date.compareTo(today) >= 0)
                    .firstOrNull
                    ?.date ??
                result.lastOrNull?.date;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => datesFailed = true);
    } finally {
      if (mounted) setState(() => datesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = mealDisplayPlan(
      now: widget.now,
      today: widget.meals,
      tomorrow: widget.tomorrowMeals,
    );
    final today = koreanDateOffset(widget.now, 0);
    final defaultDate =
        plan.primary.firstOrNull?.date ??
        widget.tomorrowMeals.firstOrNull?.date ??
        (plan.primaryIsTomorrow ? koreanDateOffset(widget.now, 1) : today);
    final date = expanded ? selectedDate ?? defaultDate : defaultDate;
    final all = contextMeals ?? [...widget.meals, ...widget.tomorrowMeals];
    final dates = all.map((m) => m.date).toSet().toList()..sort();
    final label = date == today
        ? '오늘 급식'
        : date.compareTo(today) < 0
        ? '지난 급식'
        : '다음 급식';
    final meals = all.where((m) => m.date == date).toList();
    void toggle() {
      setState(() {
        expanded = !expanded;
        if (expanded) {
          selectedDate = dates.contains(defaultDate)
              ? defaultDate
              : dates.where((d) => d.compareTo(today) >= 0).firstOrNull ??
                    dates.lastOrNull;
        }
      });
      if (expanded && contextMeals == null) loadDates();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.restaurant_outlined,
              size: 20,
              color: AppTokens.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (widget.schoolName != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.schoolName!,
                    textAlign: TextAlign.right,
                    style: AppTokens.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(mealDateLabel(date))),
            Semantics(
              label: expanded ? '급식 상세 접기' : '급식 상세 펼치기',
              expanded: expanded,
              child: IconButton(
                key: const Key('meal-expand'),
                tooltip: expanded ? '급식 상세 접기' : '급식 상세 펼치기',
                onPressed: toggle,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ),
          ],
        ),
        if (!expanded)
          Text(
            plan.isEmpty
                ? '예정된 급식이 없어요.'
                : '${plan.primary.first.mealType} · ${plan.primary.first.menuItems.join(' · ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (expanded) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in dates.take(3))
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(mealChipLabel(option)),
                  selected: date == option,
                  onSelected: (_) => setState(() => selectedDate = option),
                ),
            ],
          ),
          if (datesLoading)
            const LinearProgressIndicator(semanticsLabel: '급식 제공일 불러오는 중'),
          if (datesFailed)
            TextButton(onPressed: loadDates, child: const Text('제공일 다시 불러오기')),
          if (meals.isEmpty) const Text('예정된 급식이 없어요.'),
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

String mealChipLabel(String date) {
  final day = DateTime.parse(date);
  return '${mealDateLabel(date)}(${const ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1]})';
}
