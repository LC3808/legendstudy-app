import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

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
      accentColor: AppTokens.homeMealAccent,
      body: body,
    );
  }
}

/// One time-selected Home meal; full menus live on a date-specific detail page.
class MealSummary extends StatelessWidget {
  const MealSummary({
    super.key,
    required this.meals,
    this.tomorrowMeals = const [],
    required this.now,
  });
  final List<Meal> meals, tomorrowMeals;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final plan = mealDisplayPlan(
      now: now,
      today: meals,
      tomorrow: tomorrowMeals,
    );
    final date = koreanDateOffset(now, plan.primaryIsTomorrow ? 1 : 0);
    final label =
        '${plan.primaryIsTomorrow ? '내일' : '오늘'} ${plan.isEmpty ? '급식' : plan.primary.first.mealType}';
    return Semantics(
      button: true,
      label: '$label 전체 급식 보기',
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MealDetailsPage(
              today: meals,
              tomorrow: tomorrowMeals,
              todayDate: koreanDate(now),
              tomorrowDate: koreanDateOffset(now, 1),
              initiallyTomorrow: plan.primaryIsTomorrow,
            ),
          ),
        ),
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
                        label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              Text(mealDateLabel(date)),
              const SizedBox(height: 8),
              Text(
                plan.isEmpty
                    ? '등록된 중식·석식 정보가 없어요.'
                    : plan.primary.first.menuItems.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String mealDateLabel(String date) =>
    '${int.parse(date.substring(4, 6))}월 ${int.parse(date.substring(6, 8))}일';

class MealDetailsPage extends StatefulWidget {
  const MealDetailsPage({
    super.key,
    required this.today,
    required this.tomorrow,
    required this.todayDate,
    required this.tomorrowDate,
    required this.initiallyTomorrow,
  });
  final List<Meal> today, tomorrow;
  final String todayDate, tomorrowDate;
  final bool initiallyTomorrow;
  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  late bool tomorrow = widget.initiallyTomorrow;
  @override
  Widget build(BuildContext context) {
    final meals = tomorrow ? widget.tomorrow : widget.today;
    return Scaffold(
      appBar: AppBar(title: const Text('급식 상세')),
      body: SafeArea(
        child: ShellPage(
          children: [
            Text(
              mealDateLabel(tomorrow ? widget.tomorrowDate : widget.todayDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => setState(() => tomorrow = !tomorrow),
              child: Text(
                '${mealDateLabel(tomorrow ? widget.todayDate : widget.tomorrowDate)} 급식 보기',
              ),
            ),
            if (meals.isEmpty) const Text('등록된 급식 정보가 없어요.'),
            for (final type in ['조식', '중식', '석식'])
              for (final meal in meals.where((m) => m.mealType == type)) ...[
                SectionHeader(type),
                Text(meal.menuItems.join('\n')),
              ],
          ],
        ),
      ),
    );
  }
}
